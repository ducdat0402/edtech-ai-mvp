import { Injectable, NotFoundException, Inject, forwardRef } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
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
  ) {}

  async getOrCreate(userId: string): Promise<UserCurrency> {
    let currency = await this.currencyRepository.findOne({
      where: { userId },
    });

    if (!currency) {
      currency = this.currencyRepository.create({
        userId,
        coins: 0,
        xp: 0,
        currentStreak: 0,
        shards: {},
      });
      currency = await this.currencyRepository.save(currency);
    }

    return currency;
  }

  async getCurrency(userId: string): Promise<UserCurrency> {
    return this.getOrCreate(userId);
  }

  async addCoins(userId: string, amount: number): Promise<UserCurrency> {
    const currency = await this.getOrCreate(userId);
    currency.coins += amount;
    return this.currencyRepository.save(currency);
  }

  async addXP(userId: string, amount: number): Promise<UserCurrency> {
    const currency = await this.getOrCreate(userId);
    currency.xp += amount;
    const savedCurrency = await this.currencyRepository.save(currency);
    
    // Also update User.totalXP for leaderboard (async, don't wait)
    this.usersService.addXP(userId, amount).catch((error) => {
      console.error('Error updating User.totalXP:', error);
      // Don't throw, just log
    });
    
    return savedCurrency;
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

  async deductCoins(userId: string, amount: number): Promise<UserCurrency> {
    const currency = await this.getOrCreate(userId);
    if (currency.coins < amount) {
      throw new Error('Insufficient coins');
    }
    currency.coins -= amount;
    return this.currencyRepository.save(currency);
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
}

