import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThanOrEqual } from 'typeorm';
import { User } from '../users/entities/user.entity';
import { UserCurrency } from '../user-currency/entities/user-currency.entity';
import { UserProgress } from '../user-progress/entities/user-progress.entity';
import { Payment } from '../payment/entities/payment.entity';
import { RewardTransaction } from '../user-currency/entities/reward-transaction.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { Subject } from '../subjects/entities/subject.entity';
import { PendingContribution } from '../pending-contributions/entities/pending-contribution.entity';

@Injectable()
export class AnalyticsService {
  constructor(
    @InjectRepository(User)
    private userRepo: Repository<User>,
    @InjectRepository(UserCurrency)
    private currencyRepo: Repository<UserCurrency>,
    @InjectRepository(UserProgress)
    private progressRepo: Repository<UserProgress>,
    @InjectRepository(Payment)
    private paymentRepo: Repository<Payment>,
    @InjectRepository(RewardTransaction)
    private rewardRepo: Repository<RewardTransaction>,
    @InjectRepository(LearningNode)
    private nodeRepo: Repository<LearningNode>,
    @InjectRepository(Subject)
    private subjectRepo: Repository<Subject>,
    @InjectRepository(PendingContribution)
    private contributionRepo: Repository<PendingContribution>,
  ) {}

  async getOverview(period: string = '30d') {
    const days = this.parsePeriod(period);
    const since = new Date();
    since.setDate(since.getDate() - days);

    const [users, learning, revenue, engagement, content] = await Promise.all([
      this.getUserMetrics(since),
      this.getLearningMetrics(since),
      this.getRevenueMetrics(since),
      this.getEngagementMetrics(since),
      this.getContentMetrics(since),
    ]);

    return { period, days, users, learning, revenue, engagement, content };
  }

  private async getUserMetrics(since: Date) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [totalUsers, newUsersToday, newUsersPeriod, dauResult, mauResult] =
      await Promise.all([
        this.userRepo.count(),
        this.userRepo.count({ where: { createdAt: MoreThanOrEqual(today) } }),
        this.userRepo.count({ where: { createdAt: MoreThanOrEqual(since) } }),
        this.currencyRepo
          .createQueryBuilder('uc')
          .select('COUNT(*)', 'count')
          .where('uc."lastActiveDate" = CURRENT_DATE')
          .getRawOne(),
        this.currencyRepo
          .createQueryBuilder('uc')
          .select('COUNT(*)', 'count')
          .where(
            `uc."lastActiveDate" >= CURRENT_DATE - INTERVAL '30 days'`,
          )
          .getRawOne(),
      ]);

    const dau = parseInt(dauResult?.count || '0');
    const mau = parseInt(mauResult?.count || '0');
    const retentionRate =
      totalUsers > 0 ? Math.round((mau / totalUsers) * 100) : 0;

    const roleDistribution = await this.userRepo
      .createQueryBuilder('u')
      .select('u.role', 'role')
      .addSelect('COUNT(*)', 'count')
      .groupBy('u.role')
      .getRawMany();

