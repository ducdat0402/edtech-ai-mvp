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
import { LearningCommunicationAttempt } from '../learning-nodes/entities/learning-communication-attempt.entity';
import { UserWeeklyPlan } from '../self-leadership/entities/user-weekly-plan.entity';
import { SelfLeadershipCheckin } from '../self-leadership/entities/self-leadership-checkin.entity';
import { ChatMessage } from '../world-chat/entities/chat-message.entity';
import { DirectMessage } from '../direct-message/entities/direct-message.entity';
import { Friendship, FriendshipStatus } from '../friends/entities/friendship.entity';
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
    @InjectRepository(LearningCommunicationAttempt)
    private communicationAttemptRepository: Repository<LearningCommunicationAttempt>,
    @InjectRepository(UserWeeklyPlan)
    private weeklyPlanRepository: Repository<UserWeeklyPlan>,
    @InjectRepository(SelfLeadershipCheckin)
    private selfLeadershipCheckinRepository: Repository<SelfLeadershipCheckin>,
    @InjectRepository(ChatMessage)
    private chatMessageRepository: Repository<ChatMessage>,
    @InjectRepository(DirectMessage)
    private directMessageRepository: Repository<DirectMessage>,
    @InjectRepository(Friendship)
    private friendshipRepository: Repository<Friendship>,
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
      communicationAttempts,
      weeklyPlans,
      selfLeadershipCheckins,
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
          select: ['completedAt', 'nodeId'],
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
        this.communicationAttemptRepository.find({
          where: {
            userId,
            createdAt: MoreThanOrEqual(logicalSince),
          },
          order: { createdAt: 'ASC' },
          take: 5000,
        }),
        this.weeklyPlanRepository.find({
          where: {
            userId,
            createdAt: MoreThanOrEqual(logicalSince),
          },
          order: { createdAt: 'ASC' },
          take: 100,
        }),
        this.selfLeadershipCheckinRepository.find({
          where: {
            userId,
            createdAt: MoreThanOrEqual(logicalSince),
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
    const systemsThinking = this.computeSystemsThinkingMetrics(
      quizAttempts,
      logicalSince,
    );
    const creativity = this.computeCreativityMetrics(quizAttempts, logicalSince);
    const communication = this.computeCommunicationMetrics(
      communicationAttempts,
      logicalSince,
    );
    const selfLeadership = this.computeSelfLeadershipMetrics(
      completedLast30.map((x) => ({ completedAt: x.completedAt, nodeId: x.nodeId })),
      weeklyPlans,
      selfLeadershipCheckins,
      logicalSince,
    );
    const discipline = this.computeDisciplineMetrics(
      completedLast30.map((x) => x.completedAt).filter((x): x is Date => !!x),
      logicalSince,
    );
    const growthMindset = this.computeGrowthMindsetMetrics(
      quizAttempts,
      logicalSince,
    );
    const collaboration = await this.computeCollaborationMetrics(
      userId,
      logicalSince,
    );
    const criticalThinking = this.computeCriticalThinkingMetrics(
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
        { key: 'systems_thinking', value: systemsThinking.score },
        { key: 'creativity', value: creativity.score },
        { key: 'communication', value: communication.score },
        { key: 'self_leadership', value: selfLeadership.score },
        { key: 'discipline', value: discipline.score },
        { key: 'growth_mindset', value: growthMindset.score },
        { key: 'critical_thinking', value: criticalThinking.score },
        { key: 'collaboration', value: collaboration.score },
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
        systemsThinking: {
          version: 1,
          windowDays: 30,
          minWeightedTotal: systemsThinking.minWeightedTotal,
          attemptCount: systemsThinking.attemptCount,
          weightedTotal: systemsThinking.weightedTotal,
          weightedCorrect: systemsThinking.weightedCorrect,
          accuracy: systemsThinking.accuracy,
          provisional: systemsThinking.provisional,
          score: systemsThinking.score,
        },
        creativity: {
          version: 1,
          windowDays: 30,
          minWeightedTotal: creativity.minWeightedTotal,
          attemptCount: creativity.attemptCount,
          weightedTotal: creativity.weightedTotal,
          weightedCorrect: creativity.weightedCorrect,
          accuracy: creativity.accuracy,
          provisional: creativity.provisional,
          score: creativity.score,
        },
        communication: {
          version: 1,
          windowDays: 30,
          minSamples: communication.minSamples,
          sampleCount: communication.sampleCount,
          avgBestScore: communication.avgBestScore,
          provisional: communication.provisional,
          score: communication.score,
        },
        selfLeadership: {
          version: 1,
          windowDays: 30,
          weekCount: selfLeadership.weekCount,
          minWeeks: selfLeadership.minWeeks,
          goalCommitment: selfLeadership.goalCommitment,
          executionDiscipline: selfLeadership.executionDiscipline,
          selfCorrection: selfLeadership.selfCorrection,
          provisional: selfLeadership.provisional,
          score: selfLeadership.score,
        },
        discipline: {
          version: 1,
          windowDays: 30,
          activeDays: discipline.activeDays,
          activeDayScore: discipline.activeDayScore,
          weeklyRhythmWeeks: discipline.weeklyRhythmWeeks,
          weeklyRhythmScore: discipline.weeklyRhythmScore,
          timeSlotStabilityScore: discipline.timeSlotStabilityScore,
          dominantHours: discipline.dominantHours,
          provisional: discipline.provisional,
          score: discipline.score,
        },
        growthMindset: {
          version: 1,
          windowDays: 30,
          failGroups: growthMindset.failGroups,
          retryGroups: growthMindset.retryGroups,
          improvedGroups: growthMindset.improvedGroups,
          retryAfterFailRate: growthMindset.retryAfterFailRate,
          improvementAfterRetry: growthMindset.improvementAfterRetry,
          persistenceOnHard: growthMindset.persistenceOnHard,
          provisional: growthMindset.provisional,
          score: growthMindset.score,
        },
        criticalThinking: {
          version: 1,
          windowDays: 30,
          minWeightedTotal: criticalThinking.minWeightedTotal,
          failGroups: criticalThinking.failGroups,
          weightedTotal: criticalThinking.weightedTotal,
          weightedCorrect: criticalThinking.weightedCorrect,
          weightedAccuracy: criticalThinking.weightedAccuracy,
          retryAfterFailRate: criticalThinking.retryAfterFailRate,
          improvementAfterRetry: criticalThinking.improvementAfterRetry,
          provisional: criticalThinking.provisional,
          score: criticalThinking.score,
        },
        collaboration: {
          version: 1,
          windowDays: 30,
          publicMessageCount: collaboration.publicMessageCount,
          dmSentCount: collaboration.dmSentCount,
          uniquePeerCount: collaboration.uniquePeerCount,
          reciprocalPeerCount: collaboration.reciprocalPeerCount,
          acceptedFriendCount: collaboration.acceptedFriendCount,
          engagementScore: collaboration.engagementScore,
          diversityScore: collaboration.diversityScore,
          reciprocityScore: collaboration.reciprocityScore,
          friendBaseScore: collaboration.friendBaseScore,
          provisional: collaboration.provisional,
          score: collaboration.score,
        },
      },
    };
  }

  private async computeCollaborationMetrics(
    userId: string,
    since: Date,
  ): Promise<{
    score: number;
    publicMessageCount: number;
    dmSentCount: number;
    uniquePeerCount: number;
    reciprocalPeerCount: number;
    acceptedFriendCount: number;
    engagementScore: number;
    diversityScore: number;
    reciprocityScore: number;
    friendBaseScore: number;
    provisional: boolean;
  }> {
    const [publicMessages, directMessages, acceptedFriendCount] = await Promise.all([
      this.chatMessageRepository.find({
        where: {
          userId,
          createdAt: MoreThanOrEqual(since),
        },
        select: ['id', 'createdAt'],
        take: 5000,
      }),
      this.directMessageRepository.find({
        where: [
          { senderId: userId, createdAt: MoreThanOrEqual(since) },
          { receiverId: userId, createdAt: MoreThanOrEqual(since) },
        ],
        select: ['senderId', 'receiverId', 'createdAt'],
        take: 5000,
      }),
      this.friendshipRepository.count({
        where: [
          { requesterId: userId, status: FriendshipStatus.ACCEPTED },
          { addresseeId: userId, status: FriendshipStatus.ACCEPTED },
        ],
      }),
    ]);

    const publicMessageCount = publicMessages.length;
    const dmSent = directMessages.filter((x) => x.senderId === userId);
    const dmSentCount = dmSent.length;

    const sentPeers = new Set<string>();
    const recvPeers = new Set<string>();
    const allPeers = new Set<string>();
    for (const m of directMessages) {
      const peerId = m.senderId === userId ? m.receiverId : m.senderId;
      if (!peerId || peerId === userId) continue;
      allPeers.add(peerId);
      if (m.senderId === userId) sentPeers.add(peerId);
      if (m.receiverId === userId) recvPeers.add(peerId);
    }

    let reciprocalPeerCount = 0;
    for (const peer of allPeers) {
      if (sentPeers.has(peer) && recvPeers.has(peer)) reciprocalPeerCount++;
    }
    const uniquePeerCount = allPeers.size;

    const engagementScore = Math.min(
      100,
      Math.round(((publicMessageCount + dmSentCount) / 20) * 100),
    );
    const diversityScore = Math.min(
      100,
      Math.round((uniquePeerCount / 5) * 100),
    );
    const reciprocityScore = Math.min(
      100,
      Math.round((reciprocalPeerCount / 3) * 100),
    );
    const friendBaseScore = Math.min(
      100,
      Math.round((acceptedFriendCount / 5) * 100),
    );

    const totalInteractions = publicMessageCount + dmSentCount;
    const provisional = totalInteractions < 8 || uniquePeerCount < 2;
    const score = provisional
      ? 0
      : Math.round(
          engagementScore * 0.35 +
            diversityScore * 0.3 +
            reciprocityScore * 0.25 +
            friendBaseScore * 0.1,
        );

    return {
      score: Math.max(0, Math.min(100, score)),
      publicMessageCount,
      dmSentCount,
      uniquePeerCount,
      reciprocalPeerCount,
      acceptedFriendCount,
      engagementScore,
      diversityScore,
      reciprocityScore,
      friendBaseScore,
      provisional,
    };
  }

  private computeCriticalThinkingMetrics(
    attempts: LearningQuizAttempt[],
    since: Date,
  ): {
    score: number;
    minWeightedTotal: number;
    failGroups: number;
    weightedTotal: number;
    weightedCorrect: number;
    weightedAccuracy: number;
    retryAfterFailRate: number;
    improvementAfterRetry: number;
    provisional: boolean;
  } {
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
        const raw = mix?.critical_thinking;
        const w =
          typeof raw === 'number' && Number.isFinite(raw) ? Math.max(0, raw) : 0;
        if (w <= 0) continue;
        weightedTotal += w;
        if (row.isCorrect) weightedCorrect += w;
      }
    }
    const weightedAccuracy = weightedTotal > 0 ? weightedCorrect / weightedTotal : 0;

    const groups = new Map<string, LearningQuizAttempt[]>();
    for (const a of filtered) {
      const key = `${a.nodeId}\u0000${a.lessonType ?? ''}`;
      if (!groups.has(key)) groups.set(key, []);
      groups.get(key)!.push(a);
    }
    let failGroups = 0;
    let retryGroups = 0;
    let totalGain = 0;
    for (const arr of groups.values()) {
      const sorted = [...arr].sort(
        (x, y) => x.createdAt.getTime() - y.createdAt.getTime(),
      );
      if (!sorted.length) continue;
      const first = sorted[0];
      if (first.score >= 70) continue;
      failGroups++;
      const retries = sorted.slice(1);
      if (retries.length > 0) {
        retryGroups++;
        const bestRetry = retries.reduce((m, x) => Math.max(m, x.score), 0);
        totalGain += Math.max(0, bestRetry - first.score);
      }
    }
    const retryAfterFailRate = failGroups ? retryGroups / failGroups : 0;
    const improvementAfterRetry = retryGroups
      ? Math.min(1, (totalGain / retryGroups) / 35)
      : 0;

    const minWeightedTotal = 8;
    const provisional = weightedTotal < minWeightedTotal || failGroups < 3;
    const score = provisional
      ? 0
      : Math.round(
          (weightedAccuracy * 0.7 +
            retryAfterFailRate * 0.2 +
            improvementAfterRetry * 0.1) *
            100,
        );

    return {
      score: Math.max(0, Math.min(100, score)),
      minWeightedTotal,
      failGroups,
      weightedTotal: Math.round(weightedTotal * 1000) / 1000,
      weightedCorrect: Math.round(weightedCorrect * 1000) / 1000,
      weightedAccuracy: Math.round(weightedAccuracy * 1000) / 1000,
      retryAfterFailRate: Math.round(retryAfterFailRate * 1000) / 1000,
      improvementAfterRetry: Math.round(improvementAfterRetry * 1000) / 1000,
      provisional,
    };
  }

  private computeGrowthMindsetMetrics(
    attempts: LearningQuizAttempt[],
    since: Date,
  ): {
    score: number;
    failGroups: number;
    retryGroups: number;
    improvedGroups: number;
    retryAfterFailRate: number;
    improvementAfterRetry: number;
    persistenceOnHard: number;
    provisional: boolean;
  } {
    const filtered = attempts.filter((a) => a.createdAt >= since);
    const groups = new Map<string, LearningQuizAttempt[]>();
    for (const a of filtered) {
      const key = `${a.nodeId}\u0000${a.lessonType ?? ''}`;
      if (!groups.has(key)) groups.set(key, []);
      groups.get(key)!.push(a);
    }

    let failGroups = 0;
    let retryGroups = 0;
    let improvedGroups = 0;
    let totalGain = 0;
    let hardFailGroups = 0;
    let hardFailPersistent = 0;

    for (const arr of groups.values()) {
      const sorted = [...arr].sort(
        (x, y) => x.createdAt.getTime() - y.createdAt.getTime(),
      );
      if (!sorted.length) continue;
      const first = sorted[0];
      if (first.score >= 70) continue;
      failGroups++;

      const retries = sorted.slice(1);
      if (retries.length > 0) {
        retryGroups++;
        const bestRetry = retries.reduce((m, x) => Math.max(m, x.score), 0);
        const gain = Math.max(0, bestRetry - first.score);
        totalGain += gain;
        if (bestRetry > first.score) improvedGroups++;
      }

      if (first.score < 50) {
        hardFailGroups++;
        if (retries.length > 0) hardFailPersistent++;
      }
    }

    const retryAfterFailRate = failGroups ? (retryGroups / failGroups) * 100 : 0;
    const improvementAfterRetry = retryGroups
      ? Math.min(100, (totalGain / retryGroups) * 2)
      : 0;
    const persistenceOnHard = hardFailGroups
      ? (hardFailPersistent / hardFailGroups) * 100
      : 0;

    const provisional = failGroups < 3;
    const score = provisional
      ? 0
      : Math.round(
          retryAfterFailRate * 0.4 +
            improvementAfterRetry * 0.4 +
            persistenceOnHard * 0.2,
        );

    return {
      score: Math.max(0, Math.min(100, score)),
      failGroups,
      retryGroups,
      improvedGroups,
      retryAfterFailRate: Math.round(retryAfterFailRate * 10) / 10,
      improvementAfterRetry: Math.round(improvementAfterRetry * 10) / 10,
      persistenceOnHard: Math.round(persistenceOnHard * 10) / 10,
      provisional,
    };
  }

  private computeDisciplineMetrics(
    completedDates: Date[],
    since: Date,
  ): {
    score: number;
    activeDays: number;
    activeDayScore: number;
    weeklyRhythmWeeks: number;
    weeklyRhythmScore: number;
    timeSlotStabilityScore: number;
    dominantHours: number[];
    provisional: boolean;
  } {
    const filtered = completedDates
      .filter((d) => d >= since)
      .sort((a, b) => a.getTime() - b.getTime());

    const dayKeys = new Set<string>();
    const weekBuckets = new Map<string, Set<string>>();
    const hourCounts = new Map<number, number>();

    const toWeekStart = (d: Date) => {
      const x = new Date(d);
      const day = x.getDay();
      const diff = day === 0 ? -6 : 1 - day;
      x.setDate(x.getDate() + diff);
      x.setHours(0, 0, 0, 0);
      return x.toISOString().slice(0, 10);
    };

    for (const d of filtered) {
      const dayKey = d.toISOString().slice(0, 10);
      dayKeys.add(dayKey);

      const wk = toWeekStart(d);
      if (!weekBuckets.has(wk)) weekBuckets.set(wk, new Set());
      weekBuckets.get(wk)!.add(dayKey);

      const h = d.getHours();
      hourCounts.set(h, (hourCounts.get(h) ?? 0) + 1);
    }

    const activeDays = dayKeys.size;
    const activeDayScore = Math.min(100, Math.round((activeDays / 20) * 100));

    let weeklyRhythmWeeks = 0;
    for (const days of weekBuckets.values()) {
      if (days.size >= 3) weeklyRhythmWeeks++;
    }
    const weeklyRhythmScore = Math.min(
      100,
      Math.round((weeklyRhythmWeeks / 4) * 100),
    );

    const topHours = [...hourCounts.entries()]
      .sort((a, b) => b[1] - a[1])
      .slice(0, 2);
    const dominantHours = topHours.map(([h]) => h);
    const totalSessions = filtered.length;
    const dominantSessions = topHours.reduce((s, [, c]) => s + c, 0);
    const timeSlotStabilityScore =
      totalSessions > 0
        ? Math.round(Math.min(1, dominantSessions / totalSessions) * 100)
        : 0;

    const weekCount = weekBuckets.size;
    const provisional = activeDays < 10 || weekCount < 2;
    const score = provisional
      ? 0
      : Math.round(
          activeDayScore * 0.4 +
            weeklyRhythmScore * 0.35 +
            timeSlotStabilityScore * 0.25,
        );

    return {
      score: Math.max(0, Math.min(100, score)),
      activeDays,
      activeDayScore,
      weeklyRhythmWeeks,
      weeklyRhythmScore,
      timeSlotStabilityScore,
      dominantHours,
      provisional,
    };
  }

  private computeSelfLeadershipMetrics(
    completed: Array<{ completedAt: Date | null; nodeId: string }>,
    plans: UserWeeklyPlan[],
    checkins: SelfLeadershipCheckin[],
    since: Date,
  ): {
    score: number;
    weekCount: number;
    minWeeks: number;
    goalCommitment: number;
    executionDiscipline: number;
    selfCorrection: number;
    provisional: boolean;
  } {
    const weekMap = new Map<
      string,
      {
        plan?: UserWeeklyPlan;
        completedDates: Date[];
        completedLessons: Set<string>;
        checkins: SelfLeadershipCheckin[];
      }
    >();
    const ensure = (weekStart: string) => {
      if (!weekMap.has(weekStart)) {
        weekMap.set(weekStart, {
          completedDates: [],
          completedLessons: new Set(),
          checkins: [],
        });
      }
      return weekMap.get(weekStart)!;
    };

    const toWeekStart = (d: Date) => {
      const x = new Date(d);
      const day = x.getDay();
      const diff = day === 0 ? -6 : 1 - day;
      x.setDate(x.getDate() + diff);
      x.setHours(0, 0, 0, 0);
      return x.toISOString().slice(0, 10);
    };

    for (const p of plans) {
      ensure(p.weekStart).plan = p;
    }
    for (const c of completed) {
      if (!c.completedAt || c.completedAt < since) continue;
      const wk = toWeekStart(c.completedAt);
      const row = ensure(wk);
      row.completedDates.push(c.completedAt);
      row.completedLessons.add(c.nodeId);
    }
    for (const c of checkins) {
      if (c.createdAt < since) continue;
      ensure(c.weekStart).checkins.push(c);
    }

    const weeks = [...weekMap.values()].filter((w) => w.plan);
    const weekCount = weeks.length;
    const minWeeks = 2;
    if (!weekCount) {
      return {
        score: 0,
        weekCount,
        minWeeks,
        goalCommitment: 0,
        executionDiscipline: 0,
        selfCorrection: 0,
        provisional: true,
      };
    }

    let goalCommitmentSum = 0;
    let executionDisciplineSum = 0;
    let selfCorrectionSum = 0;

    for (const w of weeks) {
      const plan = w.plan!;
      const sessionRatio = Math.min(1, w.completedDates.length / Math.max(1, plan.targetSessions));
      const lessonRatio = Math.min(1, w.completedLessons.size / Math.max(1, plan.targetLessons));
      const goalCommitment = (sessionRatio * 0.6 + lessonRatio * 0.4) * 100;

      const learnedDays = new Set(w.completedDates.map((d) => d.getDay()));
      const targetDays = new Set((plan.plannedDays ?? []).map((d) => Number(d)));
      let overlap = 0;
      for (const d of learnedDays) if (targetDays.has(d)) overlap++;
      const executionDiscipline = targetDays.size
        ? Math.min(1, overlap / targetDays.size) * 100
        : 0;

      const deviated = w.checkins.filter((x) => !x.followedPlan);
      const corrected = deviated.filter((x) => !!x.nextAction?.trim()).length;
      const selfCorrection = deviated.length
        ? Math.min(1, corrected / deviated.length) * 100
        : 100;

      goalCommitmentSum += goalCommitment;
      executionDisciplineSum += executionDiscipline;
      selfCorrectionSum += selfCorrection;
    }

    const goalCommitment = goalCommitmentSum / weekCount;
    const executionDiscipline = executionDisciplineSum / weekCount;
    const selfCorrection = selfCorrectionSum / weekCount;
    const provisional = weekCount < minWeeks;
    const score = provisional
      ? 0
      : Math.round(goalCommitment * 0.4 + executionDiscipline * 0.35 + selfCorrection * 0.25);

    return {
      score: Math.max(0, Math.min(100, score)),
      weekCount,
      minWeeks,
      goalCommitment: Math.round(goalCommitment * 10) / 10,
      executionDiscipline: Math.round(executionDiscipline * 10) / 10,
      selfCorrection: Math.round(selfCorrection * 10) / 10,
      provisional,
    };
  }

  private computeCommunicationMetrics(
    attempts: LearningCommunicationAttempt[],
    since: Date,
  ): {
    score: number;
    minSamples: number;
    sampleCount: number;
    avgBestScore: number;
    provisional: boolean;
  } {
    const minSamples = 3;
    const filtered = attempts.filter((a) => a.createdAt >= since);
    const bestByLesson = new Map<string, number>();

    for (const a of filtered) {
      const key = `${a.nodeId}\u0000${a.lessonType ?? ''}`;
      const prev = bestByLesson.get(key) ?? 0;
      if (a.totalScore > prev) bestByLesson.set(key, a.totalScore);
    }

    const bestScores = [...bestByLesson.values()];
    const sampleCount = bestScores.length;
    const avgBestScore = sampleCount
      ? bestScores.reduce((s, x) => s + x, 0) / sampleCount
      : 0;
    const provisional = sampleCount < minSamples;
    const score = provisional ? 0 : Math.round(avgBestScore);

    return {
      score: Math.max(0, Math.min(100, score)),
      minSamples,
      sampleCount,
      avgBestScore: Math.round(avgBestScore * 10) / 10,
      provisional,
    };
  }

  private computeSystemsThinkingMetrics(
    attempts: LearningQuizAttempt[],
    since: Date,
  ): {
    score: number;
    windowDays: number;
    minWeightedTotal: number;
    attemptCount: number;
    weightedTotal: number;
    weightedCorrect: number;
    accuracy: number;
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
        const weightRaw = mix?.systems_thinking;
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
      windowDays: 30,
      minWeightedTotal,
      attemptCount: filtered.length,
      weightedTotal: Math.round(weightedTotal * 1000) / 1000,
      weightedCorrect: Math.round(weightedCorrect * 1000) / 1000,
      accuracy: Math.round(accuracy * 1000) / 1000,
      provisional,
    };
  }

  private computeCreativityMetrics(
    attempts: LearningQuizAttempt[],
    since: Date,
  ): {
    score: number;
    windowDays: number;
    minWeightedTotal: number;
    attemptCount: number;
    weightedTotal: number;
    weightedCorrect: number;
    accuracy: number;
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
        const weightRaw = mix?.creativity;
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
      windowDays: 30,
      minWeightedTotal,
      attemptCount: filtered.length,
      weightedTotal: Math.round(weightedTotal * 1000) / 1000,
      weightedCorrect: Math.round(weightedCorrect * 1000) / 1000,
      accuracy: Math.round(accuracy * 1000) / 1000,
      provisional,
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
      ? 0
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

