import { Injectable, forwardRef, Inject, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserProgress } from './entities/user-progress.entity';
import { UserTopicProgress } from './entities/user-topic-progress.entity';
import { UserDomainProgress } from './entities/user-domain-progress.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { Topic } from '../topics/entities/topic.entity';
import { Domain } from '../domains/entities/domain.entity';
import { UserCurrencyService } from '../user-currency/user-currency.service';
import { RewardSource } from '../user-currency/entities/reward-transaction.entity';
import { QuestsService } from '../quests/quests.service';
import { QuestType } from '../quests/entities/quest.entity';
import { LessonTypeContentsService } from '../lesson-type-contents/lesson-type-contents.service';

export interface RewardEntry {
  level: 'lesson_type' | 'lesson' | 'topic' | 'domain';
  name: string;
  xp: number;
  coins: number;
}

@Injectable()
export class UserProgressService {
  constructor(
    @InjectRepository(UserProgress)
    private progressRepository: Repository<UserProgress>,
    @InjectRepository(UserTopicProgress)
    private topicProgressRepository: Repository<UserTopicProgress>,
    @InjectRepository(UserDomainProgress)
    private domainProgressRepository: Repository<UserDomainProgress>,
    @InjectRepository(LearningNode)
    private nodeRepository: Repository<LearningNode>,
    @InjectRepository(Topic)
    private topicRepository: Repository<Topic>,
    @InjectRepository(Domain)
    private domainRepository: Repository<Domain>,
    private currencyService: UserCurrencyService,
    @Inject(forwardRef(() => QuestsService))
    private questsService: QuestsService,
    private lessonTypeContentsService: LessonTypeContentsService,
  ) {}

  async getOrCreate(userId: string, nodeId: string): Promise<UserProgress> {
    let progress = await this.progressRepository.findOne({
      where: { userId, nodeId },
      relations: ['node'],
    });

    if (!progress) {
      const node = await this.nodeRepository.findOne({
        where: { id: nodeId },
      });
      if (!node) {
        throw new NotFoundException(`Node not found: ${nodeId}`);
      }

      progress = this.progressRepository.create({
        userId,
        nodeId,
        completedItems: {
          concepts: [],
          examples: [],
          hiddenRewards: [],
          bossQuiz: [],
        },
        completedLessonTypes: [],
        progressPercentage: 0,
        isCompleted: false,
      });
      progress = await this.progressRepository.save(progress);
    }

    return progress;
  }

  async getProgress(userId: string, nodeId: string): Promise<UserProgress> {
    return this.getOrCreate(userId, nodeId);
  }

  // =====================
  // NEW: Complete a lesson type with cascade
  // =====================

