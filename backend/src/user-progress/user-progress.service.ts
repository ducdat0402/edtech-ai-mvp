import { Injectable, forwardRef, Inject, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserProgress } from './entities/user-progress.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { UserCurrencyService } from '../user-currency/user-currency.service';
import { RewardSource } from '../user-currency/entities/reward-transaction.entity';
import { ContentItemsService } from '../content-items/content-items.service';
import { QuestsService } from '../quests/quests.service';
import { QuestType } from '../quests/entities/quest.entity';
import { SkillTreeService } from '../skill-tree/skill-tree.service';

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
    @Inject(forwardRef(() => SkillTreeService))
    private skillTreeService: SkillTreeService,
  ) {}

  /**
   * Map itemType from API to completedItems key
   */
  private mapItemTypeToKey(itemType: string): 'concepts' | 'examples' | 'hiddenRewards' | 'bossQuiz' {
    const mapping: Record<string, 'concepts' | 'examples' | 'hiddenRewards' | 'bossQuiz'> = {
      'concept': 'concepts',
      'example': 'examples',
      'hidden_reward': 'hiddenRewards',
      'boss_quiz': 'bossQuiz',
    };
    return mapping[itemType] || 'concepts';
  }

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
    } else {
      // ✅ Fix old data: migrate from old keys to new keys
      if (!progress.completedItems) {
        progress.completedItems = {
          concepts: [],
          examples: [],
          hiddenRewards: [],
          bossQuiz: [],
        };
        await this.progressRepository.save(progress);
      } else {
        // ✅ Migrate old keys to new keys
        const oldToNewMapping: Record<string, 'concepts' | 'examples' | 'hiddenRewards' | 'bossQuiz'> = {
          'concept': 'concepts',
          'example': 'examples',
          'hidden_reward': 'hiddenRewards',
          'boss_quiz': 'bossQuiz',
        };
        
        let needsUpdate = false;
        const migratedItems: any = {
          concepts: [],
          examples: [],
          hiddenRewards: [],
          bossQuiz: [],
        };
        
        // Migrate old keys
        for (const [oldKey, newKey] of Object.entries(oldToNewMapping)) {
          if (progress.completedItems[oldKey] && Array.isArray(progress.completedItems[oldKey])) {
            // Merge old data into new key
            migratedItems[newKey] = [
              ...(migratedItems[newKey] || []),
              ...(progress.completedItems[oldKey] as string[]),
            ];
            needsUpdate = true;
          }
        }
        
        // Keep existing new keys
        for (const key of ['concepts', 'examples', 'hiddenRewards', 'bossQuiz']) {
          if (progress.completedItems[key] && Array.isArray(progress.completedItems[key])) {
            // Merge with migrated data, avoiding duplicates
            const existing = progress.completedItems[key] as string[];
            const migrated = migratedItems[key] || [];
            migratedItems[key] = [...new Set([...existing, ...migrated])];
          } else if (!migratedItems[key] || migratedItems[key].length === 0) {
            migratedItems[key] = [];
          }
        }
        
        if (needsUpdate) {
          progress.completedItems = migratedItems;
          await this.progressRepository.save(progress);
        } else {
          // ✅ Ensure all arrays exist even if no migration needed
          const defaultItems = {
            concepts: [],
            examples: [],
            hiddenRewards: [],
            bossQuiz: [],
          };
          
          for (const key of Object.keys(defaultItems)) {
            if (!progress.completedItems[key] || !Array.isArray(progress.completedItems[key])) {
              progress.completedItems[key] = [];
              needsUpdate = true;
            }
          }
          
          if (needsUpdate) {
            await this.progressRepository.save(progress);
          }
        }
      }
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

    // ✅ Ensure completedItems structure exists
    if (!progress.completedItems) {
      progress.completedItems = {
        concepts: [],
        examples: [],
        hiddenRewards: [],
        bossQuiz: [],
      };
    }

    // ✅ Map itemType to correct key (e.g., 'concept' -> 'concepts')
    const completedItemsKey = this.mapItemTypeToKey(itemType);

    // ✅ Ensure the specific array exists
    if (!progress.completedItems[completedItemsKey]) {
      progress.completedItems[completedItemsKey] = [];
    }

    // Check if already completed
    const alreadyCompleted = progress.completedItems[completedItemsKey].includes(
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
      if (!progress.completedItems[completedItemsKey]) {
        progress.completedItems[completedItemsKey] = [];
      }
      progress.completedItems[completedItemsKey].push(contentItemId);

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

      // Log reward transaction
      if (rewardsGiven.xp > 0 || rewardsGiven.coins > 0 || Object.keys(rewardsGiven.shards).length > 0) {
        try {
          await this.currencyService.logReward(
            userId,
            RewardSource.CONTENT_ITEM,
            {
              xp: rewardsGiven.xp,
              coins: rewardsGiven.coins,
              shards: rewardsGiven.shards,
            },
            contentItemId,
            contentItem.title,
          );
        } catch (error) {
          // Log but don't fail the completion
          console.error('Error logging reward transaction:', error);
        }
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
      
      console.log(`📊 [completeContentItem] Learning node ${nodeId}: ${completed}/${total} items completed (${progress.progressPercentage.toFixed(1)}%)`);
      console.log(`📊 [completeContentItem] Completed items: concepts=${progress.completedItems.concepts.length}, examples=${progress.completedItems.examples.length}, hiddenRewards=${progress.completedItems.hiddenRewards.length}, bossQuiz=${progress.completedItems.bossQuiz.length > 0 ? 1 : 0}`);

      // Check if completed
      if (progress.progressPercentage >= 100 && !progress.isCompleted) {
        console.log(`✅ Learning node ${nodeId} completed! Progress: ${progress.progressPercentage}%`);
        progress.isCompleted = true;
        progress.completedAt = new Date();
        // Bonus rewards for completing node
        await this.currencyService.addXP(userId, 50);
        await this.currencyService.addCoins(userId, 10);

        // ✅ Auto-complete corresponding skill node
        try {
          console.log(`🔄 Attempting to complete skill node for learning node ${nodeId}...`);
          const skillProgress = await this.skillTreeService.completeSkillNodeFromLearningNode(
            userId,
            nodeId,
          );
          if (skillProgress) {
            console.log(`✅ Skill node completed successfully! Status: ${skillProgress.status}`);
          } else {
            console.log(`⚠️  No skill node found or already completed for learning node ${nodeId}`);
          }
        } catch (error) {
          // Log but don't fail - skill tree might not exist yet
          console.error(
            `❌ Error completing skill node for learning node ${nodeId}:`,
            error,
          );
        }
      } else {
        console.log(`📊 Learning node ${nodeId} progress: ${progress.progressPercentage}% (not completed yet)`);
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

    // ✅ Recalculate progress percentage to ensure accuracy after migration
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

    const calculatedPercentage = total > 0 ? (completed / total) * 100 : 0;
    
    // Update progress percentage if it's different (e.g., after migration)
    if (Math.abs(progress.progressPercentage - calculatedPercentage) > 0.01) {
      progress.progressPercentage = calculatedPercentage;
      
      // Check if should be marked as completed
      if (calculatedPercentage >= 100 && !progress.isCompleted) {
        progress.isCompleted = true;
        if (!progress.completedAt) {
          progress.completedAt = new Date();
        }
      } else if (calculatedPercentage < 100 && progress.isCompleted) {
        progress.isCompleted = false;
      }
      
      // Save updated progress
      await this.progressRepository.save(progress);
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

