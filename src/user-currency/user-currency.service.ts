import { Injectable, NotFoundException, Inject, forwardRef } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, EntityManager, DataSource } from 'typeorm';
import { UserCurrency } from './entities/user-currency.entity';
import { RewardTransaction, RewardSource } from './entities/reward-transaction.entity';
import { UsersService } from '../users/users.service';

@Injectable()
export class UserCurrencyService {
  constructor(
    @InjectRepository(UserCurrency)
    private currencyRepository: Repository<UserCurrency>,
    @InjectRepository(RewardTransaction)
    private rewardTransactionRepository: Repository<RewardTransaction>,
    @Inject(forwardRef(() => UsersService))
    private usersService: UsersService,
    private dataSource: DataSource,
  ) {}

  // Level system constants
  private readonly BASE_XP_FOR_LEVEL_2 = 100; // XP cần để lên level 2
  private readonly LEVEL_MULTIPLIER = 1.30; // Mỗi level cần thêm 30% XP

  async getOrCreate(userId: string): Promise<UserCurrency> {
    let currency = await this.currencyRepository.findOne({
      where: { userId },
    });

    if (!currency) {
      currency = this.currencyRepository.create({
        userId,
        coins: 0,
        xp: 0,
        level: 1, // Mặc định level 1
        currentStreak: 0,
        shards: {},
      });
      currency = await this.currencyRepository.save(currency);
    } else {
      // Luôn tính lại level từ XP để đảm bảo chính xác
      const calculatedLevel = this.calculateLevelFromXP(currency.xp);
      if (currency.level !== calculatedLevel) {
        console.log(`🔄 Syncing level for user ${userId}: ${currency.level} → ${calculatedLevel} (XP: ${currency.xp})`);
        currency.level = calculatedLevel;
        await this.currencyRepository.save(currency);
      }
    }

    return currency;
  }

  /**
   * Tính XP cần để đạt level tiếp theo
   * Level 1→2: 100 XP
   * Level 2→3: 130 XP (100 * 1.3)
   * Level 3→4: 169 XP (130 * 1.3)
   */
  getXPRequiredForLevel(level: number): number {
    if (level <= 1) return 0;
    // XP cần cho level N = BASE_XP * (MULTIPLIER ^ (N-2))
    return Math.round(this.BASE_XP_FOR_LEVEL_2 * Math.pow(this.LEVEL_MULTIPLIER, level - 2));
  }

  /**
   * Tính tổng XP cần để đạt level cụ thể
   */
  getTotalXPForLevel(level: number): number {
    let total = 0;
    for (let i = 2; i <= level; i++) {
      total += this.getXPRequiredForLevel(i);
    }
    return total;
  }

  /**
   * Tính level từ tổng XP
   */
  calculateLevelFromXP(totalXP: number): number {
    let level = 1;
    let xpNeeded = 0;
    
    while (true) {
      const nextLevelXP = this.getXPRequiredForLevel(level + 1);
      if (xpNeeded + nextLevelXP > totalXP) {
        break;
      }
      xpNeeded += nextLevelXP;
      level++;
    }
    
    return level;
  }

  /**
   * Lấy thông tin level chi tiết
   */
  getLevelInfo(totalXP: number, currentLevel: number): {
    level: number;
    currentXP: number; // XP hiện tại trong level
    xpForNextLevel: number; // XP cần để lên level tiếp
    totalXPForCurrentLevel: number; // Tổng XP đã đạt đến level hiện tại
    progress: number; // % tiến độ level hiện tại (0-100)
  } {
    const totalXPForCurrentLevel = this.getTotalXPForLevel(currentLevel);
    const xpForNextLevel = this.getXPRequiredForLevel(currentLevel + 1);
    const currentXP = totalXP - totalXPForCurrentLevel;
    const progress = xpForNextLevel > 0 ? Math.min(100, (currentXP / xpForNextLevel) * 100) : 100;

    return {
      level: currentLevel,
      currentXP,
      xpForNextLevel,
      totalXPForCurrentLevel,
      progress: Math.round(progress * 10) / 10, // Round to 1 decimal
    };
  }

