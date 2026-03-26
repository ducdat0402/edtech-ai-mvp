import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { MoreThanOrEqual, Repository } from 'typeorm';
import { UserWeeklyPlan } from './entities/user-weekly-plan.entity';
import { SelfLeadershipCheckin } from './entities/self-leadership-checkin.entity';
import { UserProgress } from '../user-progress/entities/user-progress.entity';

@Injectable()
export class SelfLeadershipService {
  constructor(
    @InjectRepository(UserWeeklyPlan)
    private readonly weeklyPlanRepo: Repository<UserWeeklyPlan>,
    @InjectRepository(SelfLeadershipCheckin)
    private readonly checkinRepo: Repository<SelfLeadershipCheckin>,
    @InjectRepository(UserProgress)
    private readonly progressRepo: Repository<UserProgress>,
  ) {}

  private getWeekStart(date = new Date()): string {
    const d = new Date(date);
    const day = d.getDay();
    const diff = day === 0 ? -6 : 1 - day;
    d.setDate(d.getDate() + diff);
    d.setHours(0, 0, 0, 0);
    return d.toISOString().slice(0, 10);
  }

  private normalizePlannedDays(raw: unknown): number[] {
    if (!Array.isArray(raw)) return [1, 3, 5];
    const uniq = [...new Set(raw.map((x) => Number(x)).filter((x) => Number.isInteger(x) && x >= 0 && x <= 6))];
    return uniq.length ? uniq.sort((a, b) => a - b) : [1, 3, 5];
  }

  async upsertWeeklyPlan(params: {
    userId: string;
    targetSessions?: number;
    targetLessons?: number;
    plannedDays?: number[];
  }) {
    const weekStart = this.getWeekStart();
    const targetSessions = Math.max(1, Math.min(14, Math.round(params.targetSessions ?? 3)));
    const targetLessons = Math.max(1, Math.min(30, Math.round(params.targetLessons ?? targetSessions)));
    const plannedDays = this.normalizePlannedDays(params.plannedDays);

    let plan = await this.weeklyPlanRepo.findOne({
      where: { userId: params.userId, weekStart },
    });
    if (!plan) {
      plan = this.weeklyPlanRepo.create({
        userId: params.userId,
        weekStart,
        targetSessions,
        targetLessons,
        plannedDays,
        status: 'active',
      });
    } else {
      plan.targetSessions = targetSessions;
      plan.targetLessons = targetLessons;
      plan.plannedDays = plannedDays;
      plan.status = 'active';
    }
    const saved = await this.weeklyPlanRepo.save(plan);
    return {
      id: saved.id,
      weekStart: saved.weekStart,
      targetSessions: saved.targetSessions,
      targetLessons: saved.targetLessons,
      plannedDays: saved.plannedDays,
      status: saved.status,
    };
  }

  async getCurrentWeeklyPlan(userId: string) {
    const weekStart = this.getWeekStart();
    return this.weeklyPlanRepo.findOne({ where: { userId, weekStart } });
  }

  async submitCheckin(params: {
    userId: string;
    nodeId?: string;
    lessonType?: string;
    followedPlan: boolean;
    deviationReason?: string;
    nextAction?: string;
  }) {
    if (!params.followedPlan && !params.nextAction?.trim()) {
      throw new BadRequestException('nextAction is required when followedPlan is false');
    }
    const weekStart = this.getWeekStart();
    const row = this.checkinRepo.create({
      userId: params.userId,
      nodeId: params.nodeId ?? null,
      lessonType: params.lessonType ?? null,
      weekStart,
      followedPlan: !!params.followedPlan,
      deviationReason: params.deviationReason?.trim() || null,
      nextAction: params.nextAction?.trim() || null,
    });
    const saved = await this.checkinRepo.save(row);
    return {
      id: saved.id,
      weekStart: saved.weekStart,
      followedPlan: saved.followedPlan,
      deviationReason: saved.deviationReason,
      nextAction: saved.nextAction,
      createdAt: saved.createdAt,
    };
  }

  async getCurrentWeeklyReview(userId: string) {
    const weekStart = this.getWeekStart();
    const weekStartDate = new Date(`${weekStart}T00:00:00.000Z`);
    const now = new Date();

    const [plan, completed, checkins] = await Promise.all([
      this.weeklyPlanRepo.findOne({ where: { userId, weekStart } }),
      this.progressRepo.find({
        where: {
          userId,
          isCompleted: true,
          completedAt: MoreThanOrEqual(weekStartDate),
        },
        select: ['completedAt', 'nodeId'],
        take: 5000,
      }),
      this.checkinRepo.find({
        where: { userId, weekStart },
        order: { createdAt: 'ASC' },
        take: 5000,
      }),
    ]);

    const completedInWeek = completed.filter((x) => (x.completedAt?.getTime() ?? 0) <= now.getTime());
    const sessionCount = completedInWeek.length;
    const lessonCount = new Set(completedInWeek.map((x) => x.nodeId)).size;
    const checkedCount = checkins.length;
    const followedCount = checkins.filter((x) => x.followedPlan).length;

    return {
      weekStart,
      plan: plan
        ? {
            targetSessions: plan.targetSessions,
            targetLessons: plan.targetLessons,
            plannedDays: plan.plannedDays,
          }
        : null,
      actual: {
        sessionCount,
        lessonCount,
        checkinCount: checkedCount,
        followedPlanCount: followedCount,
      },
      followRate: checkedCount ? Math.round((followedCount / checkedCount) * 100) : 0,
      note: plan
        ? 'Giữ nhịp bám kế hoạch và cập nhật check-in sau mỗi phiên học.'
        : 'Bạn chưa đặt cam kết tuần. Hãy tạo kế hoạch để bắt đầu đo Lãnh đạo bản thân.',
    };
  }
}

