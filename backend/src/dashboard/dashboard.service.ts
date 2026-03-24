import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { UsersService } from '../users/users.service';
import { UserCurrencyService } from '../user-currency/user-currency.service';
import { UserProgressService } from '../user-progress/user-progress.service';
import { SubjectsService } from '../subjects/subjects.service';
import { LearningNodesService } from '../learning-nodes/learning-nodes.service';
import { QuestsService } from '../quests/quests.service';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { UserProgress } from '../user-progress/entities/user-progress.entity';

@Injectable()
export class DashboardService {
  constructor(
    private usersService: UsersService,
    private currencyService: UserCurrencyService,
    private progressService: UserProgressService,
    private subjectsService: SubjectsService,
    private nodesService: LearningNodesService,
    private questsService: QuestsService,
    @InjectRepository(LearningNode)
    private nodeRepository: Repository<LearningNode>,
    @InjectRepository(UserProgress)
    private progressRepository: Repository<UserProgress>,
  ) {}

  /**
   * Chỉ số thống kê + level — không load toàn bộ learning_nodes.
   * Dùng cho Profile / nơi chỉ cần XP, coin, streak, số bài đã xong.
   */
  async getDashboardSummary(userId: string) {
    const [currency, totalNodesCompleted] = await Promise.all([
      this.currencyService.getCurrency(userId),
      this.progressRepository.count({
        where: { userId, isCompleted: true },
      }),
    ]);

    const totalXP = currency.xp;
    const currentLevel = currency.level || 1;
    const levelInfo = this.currencyService.getLevelInfo(totalXP, currentLevel);

    return {
      stats: {
        totalXP,
        currentStreak: currency.currentStreak,
        maxStreak: currency.maxStreak ?? 0,
        totalCoins: currency.coins,
        totalDiamonds: currency.diamonds ?? 0,
        totalNodesCompleted,
        shards: currency.shards,
        level: currentLevel,
        levelInfo: {
          currentXP: levelInfo.currentXP,
          xpForNextLevel: levelInfo.xpForNextLevel,
          progress: levelInfo.progress,
        },
      },
    };
  }

  async getDashboard(userId: string) {
    const user = await this.usersService.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }

    // Batch: fetch currency, all subjects, all user progress, daily quests in parallel
    const [currency, allSubjects, allUserProgress, dailyQuests] = await Promise.all([
      this.currencyService.getCurrency(userId),
      this.subjectsService.findAll(),
      this.progressRepository.find({
        where: { userId },
        select: ['nodeId', 'progressPercentage', 'isCompleted'],
      }),
      this.questsService.getDailyQuests(userId),
    ]);

    // Build progress lookup map (nodeId -> progress)
    const progressMap = new Map<string, { progressPercentage: number; isCompleted: boolean }>();
    for (const p of allUserProgress) {
      progressMap.set(p.nodeId, { progressPercentage: p.progressPercentage, isCompleted: p.isCompleted });
    }

    const completedNodeIds = allUserProgress.filter(p => p.isCompleted).map(p => p.nodeId);

    // Batch: fetch ALL nodes once (instead of per-subject)
    const allNodes = await this.nodeRepository.find({
      select: ['id', 'title', 'description', 'subjectId', 'domainId', 'topicId', 'order', 'metadata', 'expReward', 'coinReward'],
      order: { order: 'ASC' },
    });

    // Group nodes by subjectId
    const nodesBySubject = new Map<string, LearningNode[]>();
    for (const node of allNodes) {
      if (!nodesBySubject.has(node.subjectId)) {
        nodesBySubject.set(node.subjectId, []);
      }
      nodesBySubject.get(node.subjectId)!.push(node);
    }

    // Build subjects info + active learning in one pass
    const allSubjectsWithInfo = [];
    const activeLearning = [];
    const currentLearningNodes = [];

    for (const subject of allSubjects) {
      const subjectNodes = nodesBySubject.get(subject.id) || [];
      const totalNodesCount = subjectNodes.length;

      // Calculate available nodes (no prerequisites or all prereqs completed)
      const availableNodesCount = subjectNodes.filter(node => {
        if (!node.prerequisites || node.prerequisites.length === 0) return true;
        return node.prerequisites.every(prereqId => completedNodeIds.includes(prereqId));
      }).length;

      // Calculate progress from map (no extra DB calls)
      let totalProgress = 0;
      let completedCount = 0;

      for (const node of subjectNodes) {
        const prog = progressMap.get(node.id);
        if (prog && prog.progressPercentage > 0) {
          totalProgress += prog.progressPercentage;
          if (prog.isCompleted) {
            completedCount++;
          } else {
            currentLearningNodes.push({
              id: node.id,
              title: node.title,
              description: node.description,
              icon: node.metadata?.icon,
              subjectId: subject.id,
              subjectName: subject.name,
              progress: Math.round(prog.progressPercentage),
              domainId: node.domainId,
            });
          }
        }
      }

      allSubjectsWithInfo.push({
        ...subject,
        availableNodesCount,
        totalNodesCount,
        isUnlocked: totalNodesCount > 0 || subject.track === 'explorer',
        canUnlock: true,
        requiredDiamonds: subject.unlockConditions?.minCoin || 0,
        userDiamonds: currency.diamonds ?? 0,
        userCoins: currency.coins,
      });

      if (totalProgress > 0 && completedCount < totalNodesCount) {
        activeLearning.push({
          subject: {
            id: subject.id,
            name: subject.name,
            icon: subject.metadata?.icon,
            color: subject.metadata?.color,
          },
          progress: Math.round(totalProgress / totalNodesCount),
          completedNodes: completedCount,
          totalNodes: totalNodesCount,
        });
      }
    }

    const totalNodesCompleted = completedNodeIds.length;
    const totalXP = currency.xp;
    const currentStreak = currency.currentStreak;
    const maxStreak = currency.maxStreak ?? 0;
    const totalCoins = currency.coins;
    const totalDiamonds = currency.diamonds ?? 0;
    const currentLevel = currency.level || 1;
    const levelInfo = this.currencyService.getLevelInfo(totalXP, currentLevel);

    return {
      stats: {
        totalXP,
        currentStreak,
        maxStreak,
        totalCoins,
        totalDiamonds,
        totalNodesCompleted,
        shards: currency.shards,
        level: currentLevel,
        levelInfo: {
          currentXP: levelInfo.currentXP,
          xpForNextLevel: levelInfo.xpForNextLevel,
          progress: levelInfo.progress,
        },
      },
      activeLearning,
      currentLearningNodes,
      dailyQuests,
      subjects: allSubjectsWithInfo,
    };
  }
}