  async getCurrency(userId: string): Promise<UserCurrency> {
    return this.getOrCreate(userId);
  }

  /**
   * Add coins using atomic INCREMENT to prevent lost updates.
   * Safe for concurrent access (no read-modify-write race condition).
   */
  async addCoins(userId: string, amount: number): Promise<UserCurrency> {
    // Ensure user currency record exists
    await this.getOrCreate(userId);

    // Atomic increment - no race condition possible
    await this.currencyRepository
      .createQueryBuilder()
      .update(UserCurrency)
      .set({ coins: () => `coins + ${Math.floor(amount)}` })
      .where('userId = :userId', { userId })
      .execute();

    return this.getOrCreate(userId);
  }

  /**
   * Add coins within an existing transaction (for ACID payment processing).
   * Uses EntityManager from the transaction context.
   */
  async addCoinsTransactional(manager: EntityManager, userId: string, amount: number): Promise<void> {
    await manager
      .createQueryBuilder()
      .update(UserCurrency)
      .set({ coins: () => `coins + ${Math.floor(amount)}` })
      .where('userId = :userId', { userId })
      .execute();
  }

  async addXP(userId: string, amount: number): Promise<{
    currency: UserCurrency;
    leveledUp: boolean;
    newLevel?: number;
    oldLevel?: number;
  }> {
    const currency = await this.getOrCreate(userId);
    const oldLevel = currency.level || 1;
    
    currency.xp += amount;
    
    // Tính level mới dựa trên tổng XP
    const newLevel = this.calculateLevelFromXP(currency.xp);
    const leveledUp = newLevel > oldLevel;
    
    if (leveledUp) {
      currency.level = newLevel;
      console.log(`🎉 User ${userId} leveled up! ${oldLevel} → ${newLevel}`);
    }
    
    const savedCurrency = await this.currencyRepository.save(currency);
    
    // Also update User.totalXP for leaderboard (async, don't wait)
    this.usersService.addXP(userId, amount).catch((error) => {
      console.error('Error updating User.totalXP:', error);
      // Don't throw, just log
    });
    
    return {
      currency: savedCurrency,
      leveledUp,
      newLevel: leveledUp ? newLevel : undefined,
      oldLevel: leveledUp ? oldLevel : undefined,
    };
  }

  async addShard(
    userId: string,
    shardType: string,
    amount: number = 1,
  ): Promise<UserCurrency> {
    const currency = await this.getOrCreate(userId);
    if (!currency.shards) {
      currency.shards = {};
    }
    currency.shards[shardType] = (currency.shards[shardType] || 0) + amount;
    return this.currencyRepository.save(currency);
  }

  async updateStreak(userId: string): Promise<UserCurrency> {
    const currency = await this.getOrCreate(userId);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const lastActive = currency.lastActiveDate
      ? new Date(currency.lastActiveDate)
      : null;
    if (lastActive) {
      lastActive.setHours(0, 0, 0, 0);
    }

    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    if (!lastActive) {
      // First time
      currency.currentStreak = 1;
    } else if (lastActive.getTime() === today.getTime()) {
      // Already updated today
      // Do nothing
    } else if (lastActive.getTime() === yesterday.getTime()) {
      // Consecutive day
      currency.currentStreak += 1;
    } else {
      // Streak broken
      currency.currentStreak = 1;
    }

    currency.lastActiveDate = today;
    return this.currencyRepository.save(currency);
  }

  /**
   * Deduct coins using atomic DECREMENT with CHECK (coins >= amount).
   * Prevents race condition: if two requests try to deduct simultaneously,
   * only one succeeds because the WHERE clause is evaluated atomically.
   */
  async deductCoins(userId: string, amount: number): Promise<UserCurrency> {
    // Ensure user currency record exists
    await this.getOrCreate(userId);

    // Atomic decrement with balance check in a single SQL statement
    const result = await this.currencyRepository
      .createQueryBuilder()
      .update(UserCurrency)
      .set({ coins: () => `coins - ${Math.floor(amount)}` })
      .where('userId = :userId AND coins >= :amount', { userId, amount: Math.floor(amount) })
      .execute();

    if (result.affected === 0) {
      throw new Error('Insufficient coins');
    }

    return this.getOrCreate(userId);
  }

