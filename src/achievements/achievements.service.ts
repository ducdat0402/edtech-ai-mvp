import { Injectable, Inject, forwardRef } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Achievement, AchievementType } from './entities/achievement.entity';
import { UserAchievement } from './entities/user-achievement.entity';
import { UserCurrencyService } from '../user-currency/user-currency.service';
import { RewardSource } from '../user-currency/entities/reward-transaction.entity';
import { UserProgressService } from '../user-progress/user-progress.service';
import { QuestsService } from '../quests/quests.service';
import { UsersService } from '../users/users.service';

@Injectable()
export class AchievementsService {
  constructor(
    @InjectRepository(Achievement)
    private achievementRepository: Repository<Achievement>,
    @InjectRepository(UserAchievement)
    private userAchievementRepository: Repository<UserAchievement>,
    private currencyService: UserCurrencyService,
    @Inject(forwardRef(() => UserProgressService))
    private progressService: UserProgressService,
    @Inject(forwardRef(() => QuestsService))
    private questsService: QuestsService,
    @Inject(forwardRef(() => UsersService))
    private usersService: UsersService,
  ) {}

  /**
   * Get all available achievements
   */
  async getAllAchievements(): Promise<Achievement[]> {
    return this.achievementRepository.find({
      where: { isActive: true },
      order: { order: 'ASC' },
    });
  }

  /**
   * Get user's achievements
   */
  async getUserAchievements(userId: string): Promise<UserAchievement[]> {
    return this.userAchievementRepository.find({
      where: { userId },
      relations: ['achievement'],
      order: { unlockedAt: 'DESC' },
    });
  }

  /**
   * Get achievement by code
   */
  async getAchievementByCode(code: string): Promise<Achievement | null> {
    return this.achievementRepository.findOne({
      where: { code, isActive: true },
    });
  }

  /**
   * Check if user has unlocked an achievement
   */
  async hasUnlocked(userId: string, achievementId: string): Promise<boolean> {
    const userAchievement = await this.userAchievementRepository.findOne({
      where: { userId, achievementId },
    });
    return !!userAchievement;
  }

  /**
   * Unlock an achievement for a user
   */
  async unlockAchievement(
    userId: string,
    achievementId: string,
  ): Promise<UserAchievement> {
    // Check if already unlocked
    const existing = await this.userAchievementRepository.findOne({
      where: { userId, achievementId },
    });

    if (existing) {
      return existing;
    }

    // Get achievement
    const achievement = await this.achievementRepository.findOne({
      where: { id: achievementId },
    });

    if (!achievement) {
      throw new Error(`Achievement not found: ${achievementId}`);
    }

    // Create user achievement
    const userAchievement = this.userAchievementRepository.create({
      userId,
      achievementId,
      unlockedAt: new Date(),
      rewardsClaimed: false,
    });

    return this.userAchievementRepository.save(userAchievement);
  }

  /**
   * Claim rewards for an achievement
   */
  async claimRewards(
    userId: string,
    userAchievementId: string,
  ): Promise<{ success: boolean; rewards: any }> {
    const userAchievement = await this.userAchievementRepository.findOne({
      where: { id: userAchievementId, userId },
      relations: ['achievement'],
    });

    if (!userAchievement) {
      throw new Error('User achievement not found');
    }

    if (userAchievement.rewardsClaimed) {
      throw new Error('Rewards already claimed');
    }

    const achievement = userAchievement.achievement;
    if (!achievement) {
      throw new Error('Achievement data not found');
    }

    const rewards = achievement.rewards || {};

    // Apply rewards
    if (rewards.xp) {
      await this.currencyService.addXP(userId, rewards.xp);
    }
    if (rewards.coins) {
      await this.currencyService.addCoins(userId, rewards.coins);
    }
    if (rewards.shards) {
      for (const [shardType, amount] of Object.entries(rewards.shards)) {
        await this.currencyService.addShard(userId, shardType, amount as number);
      }
    }

    // Log reward transaction
    if (rewards.xp || rewards.coins || rewards.shards) {
      try {
        await this.currencyService.logReward(
          userId,
          RewardSource.BONUS,
          {
            xp: rewards.xp,
            coins: rewards.coins,
            shards: rewards.shards,
          },
          achievement.id,
          achievement.name,
        );
      } catch (error) {
        console.error('Error logging achievement reward:', error);
      }
    }

    // Mark as claimed
    userAchievement.rewardsClaimed = true;
    userAchievement.rewardsClaimedAt = new Date();
    await this.userAchievementRepository.save(userAchievement);

    return {
      success: true,
      rewards,
    };
  }

  /**
   * Check and unlock achievements based on user stats
   */
  async checkAndUnlockAchievements(userId: string): Promise<string[]> {
    const achievements = await this.getAllAchievements();
    const unlockedIds: string[] = [];

    for (const achievement of achievements) {
      // Skip if already unlocked
      if (await this.hasUnlocked(userId, achievement.id)) {
        continue;
      }

      // Check requirements based on type
      const shouldUnlock = await this.checkRequirements(
        userId,
        achievement,
      );

      if (shouldUnlock) {
        await this.unlockAchievement(userId, achievement.id);
        unlockedIds.push(achievement.id);
      }
    }

    return unlockedIds;
  }

  /**
   * Check if user meets achievement requirements
   */
  private async checkRequirements(
    userId: string,
    achievement: Achievement,
  ): Promise<boolean> {
    const req = achievement.requirements;

    switch (achievement.type) {
      case AchievementType.MILESTONE:
        const currency = await this.currencyService.getCurrency(userId);
        if (req.xp && currency.xp >= req.xp) return true;
        // Could check level here if we have level calculation
        break;

      case AchievementType.STREAK:
        const currency2 = await this.currencyService.getCurrency(userId);
        if (req.streak && currency2.currentStreak >= req.streak) return true;
        break;

      case AchievementType.COMPLETION:
        // Check completed nodes
        // This would require querying UserProgress
        // For now, simplified check
        break;

      case AchievementType.COLLECTION:
        const currency3 = await this.currencyService.getCurrency(userId);
        if (req.shardCount) {
          const totalShards = Object.values(currency3.shards || {}).reduce(
            (sum, count) => sum + (count as number),
            0,
          );
          if (totalShards >= req.shardCount) return true;
        }
        break;

      case AchievementType.SOCIAL:
        // Check leaderboard rank
        // Would need leaderboard service
        break;

      case AchievementType.QUEST_MASTER:
        // Check quest completion count
        // Would need quests service
        break;

      default:
        break;
    }

    return false;
  }

  /**
   * Get achievements with user's unlock status
   */
  async getAchievementsWithStatus(userId: string): Promise<
    Array<{
      achievement: Achievement;
      unlocked: boolean;
      unlockedAt?: Date;
      rewardsClaimed?: boolean;
      userAchievementId?: string;
    }>
  > {
    const achievements = await this.getAllAchievements();
    const userAchievements = await this.getUserAchievements(userId);

    const userAchievementMap = new Map(
      userAchievements.map((ua) => [ua.achievementId, ua]),
    );

    return achievements.map((achievement) => {
      const userAchievement = userAchievementMap.get(achievement.id);
      return {
        achievement,
        unlocked: !!userAchievement,
        unlockedAt: userAchievement?.unlockedAt,
        rewardsClaimed: userAchievement?.rewardsClaimed || false,
        userAchievementId: userAchievement?.id,
      };
    });
  }
}

