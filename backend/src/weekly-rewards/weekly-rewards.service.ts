import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { UserBadge } from './entities/user-badge.entity';
import { WeeklyRewardHistory } from './entities/weekly-reward-history.entity';
import { UserCurrency } from '../user-currency/entities/user-currency.entity';
import { User } from '../users/entities/user.entity';

export interface RewardTier {
  maxRank: number;
  diamonds: number;
  badgeCode?: string;
  badgeName?: string;
}

const REWARD_TIERS: RewardTier[] = [
  { maxRank: 1, diamonds: 500, badgeCode: 'top_1_week', badgeName: 'Top 1 tuần' },
  { maxRank: 2, diamonds: 300, badgeCode: 'top_2_week', badgeName: 'Top 2 tuần' },
  { maxRank: 3, diamonds: 200, badgeCode: 'top_3_week', badgeName: 'Top 3 tuần' },
  { maxRank: 10, diamonds: 100 },
  { maxRank: 50, diamonds: 50 },
];

function getISOWeekCode(date: Date): string {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  const weekNum = Math.ceil(((d.getTime() - yearStart.getTime()) / 86400000 + 1) / 7);
  return `${d.getUTCFullYear()}-W${String(weekNum).padStart(2, '0')}`;
}

function getCurrentWeekBounds(): { start: Date; end: Date } {
  const now = new Date();
  const day = now.getDay();
  const diff = day === 0 ? -6 : 1 - day; // Monday
  const start = new Date(now);
  start.setDate(now.getDate() + diff);
  start.setHours(0, 0, 0, 0);
  const end = new Date(start);
  end.setDate(start.getDate() + 6);
  end.setHours(23, 59, 59, 999);
  return { start, end };
}

function getLastWeekCode(): string {
  const lastWeek = new Date();
  lastWeek.setDate(lastWeek.getDate() - 7);
  return getISOWeekCode(lastWeek);
}

@Injectable()
export class WeeklyRewardsService {
  private readonly logger = new Logger(WeeklyRewardsService.name);

  constructor(
    @InjectRepository(UserBadge)
    private badgeRepo: Repository<UserBadge>,
    @InjectRepository(WeeklyRewardHistory)
    private historyRepo: Repository<WeeklyRewardHistory>,
    @InjectRepository(UserCurrency)
    private currencyRepo: Repository<UserCurrency>,
    @InjectRepository(User)
    private userRepo: Repository<User>,
    private dataSource: DataSource,
  ) {}

  // ─── Cron: Every Monday at 00:05 ───
  @Cron('0 5 0 * * 1')
  async handleWeeklyCron() {
    this.logger.log('⏰ Weekly rewards cron started');
    try {
      await this.distributeWeeklyRewards();
      this.logger.log('✅ Weekly rewards distributed');
    } catch (err) {
      this.logger.error('❌ Weekly rewards cron failed', err);
    }
  }

  async distributeWeeklyRewards(weekCodeOverride?: string): Promise<{
    weekCode: string;
    rewarded: number;
  }> {
    const weekCode = weekCodeOverride || getLastWeekCode();

    const existing = await this.historyRepo.findOne({ where: { weekCode } });
    if (existing) {
      this.logger.warn(`Rewards already distributed for ${weekCode}`);
      return { weekCode, rewarded: 0 };
    }

    const rankings = await this.currencyRepo
      .createQueryBuilder('c')
      .innerJoin(User, 'u', 'u.id = c."userId"')
      .where('c."weeklyXp" > 0')
      .orderBy('c."weeklyXp"', 'DESC')
      .select([
        'c."userId" AS "userId"',
        'c."weeklyXp" AS "weeklyXp"',
        'u."fullName" AS "fullName"',
      ])
      .limit(50)
      .getRawMany();

    if (rankings.length === 0) {
      this.logger.log('No active users this week, skipping');
      await this.resetWeeklyXp();
      return { weekCode, rewarded: 0 };
    }

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      let rewarded = 0;

      for (let i = 0; i < rankings.length; i++) {
        const rank = i + 1;
        const { userId, weeklyXp } = rankings[i];
        const tier = REWARD_TIERS.find((t) => rank <= t.maxRank);
        if (!tier) continue;

        await queryRunner.manager
          .createQueryBuilder()
          .update(UserCurrency)
          .set({ diamonds: () => `diamonds + ${tier.diamonds}` })
          .where('"userId" = :userId', { userId })
          .execute();

        if (tier.badgeCode && tier.badgeName) {
          const badge = queryRunner.manager.create(UserBadge, {
            userId,
            code: tier.badgeCode,
            name: tier.badgeName,
            iconUrl: this.getBadgeIcon(rank),
            metadata: { week: weekCode, rank, xp: weeklyXp },
          });
          await queryRunner.manager.save(badge);
        }

        const history = queryRunner.manager.create(WeeklyRewardHistory, {
          userId,
          weekCode,
          rank,
          weeklyXp: Number(weeklyXp),
          diamondsAwarded: tier.diamonds,
          badgeCode: tier.badgeCode || null,
        });
        await queryRunner.manager.save(history);
        rewarded++;
      }

      await queryRunner.commitTransaction();
      this.logger.log(`Distributed rewards to ${rewarded} users for ${weekCode}`);

      await this.resetWeeklyXp();

      return { weekCode, rewarded };
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  private async resetWeeklyXp(): Promise<void> {
    await this.currencyRepo
      .createQueryBuilder()
      .update(UserCurrency)
      .set({ weeklyXp: 0 })
      .execute();
    this.logger.log('Weekly XP reset to 0 for all users');
  }

  private getBadgeIcon(rank: number): string {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '🏅';
    }
  }

