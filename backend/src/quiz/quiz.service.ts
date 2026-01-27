import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AiService } from '../ai/ai.service';
import { Quiz, QuizQuestion } from './entities/quiz.entity';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { UserProgress } from '../user-progress/entities/user-progress.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';

export interface QuizResult {
  passed: boolean;
  score: number;
  totalQuestions: number;
  correctAnswers: number;
  passingScore: number;
  details: Array<{
    questionId: string;
    userAnswer: string;
    correctAnswer: string;
    isCorrect: boolean;
    explanation: string;
  }>;
}

@Injectable()
export class QuizService {
  // Cache for active quiz sessions (maps sessionId -> quiz data)
  private quizSessions: Map<string, { quiz: Quiz; expiresAt: number }> = new Map();

  constructor(
    @InjectRepository(Quiz)
    private quizRepository: Repository<Quiz>,
    @InjectRepository(ContentItem)
    private contentItemRepository: Repository<ContentItem>,
    @InjectRepository(UserProgress)
    private progressRepository: Repository<UserProgress>,
    @InjectRepository(LearningNode)
    private nodeRepository: Repository<LearningNode>,
    private aiService: AiService,
  ) {}

  /**
   * Get quiz for a content item - returns from DB if exists
   */
  async getQuizForContent(
    contentItemId: string,
    userId: string,
  ): Promise<{
    quizId: string;
    sessionId: string;
    questions: Array<Omit<QuizQuestion, 'correctAnswer' | 'explanation'>>;
    passingScore: number;
    totalQuestions: number;
    contentType: string;
    title: string;
  }> {
    // Check if quiz exists in DB
    let quiz = await this.quizRepository.findOne({
      where: { contentItemId },
    });

    if (!quiz) {
      // No pre-generated quiz found, generate one now and save it
      console.log(`📝 No quiz found for content ${contentItemId}, generating...`);
      quiz = await this.generateAndSaveQuizForContent(contentItemId);
    }

    // Create session for this quiz attempt
    const sessionId = `session_${contentItemId}_${userId}_${Date.now()}`;
    this.quizSessions.set(sessionId, {
      quiz,
      expiresAt: Date.now() + 30 * 60 * 1000, // 30 minutes
    });

    // Return questions without answers
    return {
      quizId: quiz.id,
      sessionId,
      questions: quiz.questions.map((q) => ({
        id: q.id,
        question: q.question,
        options: q.options,
        category: q.category,
      })),
      passingScore: quiz.passingScore,
      totalQuestions: quiz.totalQuestions,
      contentType: quiz.contentType || 'concept',
      title: quiz.title || '',
    };
  }

  /**
   * Get boss quiz for a learning node - returns from DB if exists
   */
  async getBossQuiz(
    nodeId: string,
    userId: string,
  ): Promise<{
    quizId: string;
    sessionId: string;
    questions: Array<Omit<QuizQuestion, 'correctAnswer' | 'explanation'>>;
    passingScore: number;
    totalQuestions: number;
    title: string;
  }> {
    // Check if boss quiz exists in DB
    let quiz = await this.quizRepository.findOne({
      where: { learningNodeId: nodeId, type: 'boss' },
    });

    if (!quiz) {
      // No pre-generated quiz found, generate one now and save it
      console.log(`📝 No boss quiz found for node ${nodeId}, generating...`);
      quiz = await this.generateAndSaveBossQuiz(nodeId);
    }

    // Create session
    const sessionId = `boss_session_${nodeId}_${userId}_${Date.now()}`;
    this.quizSessions.set(sessionId, {
      quiz,
      expiresAt: Date.now() + 60 * 60 * 1000, // 1 hour for boss
    });

    return {
      quizId: quiz.id,
      sessionId,
      questions: quiz.questions.map((q) => ({
        id: q.id,
        question: q.question,
        options: q.options,
        category: q.category,
      })),
      passingScore: quiz.passingScore,
      totalQuestions: quiz.totalQuestions,
      title: quiz.title || '',
    };
  }

