import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { MoreThanOrEqual, Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { UserCurrency } from '../user-currency/entities/user-currency.entity';
import { UserProgress } from '../user-progress/entities/user-progress.entity';
import { LearningQuizAttempt } from '../learning-nodes/entities/learning-quiz-attempt.entity';
import * as bcrypt from 'bcrypt';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    @InjectRepository(UserCurrency)
    private currencyRepository: Repository<UserCurrency>,
    @InjectRepository(UserProgress)
    private progressRepository: Repository<UserProgress>,
    @InjectRepository(LearningQuizAttempt)
    private quizAttemptRepository: Repository<LearningQuizAttempt>,
  ) {}

  /**
   * Snapshot năng lực (MVP): chỉ số "memory" = Memory v2.
   * - Hành vi học (v1): completedNodes, streak, 7 ngày — giữ làm nền khi chưa có quiz.
   * - Recall (v2): từ lịch sử nộp end-quiz — delayed recall 3–14 ngày, stability ≥7 ngày, lần làm đầu.
   */
  async getCompetencies(userId: string) {
    const memorySince = new Date(Date.now() - 120 * 24 * 60 * 60 * 1000);
    const logicalSince = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    const [
      currency,
      completedNodes,
      completedLast7Days,
      completedLast30,
      quizAttempts,
    ] =
      await Promise.all([
        this.currencyRepository.findOne({
          where: { userId },
          select: ['currentStreak'],
        }),
        this.progressRepository.count({
          where: { userId, isCompleted: true },
        }),
        this.progressRepository.count({
          where: {
            userId,
            isCompleted: true,
            completedAt: MoreThanOrEqual(
              new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
            ),
          },
        }),
        this.progressRepository.find({
          where: {
            userId,
            isCompleted: true,
            completedAt: MoreThanOrEqual(logicalSince),
          },
          select: ['completedAt'],
          take: 5000,
        }),
        this.quizAttemptRepository.find({
          where: {
            userId,
            createdAt: MoreThanOrEqual(memorySince),
          },
          order: { createdAt: 'ASC' },
          take: 5000,
        }),
      ]);

    const streak = currency?.currentStreak ?? 0;
    const completedNorm = Math.min(1, completedNodes / 80);
    const streakNorm = Math.min(1, streak / 14);
    const weeklyNorm = Math.min(1, completedLast7Days / 12);

    const behavioralScore = Math.round(
      (completedNorm * 0.55 + streakNorm * 0.3 + weeklyNorm * 0.15) * 100,
    );

    const recall = this.computeMemoryRecallMetrics(quizAttempts);
    const hasQuizSignal = quizAttempts.length > 0;
    const memoryScore = hasQuizSignal
      ? Math.round(behavioralScore * 0.15 + recall.recallScore * 0.85)
      : behavioralScore;
    const logical = this.computeLogicalThinkingMetrics(quizAttempts, logicalSince);
    const practical = this.computePracticalApplicationMetrics(
      quizAttempts,
      logicalSince,
    );
    const processing = this.computeProcessingSpeedMetrics(quizAttempts, logicalSince);
    const metacognition = this.computeMetacognitionMetrics(
      quizAttempts,
      logicalSince,
    );
    const persistence = this.computeLearningPersistenceMetrics(
      completedLast30.map((x) => x.completedAt).filter((x): x is Date => !!x),
      streak,
    );
    const knowledge = this.computeKnowledgeAbsorptionMetrics(
      quizAttempts,
      logicalSince,
    );

    return {
      learningMetrics: [
        { key: 'memory', value: memoryScore },
        { key: 'logical_thinking', value: logical.score },
        { key: 'processing_speed', value: processing.score },
        { key: 'practical_application', value: practical.score },
        { key: 'metacognition', value: metacognition.score },
        { key: 'learning_persistence', value: persistence.score },
        { key: 'knowledge_absorption', value: knowledge.score },
      ],
      humanMetrics: [
        { key: 'systems_thinking', value: 0 },
        { key: 'creativity', value: 0 },
        { key: 'communication', value: 0 },
        { key: 'self_leadership', value: 0 },
        { key: 'discipline', value: 0 },
        { key: 'growth_mindset', value: 0 },
        { key: 'critical_thinking', value: 0 },
        { key: 'collaboration', value: 0 },
      ],
      formulaInfo: {
        memory: {
          version: 2,
          completedNodes,
          currentStreak: streak,
          completedLast7Days,
          behavioralScore,
          quizAttemptCount: quizAttempts.length,
          delayedRecallSampleCount: recall.delayedRecallSampleCount,
          delayedRecallAvgScore: recall.delayedRecallAvgScore,
          stabilitySampleCount: recall.stabilitySampleCount,
          stabilityAvgRatio: recall.stabilityAvgRatio,
          firstTryCount: recall.firstTryCount,
          firstTryPassRate: recall.firstTryPassRate,
          recallScore: recall.recallScore,
          blendBehaviorWeight: hasQuizSignal ? 0.15 : 1,
          blendRecallWeight: hasQuizSignal ? 0.85 : 0,
        },
        logicalThinking: {
          version: 1,
          windowDays: 30,
          attemptCount: logical.attemptCount,
          weightedTotal: logical.weightedTotal,
          weightedCorrect: logical.weightedCorrect,
          score: logical.score,
        },
        processingSpeed: {
          version: 1,
          windowDays: 30,
          fastSec: processing.fastSec,
          slowSec: processing.slowSec,
          minSamples: processing.minSamples,
          validSamples: processing.validSamples,
          correctCount: processing.correctCount,
          accuracy: processing.accuracy,
          medianTimeSec: processing.medianTimeSec,
          timeNorm: processing.timeNorm,
          provisional: processing.provisional,
          score: processing.score,
        },
        practicalApplication: {
          version: 1,
          windowDays: 30,
          minWeightedTotal: 8,
          attemptCount: practical.attemptCount,
          weightedTotal: practical.weightedTotal,
          weightedCorrect: practical.weightedCorrect,
          accuracy: practical.accuracy,
          provisional: practical.provisional,
          score: practical.score,
        },
        metacognition: {
          version: 1,
          windowDays: 30,
          minSamples: metacognition.minSamples,
          validSamples: metacognition.validSamples,
          provisional: metacognition.provisional,
          avgConfidence: metacognition.avgConfidence,
          avgAccuracy: metacognition.avgAccuracy,
          avgAbsError: metacognition.avgAbsError,
          score: metacognition.score,
        },
        learningPersistence: {
          version: 1,
          windowDays: 30,
          activeDays: persistence.activeDays,
          weeklyConsistency: persistence.weeklyConsistency,
          currentStreak: streak,
          streakNorm: persistence.streakNorm,
          activeDayNorm: persistence.activeDayNorm,
          consistencyNorm: persistence.consistencyNorm,
          score: persistence.score,
        },
        knowledgeAbsorption: {
          version: 1,
          windowDays: 30,
          groupCount: knowledge.groupCount,
          gainGroupCount: knowledge.gainGroupCount,
          avgGain: knowledge.avgGain,
          mastery: knowledge.mastery,
          provisional: knowledge.provisional,
          score: knowledge.score,
        },
      },
    };
  }

  private computeKnowledgeAbsorptionMetrics(
    attempts: LearningQuizAttempt[],
    since: Date,
  ): {
    score: number;
    groupCount: number;
    gainGroupCount: number;
    avgGain: number;
    mastery: number;
    provisional: boolean;
  } {
    const filtered = attempts.filter((a) => a.createdAt >= since);
    const groups = new Map<string, LearningQuizAttempt[]>();
    for (const a of filtered) {
      const key = `${a.nodeId}\u0000${a.lessonType ?? ''}`;
      if (!groups.has(key)) groups.set(key, []);
      groups.get(key)!.push(a);
    }

    let sumMastery = 0;
    let masteryCount = 0;
    let sumGain = 0;
    let gainCount = 0;

    for (const arr of groups.values()) {
      const sorted = [...arr].sort(
        (x, y) => x.createdAt.getTime() - y.createdAt.getTime(),
      );
      if (sorted.length === 0) continue;
      const first = sorted[0].score;
      const best = sorted.reduce((m, x) => Math.max(m, x.score), 0);
      sumMastery += best;
      masteryCount++;
      if (sorted.length >= 2) {
        sumGain += Math.max(0, best - first);
        gainCount++;
      }
    }

    const mastery = masteryCount ? sumMastery / masteryCount : 0;
    const avgGain = gainCount ? sumGain / gainCount : 0;
    const provisional = gainCount < 2;
    const score = provisional
      ? Math.round(mastery * 0.7)
      : Math.round(avgGain * 0.6 + mastery * 0.4);

    return {
      score: Math.max(0, Math.min(100, score)),
      groupCount: masteryCount,
      gainGroupCount: gainCount,
      avgGain: Math.round(avgGain * 10) / 10,
      mastery: Math.round(mastery * 10) / 10,
      provisional,
    };
  }

  private computeLearningPersistenceMetrics(
    completedDates: Date[],
    currentStreak: number,
  ): {
    score: number;
    activeDays: number;
    weeklyConsistency: number;
    streakNorm: number;
    activeDayNorm: number;
    consistencyNorm: number;
  } {
    const now = Date.now();
    const dayKeys = new Set<string>();
    const weekBuckets = new Map<number, Set<string>>();

    for (const d of completedDates) {
      const t = d.getTime();
      const daysAgo = Math.floor((now - t) / (24 * 60 * 60 * 1000));
      if (daysAgo < 0 || daysAgo >= 30) continue;

      const dayKey = d.toISOString().slice(0, 10);
      dayKeys.add(dayKey);

      const weekIndex = Math.min(3, Math.floor(daysAgo / 7));
      if (!weekBuckets.has(weekIndex)) weekBuckets.set(weekIndex, new Set());
      weekBuckets.get(weekIndex)!.add(dayKey);
    }

    const activeDays = dayKeys.size;
    let weeklyConsistency = 0;
    for (let i = 0; i < 4; i++) {
      const n = weekBuckets.get(i)?.size ?? 0;
      if (n >= 3) weeklyConsistency++;
    }

    const streakNorm = Math.min(1, currentStreak / 14);
    const activeDayNorm = Math.min(1, activeDays / 20);
    const consistencyNorm = weeklyConsistency / 4;

    const score = Math.round(
      (streakNorm * 0.35 + activeDayNorm * 0.4 + consistencyNorm * 0.25) * 100,
    );

    return {
      score,
      activeDays,
      weeklyConsistency,
      streakNorm: Math.round(streakNorm * 1000) / 1000,
      activeDayNorm: Math.round(activeDayNorm * 1000) / 1000,
      consistencyNorm: Math.round(consistencyNorm * 1000) / 1000,
    };
  }

  private computePracticalApplicationMetrics(
    attempts: LearningQuizAttempt[],
    since: Date,
  ): {
    score: number;
    attemptCount: number;
    weightedTotal: number;
    weightedCorrect: number;
    accuracy: number;
    minWeightedTotal: number;
    provisional: boolean;
  } {
    const minWeightedTotal = 8.0;
    const filtered = attempts.filter((a) => a.createdAt >= since);

    let weightedTotal = 0;
    let weightedCorrect = 0;

    for (const a of filtered) {
      const rows = Array.isArray(a.questionResults) ? a.questionResults : [];
      for (const row of rows) {
        const mix =
          row && typeof row === 'object' && !Array.isArray(row)
            ? (row as any).competencyMix
            : null;
        const weightRaw = mix?.practical_application;
        const weight =
          typeof weightRaw === 'number' && Number.isFinite(weightRaw)
            ? Math.max(0, weightRaw)
            : 0;
        if (weight <= 0) continue;
        weightedTotal += weight;
        if (row.isCorrect) weightedCorrect += weight;
      }
    }

    const accuracy = weightedTotal > 0 ? weightedCorrect / weightedTotal : 0;
    const provisional = weightedTotal < minWeightedTotal;
    const score = provisional ? 0 : Math.round(accuracy * 100);

    return {
      score,
      attemptCount: filtered.length,
      weightedTotal: Math.round(weightedTotal * 1000) / 1000,
      weightedCorrect: Math.round(weightedCorrect * 1000) / 1000,
      accuracy: Math.round(accuracy * 1000) / 1000,
      minWeightedTotal,
      provisional,
    };
  }

  private computeMetacognitionMetrics(
    attempts: LearningQuizAttempt[],
    since: Date,
  ): {
    score: number;
    windowDays: number;
    minSamples: number;
    validSamples: number;
    provisional: boolean;
    avgConfidence: number;
    avgAccuracy: number;
    avgAbsError: number;
  } {
    const windowDays = 30;
    const minSamples = 20;
    const filtered = attempts.filter((a) => a.createdAt >= since);

    let validSamples = 0;
    let sumScores = 0;
    let sumConfidence = 0;
    let sumAccuracy = 0;
    let sumAbsError = 0;

    for (const a of filtered) {
      if (a.confidencePercent === null || a.confidencePercent === undefined) {
        continue;
      }
      const total = a.totalQuestions ?? 0;
      if (!total || total <= 0) continue;

      const conf = Math.min(100, Math.max(0, a.confidencePercent));
      const accuracyPct = (a.correctCount / total) * 100;
      const absError = Math.abs(conf - accuracyPct);

      const attemptScore = Math.round(
        Math.min(100, Math.max(0, 100 - absError)),
      );

      validSamples++;
      sumScores += attemptScore;
      sumConfidence += conf;
      sumAccuracy += accuracyPct;
      sumAbsError += absError;
    }

    const provisional = validSamples < minSamples;
    const avgScore = validSamples ? sumScores / validSamples : 0;

    return {
      score: provisional ? 0 : Math.round(avgScore),
      windowDays,
      minSamples,
      validSamples,
      provisional,
      avgConfidence: validSamples
        ? Math.round((sumConfidence / validSamples) * 10) / 10
        : 0,
      avgAccuracy: validSamples
        ? Math.round((sumAccuracy / validSamples) * 10) / 10
        : 0,
      avgAbsError: validSamples
        ? Math.round((sumAbsError / validSamples) * 10) / 10
        : 0,
    };
  }

  private computeProcessingSpeedMetrics(
    attempts: LearningQuizAttempt[],
    since: Date,
  ): {
    score: number;
    windowDays: number;
    fastSec: number;
    slowSec: number;
    minSamples: number;
    validSamples: number;
    correctCount: number;
    accuracy: number;
    medianTimeSec: number;
    timeNorm: number;
    provisional: boolean;
  } {
    const fastSec = 6;
    const slowSec = 20;
    const minSamples = 20;
    const minValidMs = 400;
    const filtered = attempts.filter((a) => a.createdAt >= since);

    const timesMs: number[] = [];
    let correctCount = 0;
    for (const a of filtered) {
      const rows = Array.isArray(a.questionResults) ? a.questionResults : [];
      for (const row of rows) {
        const raw = row.responseTimeMs;
        if (typeof raw !== 'number' || !Number.isFinite(raw)) continue;
        const ms = Math.min(120000, Math.max(0, Math.round(raw)));
        if (ms < minValidMs) continue;
        timesMs.push(ms);
        if (row.isCorrect) correctCount++;
      }
    }

    const validSamples = timesMs.length;
    const accuracy = validSamples > 0 ? correctCount / validSamples : 0;
    const medianTimeSec =
      validSamples > 0 ? this.median(timesMs) / 1000 : 0;
    const rawTimeNorm = (slowSec - medianTimeSec) / (slowSec - fastSec);
    const timeNorm = Math.min(1, Math.max(0, rawTimeNorm));
    const provisional = validSamples < minSamples;
    const score = provisional
      ? 0
      : Math.round((accuracy * 0.65 + timeNorm * 0.35) * 100);

    return {
      score,
      windowDays: 30,
      fastSec,
      slowSec,
      minSamples,
      validSamples,
      correctCount,
      accuracy: Math.round(accuracy * 1000) / 1000,
      medianTimeSec: Math.round(medianTimeSec * 100) / 100,
      timeNorm: Math.round(timeNorm * 1000) / 1000,
      provisional,
    };
  }

  private median(values: number[]): number {
    if (values.length === 0) return 0;
    const sorted = [...values].sort((a, b) => a - b);
    const mid = Math.floor(sorted.length / 2);
    if (sorted.length % 2 === 0) {
      return (sorted[mid - 1] + sorted[mid]) / 2;
    }
    return sorted[mid];
  }

  private computeLogicalThinkingMetrics(
    attempts: LearningQuizAttempt[],
    since: Date,
  ): {
    score: number;
    attemptCount: number;
    weightedTotal: number;
    weightedCorrect: number;
  } {
    const filtered = attempts.filter((a) => a.createdAt >= since);
    let weightedTotal = 0;
    let weightedCorrect = 0;

    for (const a of filtered) {
      const rows = Array.isArray(a.questionResults) ? a.questionResults : [];
      for (const row of rows) {
        const weight = Math.max(0, row.logicalWeight ?? 0);
        if (weight <= 0) continue;
        weightedTotal += weight;
        if (row.isCorrect) weightedCorrect += weight;
      }
    }

    const score =
      weightedTotal > 0 ? Math.round((weightedCorrect / weightedTotal) * 100) : 0;

    return {
      score,
      attemptCount: filtered.length,
      weightedTotal: Math.round(weightedTotal * 1000) / 1000,
      weightedCorrect: Math.round(weightedCorrect * 1000) / 1000,
    };
  }

  /**
   * Gom theo (nodeId + lessonType), tính proxy recall / retention từ các lần nộp quiz.
   */
  private computeMemoryRecallMetrics(attempts: LearningQuizAttempt[]): {
    recallScore: number;
    delayedRecallSampleCount: number;
    delayedRecallAvgScore: number;
    stabilitySampleCount: number;
    stabilityAvgRatio: number;
    firstTryCount: number;
    firstTryPassRate: number;
  } {
    const MS_PER_DAY = 24 * 60 * 60 * 1000;
    const groups = new Map<string, LearningQuizAttempt[]>();
    for (const a of attempts) {
      const k = `${a.nodeId}\u0000${a.lessonType ?? ''}`;
      if (!groups.has(k)) groups.set(k, []);
      groups.get(k)!.push(a);
    }

    const delayedScores: number[] = [];
    const stabilityRatios: number[] = [];
    const firstPassed: number[] = [];

    for (const list of groups.values()) {
      const sorted = [...list].sort(
        (x, y) => x.createdAt.getTime() - y.createdAt.getTime(),
      );
      if (sorted.length === 0) continue;
      firstPassed.push(sorted[0].passed ? 1 : 0);

      for (let i = 1; i < sorted.length; i++) {
        const prev = sorted[i - 1];
        const cur = sorted[i];
        const days =
          (cur.createdAt.getTime() - prev.createdAt.getTime()) / MS_PER_DAY;
        if (days >= 3 && days <= 14) {
          delayedScores.push(cur.score);
        }
        if (days >= 7) {
          if (prev.score > 0) {
            stabilityRatios.push(Math.min(1, cur.score / prev.score));
          } else {
            stabilityRatios.push(cur.score / 100);
          }
        }
      }
    }

    const mean = (xs: number[]) =>
      xs.length ? xs.reduce((s, x) => s + x, 0) / xs.length : 0;

    const delayedRecallSampleCount = delayedScores.length;
    const delayedRecallAvgScore = delayedRecallSampleCount
      ? Math.round(mean(delayedScores) * 10) / 10
      : 0;

    const stabilitySampleCount = stabilityRatios.length;
    const stabilityAvgRatio = stabilitySampleCount
      ? Math.round(mean(stabilityRatios) * 1000) / 1000
      : 0;

    const firstTryCount = firstPassed.length;
    const firstTryPassRate = firstTryCount ? mean(firstPassed) : 0;

    let wSum = 0;
    let acc = 0;
    if (delayedRecallSampleCount) {
      acc += (mean(delayedScores) / 100) * 0.5;
      wSum += 0.5;
    }
    if (stabilitySampleCount) {
      acc += mean(stabilityRatios) * 0.35;
      wSum += 0.35;
    }
    if (firstTryCount) {
      acc += firstTryPassRate * 0.2;
      wSum += 0.2;
    }

    const recallScore = wSum > 0 ? Math.round((acc / wSum) * 100) : 0;

    return {
      recallScore,
      delayedRecallSampleCount,
      delayedRecallAvgScore,
      stabilitySampleCount,
      stabilityAvgRatio,
      firstTryCount,
      firstTryPassRate:
        Math.round(firstTryPassRate * 1000) / 1000,
    };
  }

  async create(email: string, password: string, fullName?: string): Promise<User> {
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = this.usersRepository.create({
      email,
      password: hashedPassword,
      fullName,
    });
    return this.usersRepository.save(user);
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { email } });
  }

  async findById(id: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { id } });
  }

  /** Hồ sơ công khai (bảng xếp hạng / bạn bè) — không trả email, password. */
  async getPublicProfile(userId: string) {
    const user = await this.usersRepository.findOne({
      where: { id: userId },
      // NOTE: must include avatarUrl, otherwise TypeORM returns it as undefined/null
      select: ['id', 'fullName', 'avatarUrl', 'totalXP', 'role', 'createdAt'],
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    const currency = await this.currencyRepository.findOne({
      where: { userId },
      select: [
        'coins',
        'diamonds',
        'level',
        'currentStreak',
        'maxStreak',
        'weeklyXp',
      ],
    });
    return {
      id: user.id,
      fullName: user.fullName || 'Anonymous',
      avatarUrl: user.avatarUrl ?? null,
      totalXP: user.totalXP ?? 0,
      role: user.role,
      memberSince: user.createdAt?.toISOString?.() ?? null,
      coins: currency?.coins ?? 0,
      diamonds: currency?.diamonds ?? 0,
      level: currency?.level ?? 1,
      currentStreak: currency?.currentStreak ?? 0,
      maxStreak: currency?.maxStreak ?? 0,
      weeklyXp: currency?.weeklyXp ?? 0,
    };
  }

  async validatePassword(user: User, password: string): Promise<boolean> {
    return bcrypt.compare(password, user.password);
  }

  async updateOnboardingData(userId: string, data: Record<string, any>): Promise<User> {
    const user = await this.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }
    user.onboardingData = data;
    return this.usersRepository.save(user);
  }

  async updatePlacementTest(
    userId: string,
    score: number,
    level: string,
  ): Promise<User> {
    const user = await this.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }
    user.placementTestScore = score;
    user.placementTestLevel = level;
    return this.usersRepository.save(user);
  }

  async updateStreak(userId: string, streak: number): Promise<User> {
    const user = await this.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }
    user.currentStreak = streak;
    return this.usersRepository.save(user);
  }

  async addXP(userId: string, xp: number): Promise<User> {
    const user = await this.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }
    user.totalXP += xp;
    return this.usersRepository.save(user);
  }

  async updateProfile(
    userId: string,
    data: { fullName?: string; phone?: string; avatarUrl?: string },
  ): Promise<User> {
    const user = await this.findById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }
    if (data.fullName !== undefined) {
      const t = data.fullName.trim();
      if (t.length === 0) {
        throw new BadRequestException('fullName cannot be empty');
      }
      if (t.length > 120) {
        throw new BadRequestException('fullName too long');
      }
      user.fullName = t;
    }
    if (data.phone !== undefined) {
      const p = data.phone.trim();
      user.phone = p.length > 0 ? p : null;
    }
    if (data.avatarUrl !== undefined) {
      const v = data.avatarUrl.trim();
      user.avatarUrl = v.length > 0 ? v : null;
    }
    return this.usersRepository.save(user);
  }

  async findOrCreateGoogleUser(email: string, fullName?: string): Promise<User> {
    let user = await this.findByEmail(email);
    if (user) {
      if (user.authProvider !== 'google') {
        user.authProvider = 'google';
        user = await this.usersRepository.save(user);
      }
      return user;
    }
    const randomPass = await bcrypt.hash(Math.random().toString(36), 10);
    const newUser = this.usersRepository.create({
      email,
      password: randomPass,
      fullName: fullName || email.split('@')[0],
      authProvider: 'google',
    });
    return this.usersRepository.save(newUser);
  }

  async setResetToken(userId: string, token: string, expires: Date): Promise<void> {
    await this.usersRepository.update(userId, {
      resetPasswordToken: token,
      resetPasswordExpires: expires,
    });
  }

  async findByResetToken(token: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { resetPasswordToken: token } });
  }

  async updatePassword(userId: string, hashedPassword: string): Promise<void> {
    await this.usersRepository.update(userId, {
      password: hashedPassword,
      resetPasswordToken: null,
      resetPasswordExpires: null,
    });
  }

  async switchRole(
    userId: string,
    targetRole: 'user' | 'contributor',
  ): Promise<User> {
    const user = await this.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }
    // Admin cannot switch to lower roles via this endpoint
    if (user.role === 'admin') {
      throw new Error('Admin role cannot be changed');
    }
    // Only allow switching between user and contributor
    if (targetRole !== 'user' && targetRole !== 'contributor') {
      throw new Error('Invalid target role');
    }
    user.role = targetRole;
    return this.usersRepository.save(user);
  }
}

