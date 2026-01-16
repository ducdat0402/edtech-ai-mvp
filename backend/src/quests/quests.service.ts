import { Injectable, Inject, forwardRef } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { Quest, QuestType, QuestStatus } from './entities/quest.entity';
import { UserQuest } from './entities/user-quest.entity';
import { UserCurrencyService } from '../user-currency/user-currency.service';
import { UserProgressService } from '../user-progress/user-progress.service';

@Injectable()
export class QuestsService {
  constructor(
    @InjectRepository(Quest)
    private questRepository: Repository<Quest>,
    @InjectRepository(UserQuest)
    private userQuestRepository: Repository<UserQuest>,
    private currencyService: UserCurrencyService,
    @Inject(forwardRef(() => UserProgressService))
    private progressService: UserProgressService,
  ) {}

  async getDailyQuests(userId: string): Promise<any[]> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Get or create daily quests for today
    let userQuests = await this.userQuestRepository.find({
      where: {
        userId,
        date: today,
      },
      relations: ['quest'],
    });

    // If no quests for today, generate them
    if (userQuests.length === 0) {
      userQuests = await this.generateDailyQuests(userId, today);
    }

    // Update progress for each quest
    const updatedQuests = await Promise.all(
      userQuests.map(async (userQuest) => {
        if (!userQuest.quest) {
          return null;
        }
        
        const progress = await this.calculateQuestProgress(
          userId,
          userQuest.quest,
        );
        userQuest.progress = progress;
        await this.userQuestRepository.save(userQuest);

        return {
          id: userQuest.id,
          quest: userQuest.quest,
          progress,
          target: userQuest.quest.requirements?.target || 0,
          status: userQuest.status,
          completedAt: userQuest.completedAt,
          claimedAt: userQuest.claimedAt,
        };
      }),
    );