  /**
   * Submit quiz answers and get result
   */
  async submitQuiz(
    sessionId: string,
    answers: Record<string, 'A' | 'B' | 'C' | 'D'>,
    userId: string,
  ): Promise<QuizResult> {
    const session = this.quizSessions.get(sessionId);

    if (!session) {
      throw new NotFoundException('Quiz session not found or expired. Please start a new quiz.');
    }

    if (session.expiresAt < Date.now()) {
      this.quizSessions.delete(sessionId);
      throw new BadRequestException('Quiz session has expired. Please start a new quiz.');
    }

    const { quiz } = session;
    const { questions, passingScore } = quiz;

    // Calculate results
    const details = questions.map((q) => {
      const userAnswer = answers[q.id] || '';
      const isCorrect = userAnswer === q.correctAnswer;
      return {
        questionId: q.id,
        userAnswer,
        correctAnswer: q.correctAnswer,
        isCorrect,
        explanation: q.explanation,
      };
    });

    const correctAnswers = details.filter((d) => d.isCorrect).length;
    const score = Math.round((correctAnswers / questions.length) * 100);
    const passed = score >= passingScore;

    // Clean up session after submission
    this.quizSessions.delete(sessionId);

    return {
      passed,
      score,
      totalQuestions: questions.length,
      correctAnswers,
      passingScore,
      details,
    };
  }

  /**
   * Generate and save quiz for a content item
   */
  async generateAndSaveQuizForContent(contentItemId: string): Promise<Quiz> {
    const contentItem = await this.contentItemRepository.findOne({
      where: { id: contentItemId },
    });

    if (!contentItem) {
      throw new NotFoundException(`Content item not found: ${contentItemId}`);
    }

    if (!['concept', 'example'].includes(contentItem.type)) {
      throw new BadRequestException(`Quiz not available for content type: ${contentItem.type}`);
    }

    // Generate quiz using AI
    const contentText = this.extractContentText(contentItem);
    const quizData = await this.aiService.generateQuiz(
      contentItem.title,
      contentText,
      contentItem.type as 'concept' | 'example',
      'lesson',
    );

    // Save to database
    const quiz = this.quizRepository.create({
      contentItemId,
      type: 'lesson',
      contentType: contentItem.type as 'concept' | 'example',
      questions: quizData.questions,
      totalQuestions: quizData.questions.length,
      passingScore: quizData.passingScore,
      title: contentItem.title,
      generatedAt: new Date(),
      generationModel: 'gpt-4o-mini',
    });

    return this.quizRepository.save(quiz);
  }

  /**
   * Generate and save boss quiz for a learning node
   */
  async generateAndSaveBossQuiz(nodeId: string): Promise<Quiz> {
    const node = await this.nodeRepository.findOne({
      where: { id: nodeId },
    });

    if (!node) {
      throw new NotFoundException(`Learning node not found: ${nodeId}`);
    }

    // Get all content items for this node
    const contentItems = await this.contentItemRepository.find({
      where: { nodeId },
    });

    const combinedContent = contentItems
      .map((item) => `## ${item.title}\n${this.extractContentText(item)}`)
      .join('\n\n');

    // Generate boss quiz
    const quizData = await this.aiService.generateQuiz(
      node.title,
      combinedContent,
      'concept',
      'boss',
    );

    // Save to database
    const quiz = this.quizRepository.create({
      learningNodeId: nodeId,
      type: 'boss',
      questions: quizData.questions,
      totalQuestions: quizData.questions.length,
      passingScore: quizData.passingScore,
      title: `Boss Quiz: ${node.title}`,
      generatedAt: new Date(),
      generationModel: 'gpt-4o-mini',
    });

    return this.quizRepository.save(quiz);
  }

