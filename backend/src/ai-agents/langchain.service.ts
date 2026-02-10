import { Injectable, Logger } from '@nestjs/common';
import { AiService } from '../ai/ai.service';
import { DrlService } from './drl.service';
import { ItsService } from './its.service';
import { LearningNodesService } from '../learning-nodes/learning-nodes.service';

/**

* Dịch vụ LangChain

* Kết nối các lệnh gọi AI để tạo ra lộ trình cá nhân hóa

* Luồng ví dụ: Truy xuất từ ​​đồ thị → Tạo bài kiểm tra → Điều chỉnh lộ trình → Tạo lộ trình

*/
@Injectable()
export class LangChainService {
  private readonly logger = new Logger(LangChainService.name);

  constructor(
    private aiService: AiService,
    private drlService: DrlService,
    private itsService: ItsService,
    private learningNodesService: LearningNodesService,
  ) {}

  /**
   * Generate personalized learning roadmap
   * Chain: Query understanding → RAG retrieval → DRL optimization → ITS adjustment → Roadmap generation
   */
  async generatePersonalizedRoadmap(
    userId: string,
    userQuery: string,
    subjectId: string,
    days: number = 30,
  ): Promise<{
    roadmap: Array<{
      day: number;
      nodeId: string;
      nodeName: string;
      difficulty: string;
      estimatedTime: number;
      reason: string;
    }>;
    summary: string;
    confidence: number;
  }> {
    try {
      this.logger.log(`Generating personalized roadmap for user ${userId}`);

      // Step 1: Understand user query and extract learning goals
      const goals = await this.extractLearningGoals(userQuery);

      // Step 2: Retrieve relevant learning nodes for this subject
      const subjectLearningNodes = await this.learningNodesService.findBySubject(
        subjectId,
      );

      // Step 3: Get user's current state
      const recommendations = await this.itsService.getPersonalizedRecommendations(
        userId,
      );

      // Step 4: Build learning path using DRL
      const roadmap: Array<{
        day: number;
        nodeId: string;
        nodeName: string;
        difficulty: string;
        estimatedTime: number;
        reason: string;
      }> = [];

      let currentNodeId: string | null = null;
      const visitedNodes = new Set<string>();

      for (let day = 1; day <= days; day++) {
        // Get optimal next node using DRL
        if (currentNodeId) {
          const nextNode = await this.drlService.getOptimalNextNode(
            userId,
            currentNodeId,
            subjectId,
          );

          if (nextNode && !visitedNodes.has(nextNode.nodeId)) {
            const learningNode = await this.learningNodesService.findById(
              nextNode.nodeId,
            );

            if (learningNode) {
              // Check if should skip (ITS)
              const skipCheck = await this.itsService.shouldSkipTopic(
                userId,
                learningNode.id,
              );

              if (!skipCheck.shouldSkip) {
                // Adjust difficulty (ITS)
                const difficultyAdjustment = await this.itsService.adjustDifficulty(
                  userId,
                  learningNode.id,
                  learningNode.difficulty || 'medium',
                );

                roadmap.push({
                  day,
                  nodeId: learningNode.id,
                  nodeName: learningNode.title,
                  difficulty: difficultyAdjustment.suggestedDifficulty,
                  estimatedTime: this.estimateTime(
                    difficultyAdjustment.suggestedDifficulty,
                    recommendations.learningPace,
                  ),
                  reason: nextNode.reason,
                });

                currentNodeId = learningNode.id;
                visitedNodes.add(learningNode.id);
                continue;
              }
            }
          }
        }

        // Fallback: Use subject learning nodes or recommendations
        const fallbackNode = subjectLearningNodes.find(
          (n) => !visitedNodes.has(n.id),
        );

        if (fallbackNode) {
          roadmap.push({
            day,
            nodeId: fallbackNode.id,
            nodeName: fallbackNode.title,
            difficulty: fallbackNode.difficulty || 'medium',
            estimatedTime: this.estimateTime(
              fallbackNode.difficulty || 'medium',
              recommendations.learningPace,
            ),
            reason: 'Recommended based on your learning goals',
          });
          currentNodeId = fallbackNode.id;
          visitedNodes.add(fallbackNode.id);
        } else {
          // No more nodes
          break;
        }
      }

      // Step 5: Generate summary using AI
      const summary = await this.generateRoadmapSummary(
        roadmap,
        goals,
        recommendations,
      );

      // Calculate confidence based on DRL and RAG results
      const confidence = this.calculateConfidence(roadmap.length, days);

      this.logger.log(
        `Generated roadmap with ${roadmap.length} nodes, confidence: ${confidence}`,
      );

      return { roadmap, summary, confidence };
    } catch (error) {
      this.logger.error(
        `LangChain roadmap generation error: ${error.message}`,
        error.stack,
      );
      throw error;
    }
  }

  /**
   * Extract learning goals from user query
   */
  private async extractLearningGoals(query: string): Promise<string[]> {
    const prompt = `Extract learning goals from this user query. Return a JSON array of goal strings.

Query: "${query}"

Goals (JSON array):`;

    try {
      const response = await this.aiService.chat([
        { role: 'user', content: prompt },
      ]);

      // Try to parse JSON from response
      const jsonMatch = response.match(/\[.*\]/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }

      // Fallback: simple extraction
      return query.split(/[,\s]+/).filter((w) => w.length > 3);
    } catch {
      return [query];
    }
  }

  /**
   * Generate roadmap summary using AI
   */
  private async generateRoadmapSummary(
    roadmap: Array<{
      day: number;
      nodeId: string;
      nodeName: string;
      difficulty: string;
    }>,
    goals: string[],
    recommendations: any,
  ): Promise<string> {
    const roadmapText = roadmap
      .map((r) => `Day ${r.day}: ${r.nodeName} (${r.difficulty})`)
      .join('\n');

    const prompt = `Generate a personalized learning roadmap summary.

Learning Goals: ${goals.join(', ')}
Strengths: ${recommendations.strengths.length} topics mastered
Weaknesses: ${recommendations.weaknesses.length} topics need improvement
Learning Pace: ${Math.round(recommendations.learningPace / 60)} minutes per node

Roadmap:
${roadmapText}

Generate a motivating summary (2-3 sentences) that:
1. Highlights the personalized path
2. Addresses strengths and weaknesses
3. Encourages the learner

Summary:`;

    return this.aiService.chat([
      { role: 'user', content: prompt },
    ]);
  }

  /**
   * Estimate time for a node based on difficulty and user pace
   */
  private estimateTime(
    difficulty: string,
    userPace: number,
  ): number {
    const difficultyMultipliers: Record<string, number> = {
      easy: 0.7,
      medium: 1.0,
      hard: 1.5,
      expert: 2.0,
    };

    const multiplier = difficultyMultipliers[difficulty] || 1.0;
    return Math.round(userPace * multiplier); // seconds
  }

  /**
   * Calculate confidence score for roadmap
   */
  private calculateConfidence(roadmapLength: number, targetDays: number): number {
    const coverage = roadmapLength / targetDays;
    return Math.min(1, coverage * 0.8 + 0.2); // Base confidence + coverage bonus
  }
}