  // ─── APIs ───

  async getWeeklyRankings(limit = 50, userId?: string) {
    const rankings = await this.currencyRepo
      .createQueryBuilder('c')
      .innerJoin(User, 'u', 'u.id = c."userId"')
      .where('c."weeklyXp" > 0')
      .orderBy('c."weeklyXp"', 'DESC')
      .select([
        'c."userId" AS "userId"',
        'c."weeklyXp" AS "weeklyXp"',
        'u."fullName" AS "fullName"',
      ])
      .limit(limit)
      .getRawMany();

    const entries = rankings.map((r, i) => ({
      rank: i + 1,
      userId: r.userId,
      fullName: r.fullName || 'Anonymous',
      weeklyXp: Number(r.weeklyXp),
    }));

    let myRank: number | null = null;
    let myXp = 0;
    if (userId) {
      const idx = entries.findIndex((e) => e.userId === userId);
      if (idx >= 0) {
        myRank = idx + 1;
        myXp = entries[idx].weeklyXp;
      } else {
        const mine = await this.currencyRepo.findOne({ where: { userId } });
        if (mine && mine.weeklyXp > 0) {
          const ahead = await this.currencyRepo
            .createQueryBuilder('c')
            .where('c."weeklyXp" > :xp', { xp: mine.weeklyXp })
            .getCount();
          myRank = ahead + 1;
          myXp = mine.weeklyXp;
        }
      }
    }

    const { start, end } = getCurrentWeekBounds();

    return {
      weekCode: getISOWeekCode(new Date()),
      weekStart: start.toISOString(),
      weekEnd: end.toISOString(),
      rewardTiers: REWARD_TIERS,
      entries,
      myRank,
      myXp,
    };
  }

  async getRewardHistory(userId: string, limit = 20, offset = 0) {
    const [items, total] = await this.historyRepo.findAndCount({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: limit,
      skip: offset,
    });

    const stats = await this.historyRepo
      .createQueryBuilder('h')
      .where('h."userId" = :userId', { userId })
      .select([
        'COALESCE(SUM(h."diamondsAwarded"), 0) AS "totalDiamonds"',
        'COUNT(h.id) AS "totalWeeks"',
        'COALESCE(MIN(h.rank), 0) AS "bestRank"',
        `COUNT(CASE WHEN h.rank <= 3 THEN 1 END) AS "topThreeCount"`,
      ])
      .getRawOne();

    return {
      items,
      total,
      stats: {
        totalDiamonds: Number(stats?.totalDiamonds || 0),
        totalWeeks: Number(stats?.totalWeeks || 0),
        bestRank: Number(stats?.bestRank || 0),
        topThreeCount: Number(stats?.topThreeCount || 0),
      },
    };
  }

  async getUserBadges(userId: string) {
    const badges = await this.badgeRepo.find({
      where: { userId },
      order: { awardedAt: 'DESC' },
    });

    const grouped: Record<string, { badge: UserBadge; count: number }> = {};
    for (const b of badges) {
      if (!grouped[b.code]) {
        grouped[b.code] = { badge: b, count: 1 };
      } else {
        grouped[b.code].count++;
      }
    }

    return {
      badges,
      collection: Object.values(grouped).map((g) => ({
        code: g.badge.code,
        name: g.badge.name,
        iconUrl: g.badge.iconUrl,
        count: g.count,
        lastAwarded: g.badge.awardedAt,
      })),
    };
  }

  async getUnnotifiedRewards(userId: string) {
    const rewards = await this.historyRepo.find({
      where: { userId, notified: false },
      order: { createdAt: 'DESC' },
    });

    if (rewards.length > 0) {
      await this.historyRepo.update(
        rewards.map((r) => r.id),
        { notified: true },
      );
    }

    return rewards;
  }
}