  /**
   * Complete a specific lesson type for a learning node.
   * Triggers cascade: lesson type -> lesson -> topic -> domain
   */
  async completeLessonType(
    userId: string,
    nodeId: string,
    lessonType: string,
  ): Promise<{
    progress: UserProgress;
    rewards: RewardEntry[];
    lessonCompleted: boolean;
    topicCompleted: boolean;
    domainCompleted: boolean;
  }> {
    const rewards: RewardEntry[] = [];
    let lessonCompleted = false;
    let topicCompleted = false;
    let domainCompleted = false;

    // 1. Get or create progress for this node
    const progress = await this.getOrCreate(userId, nodeId);

    // Already completed this type? Return early
    if (progress.completedLessonTypes?.includes(lessonType)) {
      return { progress, rewards, lessonCompleted: progress.isCompleted, topicCompleted: false, domainCompleted: false };
    }

    // 2. Add lesson type to completedLessonTypes
    const updatedTypes = [...(progress.completedLessonTypes || []), lessonType];
    progress.completedLessonTypes = updatedTypes;

    // 3. Check if ALL available types for this node are completed
    const availableTypes = await this.lessonTypeContentsService.getAvailableTypes(nodeId);
    const allTypesCompleted = availableTypes.length > 0 &&
      availableTypes.every((t) => updatedTypes.includes(t));

    // Update progress percentage
    if (availableTypes.length > 0) {
      progress.progressPercentage = Math.round(
        (updatedTypes.filter((t) => availableTypes.includes(t)).length / availableTypes.length) * 100,
      );
    }

    if (allTypesCompleted && !progress.isCompleted) {
      // 4. Mark lesson as complete
      progress.isCompleted = true;
      progress.completedAt = new Date();
      progress.progressPercentage = 100;
      lessonCompleted = true;

      // 5. Award lesson rewards (use node's expReward/coinReward)
      const node = await this.nodeRepository.findOne({ where: { id: nodeId } });
      if (node) {
        const lessonXp = node.expReward || 0;
        const lessonCoins = node.coinReward || 0;

        if (lessonXp > 0 || lessonCoins > 0) {
          if (lessonXp > 0) await this.currencyService.addXP(userId, lessonXp);
          if (lessonCoins > 0) await this.currencyService.addCoins(userId, lessonCoins);

          rewards.push({
            level: 'lesson',
            name: node.title,
            xp: lessonXp,
            coins: lessonCoins,
          });

          try {
            await this.currencyService.logReward(
              userId,
              RewardSource.CONTENT_ITEM,
              { xp: lessonXp, coins: lessonCoins, shards: {} },
              nodeId,
              `Hoàn thành bài học: ${node.title}`,
            );
          } catch (error) {
            console.error('Error logging lesson reward:', error);
          }
        }

        // 6. Check topic completion
        if (node.topicId) {
          const topicResult = await this.checkAndCompleteTopicIfDone(userId, node.topicId);
          if (topicResult) {
            topicCompleted = true;
            rewards.push(topicResult);

            // 7. Check domain completion
            const topic = await this.topicRepository.findOne({ where: { id: node.topicId } });
            if (topic?.domainId) {
              const domainResult = await this.checkAndCompleteDomainIfDone(userId, topic.domainId);
              if (domainResult) {
                domainCompleted = true;
                rewards.push(domainResult);
              }
            }
          }
        }
      }

      // Update streak
      await this.currencyService.updateStreak(userId);

      // Update quest progress
      try {
        await this.questsService.checkAndUpdateQuestProgress(
          userId,
          QuestType.COMPLETE_ITEMS,
          1,
        );
      } catch (error) {
        console.error('Error updating quest progress:', error);
      }
    }

    const savedProgress = await this.progressRepository.save(progress);

    return { progress: savedProgress, rewards, lessonCompleted, topicCompleted, domainCompleted };
  }

  /**
   * Check if all lessons in a topic are completed, and if so mark topic complete + award rewards
   */
  private async checkAndCompleteTopicIfDone(
    userId: string,
    topicId: string,
  ): Promise<RewardEntry | null> {
    // Check if already completed
    const existingProgress = await this.topicProgressRepository.findOne({
      where: { userId, topicId },
    });
    if (existingProgress?.isCompleted) return null;

    // Get all nodes in this topic
    const topicNodes = await this.nodeRepository.find({
      where: { topicId },
    });

    if (topicNodes.length === 0) return null;

    // Check if all nodes are completed by this user
    const completedNodes = await this.progressRepository.find({
      where: { userId, isCompleted: true },
    });
    const completedNodeIds = new Set(completedNodes.map((p) => p.nodeId));

    const allNodesCompleted = topicNodes.every((n) => completedNodeIds.has(n.id));
    if (!allNodesCompleted) return null;

    // Mark topic as complete
    let topicProgress = existingProgress;
    if (!topicProgress) {
      topicProgress = this.topicProgressRepository.create({ userId, topicId });
    }
    topicProgress.isCompleted = true;
    topicProgress.completedAt = new Date();
    await this.topicProgressRepository.save(topicProgress);

    // Award topic rewards
    const topic = await this.topicRepository.findOne({ where: { id: topicId } });
    if (!topic) return null;

    const topicXp = topic.expReward || 0;
    const topicCoins = topic.coinReward || 0;

    if (topicXp > 0 || topicCoins > 0) {
      if (topicXp > 0) await this.currencyService.addXP(userId, topicXp);
      if (topicCoins > 0) await this.currencyService.addCoins(userId, topicCoins);

      try {
        await this.currencyService.logReward(
          userId,
          RewardSource.TOPIC,
          { xp: topicXp, coins: topicCoins, shards: {} },
          topicId,
          `Hoàn thành topic: ${topic.name}`,
        );
      } catch (error) {
        console.error('Error logging topic reward:', error);
      }
    }

    return {
      level: 'topic',
      name: topic.name,
      xp: topicXp,
      coins: topicCoins,
    };
  }

