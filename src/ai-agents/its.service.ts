import { Injectable, Logger } from '@nestjs/common';
import { UserBehaviorService } from './user-behavior.service';
import { AiService } from '../ai/ai.service';

/**
 * Intelligent Tutoring System (ITS)
 * Adjusts difficulty, provides hints, skips mastered topics
 * Analyzes real-time data (pace, strengths/weaknesses) to personalize learning
 */
@Injectable()
export class ItsService {
  private readonly logger = new Logger(ItsService.name);

  constructor(
    private behaviorService: UserBehaviorService,
    private aiService: AiService,
  ) {}

  /**
   * Analyze user's current state and adjust difficulty
   */
  async adjustDifficulty(
    userId: string,
    nodeId: string,
    currentDifficulty: 'easy' | 'medium' | 'hard' | 'expert',
  ): Promise<{
    suggestedDifficulty: 'easy' | 'medium' | 'hard' | 'expert';
    reason: string;
    shouldSkip: boolean;
  }> {
    try {
      const mastery = await this.behaviorService.calculateMastery(
        userId,
        nodeId,
      );
      const errorPatterns = await this.behaviorService.getErrorPatterns(
        userId,
        nodeId,
      );
      const pace = await this.behaviorService.getLearningPace(userId, 7);

      // Decision logic
      let suggestedDifficulty = currentDifficulty;
      let shouldSkip = false;
      let reason = '';

      // Skip if mastered
      if (mastery >= 0.9) {
        shouldSkip = true;
        reason = 'You have mastered this topic';
        return { suggestedDifficulty, reason, shouldSkip };
      }

      // Adjust difficulty based on performance
      if (errorPatterns.errorRate > 0.6 && errorPatterns.consecutiveErrors > 3) {
        // Too many errors - reduce difficulty
        if (currentDifficulty === 'hard') {
          suggestedDifficulty = 'medium';
        } else if (currentDifficulty === 'expert') {
          suggestedDifficulty = 'hard';
        } else if (currentDifficulty === 'medium') {
          suggestedDifficulty = 'easy';
        }
        reason = 'Reducing difficulty due to high error rate';
      } else if (
        mastery > 0.7 &&
        errorPatterns.errorRate < 0.2 &&
        pace < 300
      ) {
        // High mastery, low errors, fast pace - increase difficulty
        if (currentDifficulty === 'easy') {
          suggestedDifficulty = 'medium';
        } else if (currentDifficulty === 'medium') {
          suggestedDifficulty = 'hard';
        } else if (currentDifficulty === 'hard') {
          suggestedDifficulty = 'expert';
        }
        reason = 'Increasing difficulty based on strong performance';
      } else {
        reason = 'Difficulty appropriate for current level';
      }

      this.logger.log(
        `ITS adjusted difficulty for node ${nodeId}: ${currentDifficulty} -> ${suggestedDifficulty}`,
      );

      return { suggestedDifficulty, reason, shouldSkip };
    } catch (error) {
      this.logger.error(`ITS error: ${error.message}`, error.stack);
      return {
        suggestedDifficulty: currentDifficulty,
        reason: 'Unable to analyze, keeping current difficulty',
        shouldSkip: false,
      };
    }
  }

