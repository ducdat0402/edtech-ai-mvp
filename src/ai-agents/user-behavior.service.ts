import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { UserBehavior } from './entities/user-behavior.entity';

@Injectable()
export class UserBehaviorService {
  private readonly logger = new Logger(UserBehaviorService.name);

  constructor(
    @InjectRepository(UserBehavior)
    private behaviorRepository: Repository<UserBehavior>,
  ) {}

  /**
   * Track a user behavior event
   */
  async trackBehavior(
    userId: string,
    nodeId: string,
    action: string,
    metrics?: Partial<UserBehavior['metrics']>,
    context?: Partial<UserBehavior['context']>,
    contentItemId?: string,
  ): Promise<UserBehavior> {
    const behavior = this.behaviorRepository.create({
      userId,
      nodeId,
      contentItemId,
      action,
      metrics: metrics || {},
      context: context || {},
    });

    return this.behaviorRepository.save(behavior);
  }

  /**
   * Get user behavior history for a node
   */
  async getNodeBehavior(
    userId: string,
    nodeId: string,
    limit: number = 50,
  ): Promise<UserBehavior[]> {
    return this.behaviorRepository.find({
      where: { userId, nodeId },
      order: { createdAt: 'DESC' },
      take: limit,
    });
  }

  /**
   * Calculate mastery level for a node
   * Based on completion rate, accuracy, time spent, errors
   */
  async calculateMastery(userId: string, nodeId: string): Promise<number> {
    const behaviors = await this.getNodeBehavior(userId, nodeId, 100);

    if (behaviors.length === 0) {
      return 0;
    }

    // Calculate metrics
    const completions = behaviors.filter((b) => b.action === 'complete').length;
    const attempts = behaviors.filter((b) => b.action === 'attempt_quiz').length;
    const errors = behaviors.reduce((sum, b) => sum + (b.metrics.errors || 0), 0);
    const correctAnswers = behaviors.reduce(
      (sum, b) => sum + (b.metrics.correctAnswers || 0),
      0,
    );
    const totalAnswers = correctAnswers + errors;
    const accuracy = totalAnswers > 0 ? correctAnswers / totalAnswers : 0;

    // Calculate mastery (0-1)
    // Factors:
    // - Completion rate: 40%
    // - Accuracy: 40%
    // - Error rate: -20% (penalty)
    const completionRate = completions / Math.max(behaviors.length, 1);
    const errorRate = errors / Math.max(totalAnswers, 1);

    const mastery =
      completionRate * 0.4 + accuracy * 0.4 - errorRate * 0.2;

    return Math.max(0, Math.min(1, mastery));
  }

  /**
   * Get user's learning pace (average time per node)
   */
  async getLearningPace(userId: string, days: number = 7): Promise<number> {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const behaviors = await this.behaviorRepository.find({
      where: {
        userId,
        createdAt: Between(startDate, new Date()),
        action: 'complete',
      },
    });

    if (behaviors.length === 0) {
      return 0;
    }

    const totalTime = behaviors.reduce(
      (sum, b) => sum + (b.metrics.completionTime || 0),
      0,
    );

    return totalTime / behaviors.length; // Average seconds per node
  }

  /**
   * Get user's error patterns
   */
  async getErrorPatterns(userId: string, nodeId?: string): Promise<{
    totalErrors: number;
    averageErrorsPerNode: number;
    errorRate: number;
    consecutiveErrors: number;
    errorProneNodes: Array<{ nodeId: string; errorCount: number }>;
  }> {
    const where: any = { userId };
    if (nodeId) {
      where.nodeId = nodeId;
    }

    const behaviors = await this.behaviorRepository.find({
      where,
      order: { createdAt: 'DESC' },
      take: 1000,
    });

    const totalErrors = behaviors.reduce(
      (sum, b) => sum + (b.metrics.errors || 0),
      0,
    );
    const uniqueNodes = new Set(behaviors.map((b) => b.nodeId));
    const averageErrorsPerNode = uniqueNodes.size > 0
      ? totalErrors / uniqueNodes.size
      : 0;

    const totalAttempts = behaviors.filter((b) => b.action === 'attempt_quiz')
      .length;
    const errorRate = totalAttempts > 0 ? totalErrors / totalAttempts : 0;

    // Calculate consecutive errors
    let consecutiveErrors = 0;
    let maxConsecutive = 0;
    for (const behavior of behaviors) {
      if (behavior.metrics.errors && behavior.metrics.errors > 0) {
        consecutiveErrors++;
        maxConsecutive = Math.max(maxConsecutive, consecutiveErrors);
      } else {
        consecutiveErrors = 0;
      }
    }

    // Find error-prone nodes
    const nodeErrorCounts = new Map<string, number>();
    behaviors.forEach((b) => {
      if (b.metrics.errors && b.metrics.errors > 0) {
        const current = nodeErrorCounts.get(b.nodeId) || 0;
        nodeErrorCounts.set(b.nodeId, current + b.metrics.errors);
      }
    });

    const errorProneNodes = Array.from(nodeErrorCounts.entries())
      .map(([nodeId, errorCount]) => ({ nodeId, errorCount }))
      .sort((a, b) => b.errorCount - a.errorCount)
      .slice(0, 10);

    return {
      totalErrors,
      averageErrorsPerNode,
      errorRate,
      consecutiveErrors: maxConsecutive,
      errorProneNodes,
    };
  }

  /**
   * Get user's strengths and weaknesses
   */
  async getStrengthsAndWeaknesses(userId: string): Promise<{
    strengths: Array<{ nodeId: string; mastery: number }>;
    weaknesses: Array<{ nodeId: string; mastery: number }>;
  }> {
    const behaviors = await this.behaviorRepository
      .createQueryBuilder('behavior')
      .select('behavior.nodeId', 'nodeId')
      .where('behavior.userId = :userId', { userId })
      .groupBy('behavior.nodeId')
      .getRawMany();

    const masteries = await Promise.all(
      behaviors.map(async (b) => ({
        nodeId: b.nodeId,
        mastery: await this.calculateMastery(userId, b.nodeId),
      })),
    );

    const strengths = masteries
      .filter((m) => m.mastery >= 0.7)
      .sort((a, b) => b.mastery - a.mastery)
      .slice(0, 10);

    const weaknesses = masteries
      .filter((m) => m.mastery < 0.5)
      .sort((a, b) => a.mastery - b.mastery)
      .slice(0, 10);

    return { strengths, weaknesses };
  }
}