  async hasEnoughCoins(userId: string, amount: number): Promise<boolean> {
    const currency = await this.getOrCreate(userId);
    return currency.coins >= amount;
  }

  /**
   * Log a reward transaction
   */
  async logReward(
    userId: string,
    source: RewardSource,
    rewards: {
      xp?: number;
      coins?: number;
      shards?: Record<string, number>;
    },
    sourceId?: string,
    sourceName?: string,
  ): Promise<RewardTransaction> {
    const transaction = this.rewardTransactionRepository.create({
      userId,
      source,
      sourceId,
      sourceName,
      xp: rewards.xp || 0,
      coins: rewards.coins || 0,
      shards: rewards.shards || {},
    });

    return this.rewardTransactionRepository.save(transaction);
  }

  /**
   * Log a reward transaction within an existing transaction context (for ACID payment processing).
   */
  async logRewardTransactional(
    manager: EntityManager,
    userId: string,
    source: RewardSource,
    rewards: {
      xp?: number;
      coins?: number;
      shards?: Record<string, number>;
    },
    sourceId?: string,
    sourceName?: string,
  ): Promise<RewardTransaction> {
    const transaction = manager.create(RewardTransaction, {
      userId,
      source,
      sourceId,
      sourceName,
      xp: rewards.xp || 0,
      coins: rewards.coins || 0,
      shards: rewards.shards || {},
    });

    return manager.save(transaction);
  }

  /**
   * Get DataSource for external transaction management
   */
  getDataSource(): DataSource {
    return this.dataSource;
  }

  /**
   * Get rewards history for a user
   */
  async getRewardsHistory(
    userId: string,
    options?: {
      limit?: number;
      offset?: number;
      source?: RewardSource;
      startDate?: Date;
      endDate?: Date;
    },
  ): Promise<{
    transactions: RewardTransaction[];
    total: number;
  }> {
    const limit = options?.limit || 50;
    const offset = options?.offset || 0;

    const queryBuilder = this.rewardTransactionRepository
      .createQueryBuilder('transaction')
      .where('transaction.userId = :userId', { userId })
      .orderBy('transaction.createdAt', 'DESC');

    if (options?.source) {
      queryBuilder.andWhere('transaction.source = :source', {
        source: options.source,
      });
    }

    if (options?.startDate) {
      queryBuilder.andWhere('transaction.createdAt >= :startDate', {
        startDate: options.startDate,
      });
    }

    if (options?.endDate) {
      queryBuilder.andWhere('transaction.createdAt <= :endDate', {
        endDate: options.endDate,
      });
    }

    const [transactions, total] = await queryBuilder
      .skip(offset)
      .take(limit)
      .getManyAndCount();

    return {
      transactions,
      total,
    };
  }

  /**
   * Get coins earned today from reward transactions
   */
  async getCoinsEarnedToday(userId: string, today: Date): Promise<number> {
    try {
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      const result = await this.rewardTransactionRepository
        .createQueryBuilder('transaction')
        .select('SUM(transaction.coins)', 'totalCoins')
        .where('transaction.userId = :userId', { userId })
        .andWhere('transaction.createdAt >= :today', { today })
        .andWhere('transaction.createdAt < :tomorrow', { tomorrow })
        .getRawOne();

      return parseInt(result?.totalCoins || '0', 10);
    } catch (e) {
      console.error('Error getting coins earned today:', e);
      return 0;
    }
  }

  /**
   * Get XP earned today from reward transactions
   */
  async getXPEarnedToday(userId: string, today: Date): Promise<number> {
    try {
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      const result = await this.rewardTransactionRepository
        .createQueryBuilder('transaction')
        .select('SUM(transaction.xp)', 'totalXP')
        .where('transaction.userId = :userId', { userId })
        .andWhere('transaction.createdAt >= :today', { today })
        .andWhere('transaction.createdAt < :tomorrow', { tomorrow })
        .getRawOne();

      return parseInt(result?.totalXP || '0', 10);
    } catch (e) {
      console.error('Error getting XP earned today:', e);
      return 0;
    }
  }
}