  /**
   * Batch generate quizzes for all content items without quizzes
   */
  async generateAllMissingQuizzes(options?: {
    limit?: number;
    onProgress?: (current: number, total: number, title: string) => void;
  }): Promise<{ generated: number; failed: number; skipped: number }> {
    const limit = options?.limit || 100;
    
    // Find all concept/example content items without quizzes
    const contentItems = await this.contentItemRepository
      .createQueryBuilder('content')
      .leftJoin('quizzes', 'quiz', 'quiz.contentItemId = content.id')
      .where('content.type IN (:...types)', { types: ['concept', 'example'] })
      .andWhere('quiz.id IS NULL')
      .take(limit)
      .getMany();

    console.log(`📝 Found ${contentItems.length} content items without quizzes`);

    let generated = 0;
    let failed = 0;
    let skipped = 0;

    for (let i = 0; i < contentItems.length; i++) {
      const item = contentItems[i];
      
      try {
        // Check if content has enough text
        const contentText = this.extractContentText(item);
        if (contentText.length < 50) {
          console.log(`⏭️  Skipping ${item.title} - not enough content`);
          skipped++;
          continue;
        }

        options?.onProgress?.(i + 1, contentItems.length, item.title);
        console.log(`📝 [${i + 1}/${contentItems.length}] Generating quiz for: ${item.title}`);
        
        await this.generateAndSaveQuizForContent(item.id);
        generated++;
        
        // Rate limiting - wait 1 second between API calls
        await new Promise(resolve => setTimeout(resolve, 1000));
      } catch (error: any) {
        console.error(`❌ Failed to generate quiz for ${item.title}: ${error.message}`);
        failed++;
      }
    }

    return { generated, failed, skipped };
  }

  /**
   * Check if quiz exists for a content item
   */
  async hasQuiz(contentItemId: string): Promise<boolean> {
    const count = await this.quizRepository.count({
      where: { contentItemId },
    });
    return count > 0;
  }

  /**
   * Get quiz statistics
   */
  async getQuizStats(): Promise<{
    totalQuizzes: number;
    lessonQuizzes: number;
    bossQuizzes: number;
    conceptQuizzes: number;
    exampleQuizzes: number;
  }> {
    const [total, lesson, boss] = await Promise.all([
      this.quizRepository.count(),
      this.quizRepository.count({ where: { type: 'lesson' } }),
      this.quizRepository.count({ where: { type: 'boss' } }),
    ]);

    const [concept, example] = await Promise.all([
      this.quizRepository.count({ where: { contentType: 'concept' } }),
      this.quizRepository.count({ where: { contentType: 'example' } }),
    ]);

    return {
      totalQuizzes: total,
      lessonQuizzes: lesson,
      bossQuizzes: boss,
      conceptQuizzes: concept,
      exampleQuizzes: example,
    };
  }

  /**
   * Extract text content from content item
   */
  private extractContentText(contentItem: ContentItem): string {
    const parts: string[] = [];

    // Add main content
    if (contentItem.content) {
      parts.push(contentItem.content);
    }

    // Add rich content if available (convert to plain text)
    if (contentItem.richContent) {
      try {
        if (Array.isArray(contentItem.richContent)) {
          const text = contentItem.richContent
            .map((block: any) => block.insert || '')
            .join('');
          if (text.trim()) parts.push(text);
        }
      } catch (e) {
        // Ignore rich content parsing errors
      }
    }

    // Add media descriptions if available
    if (contentItem.media) {
      if (contentItem.media.imageDescription) {
        parts.push(contentItem.media.imageDescription);
      }
      if (contentItem.media.videoDescription) {
        parts.push(contentItem.media.videoDescription);
      }
    }

    return parts.join('\n\n');
  }

  /**
   * Clean up expired sessions (call periodically)
   */
  cleanupExpiredSessions(): void {
    const now = Date.now();
    for (const [sessionId, session] of this.quizSessions.entries()) {
      if (session.expiresAt < now) {
        this.quizSessions.delete(sessionId);
      }
    }
  }
}