  /**
   * Generate adaptive hint based on user's errors and context
   */
  async generateHint(
    userId: string,
    nodeId: string,
    contentItemId: string,
    question?: string,
    userAnswer?: string,
  ): Promise<{
    hint: string;
    level: 'subtle' | 'moderate' | 'explicit';
    nextStep?: string;
  }> {
    try {
      const behaviors = await this.behaviorService.getNodeBehavior(
        userId,
        nodeId,
        10,
      );
      const errorPatterns = await this.behaviorService.getErrorPatterns(
        userId,
        nodeId,
      );
      const mastery = await this.behaviorService.calculateMastery(
        userId,
        nodeId,
      );

      // Determine hint level based on attempts and errors
      let hintLevel: 'subtle' | 'moderate' | 'explicit' = 'subtle';

      if (errorPatterns.consecutiveErrors >= 3) {
        hintLevel = 'explicit';
      } else if (errorPatterns.consecutiveErrors >= 2) {
        hintLevel = 'moderate';
      }

      // Generate hint using AI
      const context = `
User is learning: ${nodeId}
Mastery level: ${(mastery * 100).toFixed(0)}%
Errors in this session: ${errorPatterns.consecutiveErrors}
${question ? `Question: ${question}` : ''}
${userAnswer ? `User's answer: ${userAnswer}` : ''}
Previous attempts: ${behaviors.filter((b) => b.action === 'attempt_quiz').length}
      `.trim();

      const hintPrompt = `You are an intelligent tutoring system. Generate a ${hintLevel} hint to help the user understand the concept without giving away the answer directly.

Context:
${context}

Generate a helpful hint that:
1. Guides the user toward the correct understanding
2. Is appropriate for their current mastery level
3. Doesn't reveal the answer directly
4. Encourages critical thinking

Hint:`;

      const hint = await this.aiService.chat([
        { role: 'user', content: hintPrompt },
      ]);

      // Determine next step
      let nextStep: string | undefined;
      if (errorPatterns.consecutiveErrors >= 3) {
        nextStep = 'Consider reviewing prerequisite concepts';
      } else if (mastery < 0.3) {
        nextStep = 'Try breaking down the problem into smaller steps';
      }

      this.logger.log(`ITS generated ${hintLevel} hint for node ${nodeId}`);

      return { hint, level: hintLevel, nextStep };
    } catch (error) {
      this.logger.error(`ITS hint generation error: ${error.message}`, error.stack);
      return {
        hint: 'Think about the key concepts you\'ve learned so far.',
        level: 'subtle',
      };
    }
  }

  /**
   * Check if topic should be skipped (mastered)
   */
  async shouldSkipTopic(
    userId: string,
    nodeId: string,
  ): Promise<{ shouldSkip: boolean; reason: string }> {
    const mastery = await this.behaviorService.calculateMastery(userId, nodeId);
    const behaviors = await this.behaviorService.getNodeBehavior(userId, nodeId, 5);

    // Skip if:
    // 1. Mastery >= 90%
    // 2. Completed recently with high accuracy
    const recentCompletions = behaviors.filter(
      (b) => b.action === 'complete' && b.metrics.accuracy && b.metrics.accuracy > 0.9,
    );

    if (mastery >= 0.9 || recentCompletions.length >= 2) {
      return {
        shouldSkip: true,
        reason: mastery >= 0.9
          ? 'Topic already mastered'
          : 'Recently completed with high accuracy',
      };
    }

    return { shouldSkip: false, reason: 'Topic needs more practice' };
  }

  /**
   * Get personalized learning recommendations
   */
  async getPersonalizedRecommendations(
    userId: string,
  ): Promise<{
    strengths: Array<{ nodeId: string; mastery: number }>;
    weaknesses: Array<{ nodeId: string; mastery: number }>;
    recommendedFocus: string[];
    learningPace: number;
    suggestions: string[];
  }> {
    const { strengths, weaknesses } =
      await this.behaviorService.getStrengthsAndWeaknesses(userId);
    const pace = await this.behaviorService.getLearningPace(userId, 7);
    const errorPatterns = await this.behaviorService.getErrorPatterns(userId);

    // Generate AI-powered suggestions
    const suggestions: string[] = [];

    if (errorPatterns.consecutiveErrors > 3) {
      suggestions.push(
        'You\'re encountering multiple errors. Consider reviewing foundational concepts.',
      );
    }

    if (pace > 600) {
      suggestions.push(
        'You\'re taking longer than average. Try breaking content into smaller chunks.',
      );
    }

    if (strengths.length > weaknesses.length) {
      suggestions.push(
        'Great progress! Consider tackling more challenging topics.',
      );
    } else {
      suggestions.push(
        'Focus on strengthening your weak areas before moving forward.',
      );
    }

    // Recommend focus areas (top 3 weaknesses)
    const recommendedFocus = weaknesses
      .slice(0, 3)
      .map((w) => w.nodeId);

    return {
      strengths,
      weaknesses,
      recommendedFocus,
      learningPace: pace,
      suggestions,
    };
  }
}

