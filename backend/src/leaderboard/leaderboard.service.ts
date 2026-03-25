import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/entities/user.entity';
import { UserCurrency } from '../user-currency/entities/user-currency.entity';
import { UserProgress } from '../user-progress/entities/user-progress.entity';
import { LeaderboardEntry, LeaderboardResponse } from './entities/leaderboard.entity';
import {
  GLOBAL_STRICTLY_AHEAD_WHERE,
  bindGlobalStrictlyAhead,
} from './leaderboard-ranking.util';

@Injectable()
export class LeaderboardService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    @InjectRepository(UserCurrency)
    private currencyRepository: Repository<UserCurrency>,
    @InjectRepository(UserProgress)
    private progressRepository: Repository<UserProgress>,
  ) {}

  async getGlobalLeaderboard(
    limit: number = 100,
    page: number = 1,
    userId?: string,
  ): Promise<LeaderboardResponse> {
    const skip = (page - 1) * limit;

    // Ordinal rank: đồng XP → updatedAt sớm hơn (đạt mốc trước) đứng trên
    const users = await this.usersRepository
      .createQueryBuilder('user')
      .select([
        'user.id',
        'user.email',
        'user.fullName',
        'user.totalXP',
        'user.avatarUrl',
      ])
      .orderBy('user.totalXP', 'DESC')
      .addOrderBy('user.updatedAt', 'ASC')
      .addOrderBy('user.id', 'ASC')
      .skip(skip)
      .take(limit)
      .getMany();

    // Get currency data for these users
    const userIds = users.map((u) => u.id);
    const currencies = await this.currencyRepository.find({
      where: userIds.map((id) => ({ userId: id })),
      select: ['userId', 'coins', 'currentStreak'],
    });

    const currencyMap = new Map(
      currencies.map((c) => [c.userId, c]),
    );

    // Build leaderboard entries
    const entries: LeaderboardEntry[] = users.map((user, index) => {
      const currency = currencyMap.get(user.id);
      return {
        rank: skip + index + 1,
        userId: user.id,
        fullName: user.fullName || 'Anonymous',
        email: user.email,
        totalXP: user.totalXP,
        coins: currency?.coins || 0,
        currentStreak: currency?.currentStreak || 0,
        avatar: user.avatarUrl || undefined,
      };
    });

    // Get user's rank if userId provided
    let userRank: number | undefined;
    if (userId) {
      const user = await this.usersRepository.findOne({
        where: { id: userId },
        select: ['id', 'totalXP', 'updatedAt'],
      });

      if (user) {
        const rank = await this.usersRepository
          .createQueryBuilder('user')
          .where(GLOBAL_STRICTLY_AHEAD_WHERE, bindGlobalStrictlyAhead(user))
          .getCount();
        userRank = rank + 1;
      }
    }

    // Get total users count
    const totalUsers = await this.usersRepository.count();

    return {
      entries,
      userRank,
      totalUsers,
      page,
      limit,
    };
  }

  async getWeeklyLeaderboard(
    limit: number = 100,
    page: number = 1,
    userId?: string,
  ): Promise<LeaderboardResponse> {
    const skip = (page - 1) * limit;
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);

    // Get users who were active in the last week
    // For weekly leaderboard, use totalXP as it's simpler and more accurate
    // In production, you might want to track weekly XP separately
    const users = await this.usersRepository
      .createQueryBuilder('user')
      .select([
        'user.id',
        'user.email',
        'user.fullName',
        'user.totalXP',
        'user.avatarUrl',
      ])
      .orderBy('user.totalXP', 'DESC')
      .addOrderBy('user.updatedAt', 'ASC')
      .addOrderBy('user.id', 'ASC')
      .skip(skip)
      .take(limit)
      .getMany();

    const userIds = users.map((u) => u.id);

    // Get currency data
    const currencies = await this.currencyRepository.find({
      where: userIds.map((id) => ({ userId: id })),
      select: ['userId', 'coins', 'currentStreak'],
    });

    const currencyMap = new Map(
      currencies.map((c) => [c.userId, c]),
    );

    // Build entries
    const entries: LeaderboardEntry[] = users.map((user, index) => {
      const currency = currencyMap.get(user.id);
      return {
        rank: skip + index + 1,
        userId: user.id,
        fullName: user.fullName || 'Anonymous',
        email: user.email,
        totalXP: user.totalXP,
        coins: currency?.coins || 0,
        currentStreak: currency?.currentStreak || 0,
        avatar: user.avatarUrl || undefined,
      };
    });

    // Get user's weekly rank
    let userRank: number | undefined;
    if (userId) {
      const userIndex = users.findIndex((u) => u.id === userId);
      if (userIndex >= 0) {
        userRank = skip + userIndex + 1;
      } else {
        // User not in top list, calculate rank
        const user = await this.usersRepository.findOne({
          where: { id: userId },
          select: ['id', 'totalXP', 'updatedAt'],
        });
        if (user) {
          const rank = await this.usersRepository
            .createQueryBuilder('user')
            .where(GLOBAL_STRICTLY_AHEAD_WHERE, bindGlobalStrictlyAhead(user))
            .getCount();
          userRank = rank + 1;
        }
      }
    }

    return {
      entries,
      userRank,
      totalUsers: await this.usersRepository.count(),
      page,
      limit,
    };
  }

  async getSubjectLeaderboard(
    subjectId: string,
    limit: number = 100,
    page: number = 1,
    userId?: string,
  ): Promise<LeaderboardResponse> {
    const skip = (page - 1) * limit;

    // Get users who completed nodes in this subject
    const subjectProgress = await this.progressRepository
      .createQueryBuilder('progress')
      .innerJoin('progress.node', 'node')
      .where('node.subjectId = :subjectId', { subjectId })
      .andWhere('progress.isCompleted = true')
      .select('progress.userId', 'userId')
      .addSelect('COUNT(progress.id)', 'completedNodes')
      .groupBy('progress.userId')
      .orderBy('completedNodes', 'DESC')
      .addOrderBy('progress.userId', 'ASC')
      .limit(limit)
      .offset(skip)
      .getRawMany();

    const userIds = subjectProgress.map((p) => p.userId);
    const users = await this.usersRepository.find({
      where: userIds.map((id) => ({ id })),
      select: ['id', 'email', 'fullName', 'totalXP', 'avatarUrl'],
    });

    const userMap = new Map(users.map((u) => [u.id, u]));

    const currencies = await this.currencyRepository.find({
      where: userIds.map((id) => ({ userId: id })),
      select: ['userId', 'coins', 'currentStreak'],
    });

    const currencyMap = new Map(
      currencies.map((c) => [c.userId, c]),
    );

    const entries: LeaderboardEntry[] = subjectProgress.map((p, index) => {
      const user = userMap.get(p.userId);
      const currency = currencyMap.get(p.userId);
      return {
        rank: skip + index + 1,
        userId: p.userId,
        fullName: user?.fullName || 'Anonymous',
        email: user?.email || '',
        totalXP: user?.totalXP || 0,
        coins: currency?.coins || 0,
        currentStreak: currency?.currentStreak || 0,
        avatar: user?.avatarUrl || undefined,
      };
    });

    let userRank: number | undefined;
    if (userId) {
      const userProgress = subjectProgress.find((p) => p.userId === userId);
      if (userProgress) {
        const rank = subjectProgress.findIndex((p) => p.userId === userId);
        userRank = rank >= 0 ? rank + 1 : undefined;
      }
    }

    return {
      entries,
      userRank,
      totalUsers: subjectProgress.length,
      page,
      limit,
    };
  }

  async getUserRank(userId: string): Promise<{
    globalRank: number;
    weeklyRank?: number;
    totalXP: number;
  }> {
    const user = await this.usersRepository.findOne({
      where: { id: userId },
      select: ['id', 'totalXP', 'updatedAt'],
    });

    if (!user) {
      throw new Error('User not found');
    }

    const usersWithMoreXP = await this.usersRepository
      .createQueryBuilder('user')
      .where(GLOBAL_STRICTLY_AHEAD_WHERE, bindGlobalStrictlyAhead(user))
      .getCount();

    const globalRank = usersWithMoreXP + 1;

    return {
      globalRank,
      totalXP: user.totalXP,
    };
  }
}