  /**
   * Check if all topics in a domain are completed, and if so mark domain complete + award rewards
   */
  private async checkAndCompleteDomainIfDone(
    userId: string,
    domainId: string,
  ): Promise<RewardEntry | null> {
    // Check if already completed
    const existingProgress = await this.domainProgressRepository.findOne({
      where: { userId, domainId },
    });
    if (existingProgress?.isCompleted) return null;

    // Get all topics in this domain
    const domainTopics = await this.topicRepository.find({
      where: { domainId },
    });

    if (domainTopics.length === 0) return null;

    // Check if all topics are completed by this user
    const completedTopics = await this.topicProgressRepository.find({
      where: { userId },
    });
    const completedTopicIds = new Set(
      completedTopics.filter((p) => p.isCompleted).map((p) => p.topicId),
    );

    const allTopicsCompleted = domainTopics.every((t) => completedTopicIds.has(t.id));
    if (!allTopicsCompleted) return null;

    // Mark domain as complete
    let domainProgress = existingProgress;
    if (!domainProgress) {
      domainProgress = this.domainProgressRepository.create({ userId, domainId });
    }
    domainProgress.isCompleted = true;
    domainProgress.completedAt = new Date();
    await this.domainProgressRepository.save(domainProgress);

    // Award domain rewards
    const domain = await this.domainRepository.findOne({ where: { id: domainId } });
    if (!domain) return null;

    const domainXp = domain.expReward || 0;
    const domainCoins = domain.coinReward || 0;

    if (domainXp > 0 || domainCoins > 0) {
      if (domainXp > 0) await this.currencyService.addXP(userId, domainXp);
      if (domainCoins > 0) await this.currencyService.addCoins(userId, domainCoins);

      try {
        await this.currencyService.logReward(
          userId,
          RewardSource.DOMAIN,
          { xp: domainXp, coins: domainCoins, shards: {} },
          domainId,
          `Hoàn thành domain: ${domain.name}`,
        );
      } catch (error) {
        console.error('Error logging domain reward:', error);
      }
    }

    return {
      level: 'domain',
      name: domain.name,
      xp: domainXp,
      coins: domainCoins,
    };
  }

  // =====================
  // Progress query methods
  // =====================

  /**
   * Get lesson type progress for a node
   */
  async getLessonTypeProgress(
    userId: string,
    nodeId: string,
  ): Promise<{
    completedTypes: string[];
    availableTypes: string[];
    totalTypes: number;
    completedCount: number;
    isLessonComplete: boolean;
  }> {
    const progress = await this.getOrCreate(userId, nodeId);
    const availableTypes = await this.lessonTypeContentsService.getAvailableTypes(nodeId);

    return {
      completedTypes: progress.completedLessonTypes || [],
      availableTypes,
      totalTypes: availableTypes.length,
      completedCount: (progress.completedLessonTypes || []).filter((t) =>
        availableTypes.includes(t),
      ).length,
      isLessonComplete: progress.isCompleted,
    };
  }

  /**
   * Get topic progress for a user
   */
  async getTopicProgress(
    userId: string,
    topicId: string,
  ): Promise<{
    isCompleted: boolean;
    completedAt: Date | null;
    totalLessons: number;
    completedLessons: number;
  }> {
    const topicProgress = await this.topicProgressRepository.findOne({
      where: { userId, topicId },
    });

    // Count total and completed lessons
    const topicNodes = await this.nodeRepository.find({ where: { topicId } });
    const completedProgresses = await this.progressRepository.find({
      where: { userId, isCompleted: true },
    });
    const completedNodeIds = new Set(completedProgresses.map((p) => p.nodeId));
    const completedLessons = topicNodes.filter((n) => completedNodeIds.has(n.id)).length;

    return {
      isCompleted: topicProgress?.isCompleted || false,
      completedAt: topicProgress?.completedAt || null,
      totalLessons: topicNodes.length,
      completedLessons,
    };
  }