    return {
      totalUsers,
      newUsersToday,
      newUsersPeriod,
      dau,
      mau,
      retentionRate,
      roleDistribution,
    };
  }

  private async getLearningMetrics(since: Date) {
    const [
      totalProgress,
      completedNodes,
      avgProgressResult,
      completionsBySubject,
    ] = await Promise.all([
      this.progressRepo.count(),
      this.progressRepo.count({ where: { isCompleted: true } }),
      this.progressRepo
        .createQueryBuilder('up')
        .select('AVG(up."progressPercentage")', 'avg')
        .getRawOne(),
      this.progressRepo
        .createQueryBuilder('up')
        .innerJoin('learning_nodes', 'ln', 'ln.id = up."nodeId"')
        .innerJoin('subjects', 's', 's.id = ln."subjectId"')
        .select('s.name', 'subject')
        .addSelect('COUNT(*) FILTER (WHERE up."isCompleted" = true)', 'completed')
        .addSelect('COUNT(*)', 'total')
        .groupBy('s.name')
        .getRawMany(),
    ]);

    const avgProgress = parseFloat(avgProgressResult?.avg || '0');
    const completionRate =
      totalProgress > 0
        ? Math.round((completedNodes / totalProgress) * 100)
        : 0;

    const recentCompletions = await this.progressRepo.count({
      where: {
        isCompleted: true,
        completedAt: MoreThanOrEqual(since),
      },
    });

    return {
      totalProgress,
      completedNodes,
      avgProgress: Math.round(avgProgress * 10) / 10,
      completionRate,
      recentCompletions,
      completionsBySubject,
    };
  }

  private async getRevenueMetrics(since: Date) {
    const [totalRevenueResult, paidCount, payingUsersResult, recentPayments] =
      await Promise.all([
        this.paymentRepo
          .createQueryBuilder('p')
          .select('COALESCE(SUM(p.amount), 0)', 'total')
          .addSelect('COALESCE(SUM(p."diamondAmount"), 0)', 'diamonds')
          .where('p.status = :status', { status: 'paid' })
          .getRawOne(),
        this.paymentRepo.count({ where: { status: 'paid' as any } }),
        this.paymentRepo
          .createQueryBuilder('p')
          .select('COUNT(DISTINCT p."userId")', 'count')
          .where('p.status = :status', { status: 'paid' })
          .getRawOne(),
        this.paymentRepo.count({
          where: {
            status: 'paid' as any,
            paidAt: MoreThanOrEqual(since),
          },
        }),
      ]);

    const totalRevenue = parseFloat(totalRevenueResult?.total || '0');
    const totalDiamondsSold = parseInt(totalRevenueResult?.diamonds || '0');
    const payingUsers = parseInt(payingUsersResult?.count || '0');
    const arpu = payingUsers > 0 ? Math.round(totalRevenue / payingUsers) : 0;

    const revenueByPackage = await this.paymentRepo
      .createQueryBuilder('p')
      .select('p."packageName"', 'package')
      .addSelect('COUNT(*)', 'count')
      .addSelect('COALESCE(SUM(p.amount), 0)', 'revenue')
      .where('p.status = :status', { status: 'paid' })
      .groupBy('p."packageName"')
      .getRawMany();

    return {
      totalRevenue,
      totalDiamondsSold,
      paidCount,
      payingUsers,
      arpu,
      recentPayments,
      revenueByPackage,
    };
  }

  private async getEngagementMetrics(since: Date) {
    const [avgStreakResult, streakDistribution, rewardsBySource] =
      await Promise.all([
        this.currencyRepo
          .createQueryBuilder('uc')
          .select('AVG(uc."currentStreak")', 'avg')
          .addSelect('MAX(uc."currentStreak")', 'max')
          .getRawOne(),
        this.currencyRepo
          .createQueryBuilder('uc')
          .select(
            `CASE
            WHEN uc."currentStreak" = 0 THEN '0 days'
            WHEN uc."currentStreak" BETWEEN 1 AND 3 THEN '1-3 days'
            WHEN uc."currentStreak" BETWEEN 4 AND 7 THEN '4-7 days'
            WHEN uc."currentStreak" BETWEEN 8 AND 14 THEN '8-14 days'
            ELSE '15+ days'
          END`,
            'range',
          )
          .addSelect('COUNT(*)', 'count')
          .groupBy(
            `CASE
            WHEN uc."currentStreak" = 0 THEN '0 days'
            WHEN uc."currentStreak" BETWEEN 1 AND 3 THEN '1-3 days'
            WHEN uc."currentStreak" BETWEEN 4 AND 7 THEN '4-7 days'
            WHEN uc."currentStreak" BETWEEN 8 AND 14 THEN '8-14 days'
            ELSE '15+ days'
          END`,
          )
          .getRawMany(),
        this.rewardRepo
          .createQueryBuilder('rt')
          .select('rt.source', 'source')
          .addSelect('COUNT(*)', 'count')
          .addSelect('COALESCE(SUM(rt.xp), 0)', 'totalXp')
          .addSelect('COALESCE(SUM(rt.coins), 0)', 'totalCoins')
          .where('rt."createdAt" >= :since', { since })
          .groupBy('rt.source')
          .getRawMany(),
      ]);

    const levelDistribution = await this.currencyRepo
      .createQueryBuilder('uc')
      .select(
        `CASE
        WHEN uc.level BETWEEN 1 AND 5 THEN 'Lv 1-5'
        WHEN uc.level BETWEEN 6 AND 10 THEN 'Lv 6-10'
        WHEN uc.level BETWEEN 11 AND 20 THEN 'Lv 11-20'
        WHEN uc.level BETWEEN 21 AND 35 THEN 'Lv 21-35'
        ELSE 'Lv 36+'
      END`,
        'range',
      )
      .addSelect('COUNT(*)', 'count')
      .groupBy(
        `CASE
        WHEN uc.level BETWEEN 1 AND 5 THEN 'Lv 1-5'
        WHEN uc.level BETWEEN 6 AND 10 THEN 'Lv 6-10'
        WHEN uc.level BETWEEN 11 AND 20 THEN 'Lv 11-20'
        WHEN uc.level BETWEEN 21 AND 35 THEN 'Lv 21-35'
        ELSE 'Lv 36+'
      END`,
      )
      .getRawMany();

    return {
      avgStreak: parseFloat(avgStreakResult?.avg || '0'),
      maxStreak: parseInt(avgStreakResult?.max || '0'),
      streakDistribution,
      levelDistribution,
      rewardsBySource,
    };
  }

  private async getContentMetrics(since: Date) {
    const [
      totalNodes,
      nodesBySubject,
      contributionStats,
      recentContributions,
    ] = await Promise.all([
      this.nodeRepo.count(),
      this.nodeRepo
        .createQueryBuilder('ln')
        .innerJoin('subjects', 's', 's.id = ln."subjectId"')
        .select('s.name', 'subject')
        .addSelect('COUNT(*)', 'lessons')
        .groupBy('s.name')
        .orderBy('COUNT(*)', 'DESC')
        .getRawMany(),
      this.contributionRepo
        .createQueryBuilder('pc')
        .select('pc.status', 'status')
        .addSelect('COUNT(*)', 'count')
        .groupBy('pc.status')
        .getRawMany(),
      this.contributionRepo.count({
        where: { createdAt: MoreThanOrEqual(since) },
      }),
    ]);

    const topContributors = await this.contributionRepo
      .createQueryBuilder('pc')
      .innerJoin('users', 'u', 'u.id = pc."contributorId"')
      .select('u."fullName"', 'name')
      .addSelect('u.email', 'email')
      .addSelect('COUNT(*)', 'contributions')
      .addSelect(
        `COUNT(*) FILTER (WHERE pc.status = 'approved')`,
        'approved',
      )
      .groupBy('u."fullName"')
      .addGroupBy('u.email')
      .orderBy('COUNT(*)', 'DESC')
      .limit(10)
      .getRawMany();

    const totalSubjects = await this.subjectRepo.count();

    return {
      totalSubjects,
      totalNodes,
      nodesBySubject,
      contributionStats,
      recentContributions,
      topContributors,
    };
  }

  private parsePeriod(period: string): number {
    const match = period.match(/^(\d+)d$/);
    if (match) return parseInt(match[1]);
    if (period === '7d') return 7;
    if (period === '90d') return 90;
    return 30;
  }
}
