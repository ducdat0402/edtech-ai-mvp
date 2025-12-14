import { Injectable, forwardRef, Inject, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserProgress } from './entities/user-progress.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { UserCurrencyService } from '../user-currency/user-currency.service';
import { ContentItemsService } from '../content-items/content-items.service';
import { QuestsService } from '../quests/quests.service';
import { QuestType } from '../quests/entities/quest.entity';

@Injectable()
export class UserProgressService {
  constructor(
    @InjectRepository(UserProgress)
    private progressRepository: Repository<UserProgress>,
    @InjectRepository(LearningNode)
    private nodeRepository: Repository<LearningNode>,
    private currencyService: UserCurrencyService,
    private contentItemsService: ContentItemsService,
    @Inject(forwardRef(() => QuestsService))
    private questsService: QuestsService,
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

  async completeContentItem(
    userId: string,
    nodeId: string,
    contentItemId: string,
    itemType: 'concept' | 'example' | 'hidden_reward' | 'boss_quiz',
  ): Promise<{
    progress: UserProgress;
    rewards: {
      xp: number;
      coins: number;
      shards: Record<string, number>;
    };
  }> {
    const progress = await this.getOrCreate(userId, nodeId);
    const node = await this.nodeRepository.findOne({ where: { id: nodeId } });

    if (!node) {
      throw new NotFoundException(`Node not found: ${nodeId}`);
    }

    // Check if already completed
    const alreadyCompleted = progress.completedItems[itemType].includes(
      contentItemId,
    );

    // Get content item to extract rewards
    const contentItem = await this.contentItemsService.findById(contentItemId);
    if (!contentItem) {
      throw new NotFoundException(`Content item not found: ${contentItemId}`);
    }

    // Validate item type matches
    if (contentItem.type !== itemType) {
      throw new BadRequestException(
        `Item type mismatch: expected ${itemType}, got ${contentItem.type}`,
      );
    }

    // Add to completed items if not already completed
    if (!alreadyCompleted) {
      // Ensure the array exists
      if (!progress.completedItems[itemType]) {
        progress.completedItems[itemType] = [];
      }
      progress.completedItems[itemType].push(contentItemId);

      // Apply rewards only if not already completed
      const rewards = contentItem.rewards || {};
      const rewardsGiven = {
        xp: 0,
        coins: 0,
        shards: {} as Record<string, number>,
      };

      // Add XP
      if (rewards.xp) {
        await this.currencyService.addXP(userId, rewards.xp);
        rewardsGiven.xp = rewards.xp;
      }

      // Add Coins
      if (rewards.coin) {
        await this.currencyService.addCoins(userId, rewards.coin);
        rewardsGiven.coins = rewards.coin;
      }

      // Add Shards
      if (rewards.shard && rewards.shardAmount) {
        await this.currencyService.addShard(
          userId,
          rewards.shard,
          rewards.shardAmount,
        );
        rewardsGiven.shards[rewards.shard] = rewards.shardAmount;
      }

      // Update streak when completing items
      await this.currencyService.updateStreak(userId);

      // Update quest progress (with error handling)
      try {
        await this.questsService.checkAndUpdateQuestProgress(
          userId,
          QuestType.COMPLETE_ITEMS,
          1,
        );
      } catch (error) {
        // Log but don't fail the completion
        console.error('Error updating quest progress:', error);
        // Continue even if quest update fails
      }

      // Calculate progress percentage
      const total =
        node.contentStructure.concepts +
        node.contentStructure.examples +
        node.contentStructure.hiddenRewards +
        node.contentStructure.bossQuiz;

      const completed =
        progress.completedItems.concepts.length +
        progress.completedItems.examples.length +
        progress.completedItems.hiddenRewards.length +
        (progress.completedItems.bossQuiz.length > 0 ? 1 : 0);

      progress.progressPercentage = (completed / total) * 100;

      // Check if completed
      if (progress.progressPercentage >= 100 && !progress.isCompleted) {
        progress.isCompleted = true;
        progress.completedAt = new Date();
        // Bonus rewards for completing node
        await this.currencyService.addXP(userId, 50);
        await this.currencyService.addCoins(userId, 10);
      }

      const savedProgress = await this.progressRepository.save(progress);

      return {
        progress: savedProgress,
        rewards: rewardsGiven,
      };
    }

    // Already completed, return existing progress with no rewards
    return {
      progress,
      rewards: { xp: 0, coins: 0, shards: {} },
    };
  }

  async getUserNodeProgress(
    userId: string,
    nodeId: string,
  ): Promise<{
    progress: UserProgress;
    node: LearningNode;
    hud: {
      concepts: { completed: number; total: number };
      examples: { completed: number; total: number };
      hiddenRewards: { completed: number; total: number };
      bossQuiz: { completed: number; total: number };
      progressPercentage: number;
      isCompleted: boolean;
    };
  }> {
    const progress = await this.getOrCreate(userId, nodeId);
    const node = await this.nodeRepository.findOne({ where: { id: nodeId } });

    if (!node) {
      throw new NotFoundException(`Node not found: ${nodeId}`);
    }

    return {
      progress,
      node,
      hud: {
        concepts: {
          completed: progress.completedItems.concepts.length,
          total: node.contentStructure.concepts,
        },
        examples: {
          completed: progress.completedItems.examples.length,
          total: node.contentStructure.examples,
        },
        hiddenRewards: {
          completed: progress.completedItems.hiddenRewards.length,
          total: node.contentStructure.hiddenRewards,
        },
        bossQuiz: {
          completed: progress.completedItems.bossQuiz.length,
          total: node.contentStructure.bossQuiz,
        },
        progressPercentage: progress.progressPercentage,
        isCompleted: progress.isCompleted,
      },
    };
  }

  async getCompletedNodes(userId: string): Promise<string[]> {
    const progresses = await this.progressRepository.find({
      where: { userId, isCompleted: true },
    });
    return progresses.map((p) => p.nodeId);
  }

  calculateProgress(
    completedItems: {
      concepts: string[];
      examples: string[];
      hiddenRewards: string[];
      bossQuiz: string[];
    },
    node: LearningNode,
  ): number {
    const total =
      node.contentStructure.concepts +
      node.contentStructure.examples +
      node.contentStructure.hiddenRewards +
      node.contentStructure.bossQuiz;

    const completed =
      completedItems.concepts.length +
      completedItems.examples.length +
      completedItems.hiddenRewards.length +
      (completedItems.bossQuiz.length > 0 ? 1 : 0);

    return (completed / total) * 100;
  }
}