    return updatedQuests.filter((quest) => quest !== null);
  }

  private async generateDailyQuests(
    userId: string,
    date: Date,
  ): Promise<UserQuest[]> {
    // Get template daily quests
    const templateQuests = await this.questRepository.find({
      where: { isDaily: true, isActive: true },
    });

    // If no templates, create default ones
    if (templateQuests.length === 0) {
      await this.createDefaultQuests();
      const updatedTemplates = await this.questRepository.find({
        where: { isDaily: true, isActive: true },
      });
      templateQuests.push(...updatedTemplates);
    }

    // Create user quests for today
    const userQuests = templateQuests.map((quest) =>
      this.userQuestRepository.create({
        userId,
        questId: quest.id,
        date,
        status: QuestStatus.ACTIVE,
        progress: 0,
      }),
    );

    return this.userQuestRepository.save(userQuests);
  }

  private async createDefaultQuests(): Promise<void> {
    const defaultQuests = [
      {
        title: 'Học 3 bài hôm nay',
        description: 'Hoàn thành 3 content items để nhận 20 XP và 5 coin',
        type: QuestType.COMPLETE_ITEMS,
        requirements: { target: 3 },
        rewards: { xp: 20, coin: 5 },
        metadata: { icon: '📚', category: 'learning', priority: 3 },
        isDaily: true,
        isActive: true,
      },
      {
        title: 'Duy trì streak',
        description: 'Đăng nhập và học bài hôm nay để duy trì streak',
        type: QuestType.MAINTAIN_STREAK,
        requirements: { target: 1 },
        rewards: { xp: 10, coin: 2 },
        metadata: { icon: '🔥', category: 'engagement', priority: 5 },
        isDaily: true,
        isActive: true,
      },
      {
        title: 'Kiếm 10 coin',
        description: 'Hoàn thành các bài học để kiếm coin',
        type: QuestType.EARN_COINS,
        requirements: { target: 10 },
        rewards: { xp: 15, coin: 3 },
        metadata: { icon: '💰', category: 'currency', priority: 2 },
        isDaily: true,
        isActive: true,
      },
      {
        title: 'Hoàn thành skill node hôm nay',
        description: 'Hoàn thành một skill node trong skill tree',
        type: QuestType.COMPLETE_NODE,
        requirements: { target: 1 },
        rewards: { xp: 25, coin: 5 },
        metadata: { icon: '✅', category: 'skill_tree', priority: 4 },
        isDaily: true,
        isActive: true,
      },
    ];

    for (const questData of defaultQuests) {
      const existing = await this.questRepository.findOne({
        where: { title: questData.title, isDaily: true },
      });

      if (!existing) {
        const quest = this.questRepository.create(questData);
        await this.questRepository.save(quest);
      }
    }
  }

  private async calculateQuestProgress(
    userId: string,
    quest: Quest,
  ): Promise<number> {
    if (!quest || !quest.type) {
      return 0;
    }
    
    switch (quest.type) {
      case QuestType.COMPLETE_ITEMS:
        // Count completed items today
        // This would need to query user_progress for today's completions
        // Simplified: return 0 for now, will be updated by event handlers
        return 0;

      case QuestType.MAINTAIN_STREAK:
        // Check if user has activity today
        const currency = await this.currencyService.getCurrency(userId);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const lastActive = currency.lastActiveDate
          ? new Date(currency.lastActiveDate)
          : null;
        if (lastActive) {
          lastActive.setHours(0, 0, 0, 0);
          return lastActive.getTime() === today.getTime() ? 1 : 0;
        }
        return 0;

      case QuestType.EARN_COINS:
        // This would need to track coins earned today
        // Simplified: return 0
        return 0;

      case QuestType.EARN_XP:
        // This would need to track XP earned today
        // Simplified: return 0
        return 0;

      case QuestType.COMPLETE_NODE:
        // Check if any node completed today
        return 0;

      case QuestType.COMPLETE_DAILY_LESSON:
        // Legacy quest type - now handled by COMPLETE_NODE
        // Check if any skill node completed today
        return 0;

      default:
        return 0;
    }
  }

  async checkAndUpdateQuestProgress(
    userId: string,
    questType: QuestType,
    amount: number = 1,
  ): Promise<void> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const userQuests = await this.userQuestRepository.find({
      where: {
        userId,
        date: today,
        status: QuestStatus.ACTIVE,
      },
      relations: ['quest'],
    });

    for (const userQuest of userQuests) {
      if (!userQuest.quest || userQuest.quest.type !== questType) {
        continue;
      }
      
      userQuest.progress += amount;

      // Check if completed
      const target = userQuest.quest.requirements?.target || 0;
      if (
        userQuest.progress >= target &&
        userQuest.status === QuestStatus.ACTIVE
      ) {
        userQuest.status = QuestStatus.COMPLETED;
        userQuest.completedAt = new Date();
      }

      await this.userQuestRepository.save(userQuest);
    }
  }

  async claimQuestReward(
    userId: string,
    userQuestId: string,
  ): Promise<{ success: boolean; rewards: any }> {
    const userQuest = await this.userQuestRepository.findOne({
      where: { id: userQuestId, userId },
      relations: ['quest'],
    });

    if (!userQuest) {
      throw new Error('Quest not found');
    }

    if (userQuest.status !== QuestStatus.COMPLETED) {
      throw new Error('Quest not completed yet');
    }

    if (userQuest.claimedAt) {
      throw new Error('Reward already claimed');
    }

    if (!userQuest.quest) {
      throw new Error('Quest data not found');
    }

    // Apply rewards
    const rewards = userQuest.quest.rewards;
    if (rewards?.xp) {
      await this.currencyService.addXP(userId, rewards.xp);
    }
    if (rewards?.coin) {
      await this.currencyService.addCoins(userId, rewards.coin);
    }
    if (rewards?.shard && rewards?.shardAmount) {
      await this.currencyService.addShard(
        userId,
        rewards.shard,
        rewards.shardAmount,
      );
    }

    // Mark as claimed
    userQuest.status = QuestStatus.CLAIMED;
    userQuest.claimedAt = new Date();
    await this.userQuestRepository.save(userQuest);

    return {
      success: true,
      rewards,
    };
  }

  async getQuestHistory(
    userId: string,
    days: number = 7,
  ): Promise<UserQuest[]> {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    return this.userQuestRepository.find({
      where: {
        userId,
        date: Between(startDate, endDate),
      },
      relations: ['quest'],
      order: { date: 'DESC', createdAt: 'DESC' },
    });
  }
}