  /**
   * Get domain progress for a user
   */
  async getDomainProgress(
    userId: string,
    domainId: string,
  ): Promise<{
    isCompleted: boolean;
    completedAt: Date | null;
    totalTopics: number;
    completedTopics: number;
  }> {
    const domainProgress = await this.domainProgressRepository.findOne({
      where: { userId, domainId },
    });

    // Count total and completed topics
    const domainTopics = await this.topicRepository.find({ where: { domainId } });
    const completedTopicProgresses = await this.topicProgressRepository.find({
      where: { userId },
    });
    const completedTopicIds = new Set(
      completedTopicProgresses.filter((p) => p.isCompleted).map((p) => p.topicId),
    );
    const completedTopics = domainTopics.filter((t) => completedTopicIds.has(t.id)).length;

    return {
      isCompleted: domainProgress?.isCompleted || false,
      completedAt: domainProgress?.completedAt || null,
      totalTopics: domainTopics.length,
      completedTopics,
    };
  }

  // =====================
  // Legacy methods (kept for backward compatibility)
  // =====================

  /**
   * Mark a learning node as completed (legacy - use completeLessonType for new flow)
   */
  async completeNode(
    userId: string,
    nodeId: string,
  ): Promise<{
    progress: UserProgress;
    rewards: { xp: number; coins: number };
  }> {
    const progress = await this.getOrCreate(userId, nodeId);

    if (progress.isCompleted) {
      return {
        progress,
        rewards: { xp: 0, coins: 0 },
      };
    }

    progress.isCompleted = true;
    progress.completedAt = new Date();
    progress.progressPercentage = 100;

    const savedProgress = await this.progressRepository.save(progress);

    // Use node's rewards if available, otherwise fallback to defaults
    const node = await this.nodeRepository.findOne({ where: { id: nodeId } });
    const rewards = {
      xp: node?.expReward || 50,
      coins: node?.coinReward || 10,
    };
    await this.currencyService.addXP(userId, rewards.xp);
    await this.currencyService.addCoins(userId, rewards.coins);

    // Log reward
    try {
      await this.currencyService.logReward(
        userId,
        RewardSource.CONTENT_ITEM,
        { xp: rewards.xp, coins: rewards.coins, shards: {} },
        nodeId,
        'Node completion',
      );
    } catch (error) {
      console.error('Error logging reward:', error);
    }

    // Update streak
    await this.currencyService.updateStreak(userId);

    // Update quest progress
    try {
      await this.questsService.checkAndUpdateQuestProgress(
        userId,
        QuestType.COMPLETE_ITEMS,
        1,
      );
    } catch (error) {
      console.error('Error updating quest progress:', error);
    }

    return { progress: savedProgress, rewards };
  }

  async getUserNodeProgress(
    userId: string,
    nodeId: string,
  ): Promise<{
    progress: UserProgress;
    node: LearningNode;
    isCompleted: boolean;
    progressPercentage: number;
    completedLessonTypes: string[];
  }> {
    const progress = await this.getOrCreate(userId, nodeId);
    const node = await this.nodeRepository.findOne({ where: { id: nodeId } });

    if (!node) {
      throw new NotFoundException(`Node not found: ${nodeId}`);
    }

    return {
      progress,
      node,
      isCompleted: progress.isCompleted,
      progressPercentage: progress.progressPercentage,
      completedLessonTypes: progress.completedLessonTypes || [],
    };
  }

  async getCompletedNodes(userId: string): Promise<string[]> {
    const progresses = await this.progressRepository.find({
      where: { userId, isCompleted: true },
    });
    return progresses.map((p) => p.nodeId);
  }

  /**
   * Count content items completed today for quest progress
   */
  async countCompletedItemsToday(userId: string, today: Date): Promise<number> {
    try {
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      const count = await this.progressRepository
        .createQueryBuilder('progress')
        .where('progress.userId = :userId', { userId })
        .andWhere('progress.isCompleted = :isCompleted', { isCompleted: true })
        .andWhere('progress.completedAt >= :today', { today })
        .andWhere('progress.completedAt < :tomorrow', { tomorrow })
        .getCount();

      return count;
    } catch (e) {
      console.error('Error counting completed items today:', e);
      return 0;
    }
  }

  /**
   * Count learning nodes completed today for quest progress
   */
  async countNodesCompletedToday(userId: string, today: Date): Promise<number> {
    return this.countCompletedItemsToday(userId, today);
  }
}
