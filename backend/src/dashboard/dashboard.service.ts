import { Injectable } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { UserCurrencyService } from '../user-currency/user-currency.service';
import { UserProgressService } from '../user-progress/user-progress.service';
import { SubjectsService } from '../subjects/subjects.service';
import { LearningNodesService } from '../learning-nodes/learning-nodes.service';
import { QuestsService } from '../quests/quests.service';

@Injectable()
export class DashboardService {
  constructor(
    private usersService: UsersService,
    private currencyService: UserCurrencyService,
    private progressService: UserProgressService,
    private subjectsService: SubjectsService,
    private nodesService: LearningNodesService,
    private questsService: QuestsService,
  ) {}

  async getDashboard(userId: string) {
    // Get user info
    const user = await this.usersService.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }

    // Get currency stats
    const currency = await this.currencyService.getCurrency(userId);

    // Get all subjects
    const explorerSubjects = await this.subjectsService.findByTrack('explorer');
    const scholarSubjects = await this.subjectsService.findByTrack('scholar');

    // Get user progress for all subjects
    const completedNodeIds =
      await this.progressService.getCompletedNodes(userId);

    // Get available nodes for each explorer subject (Fog of War)
    const explorerSubjectsWithNodes = await Promise.all(
      explorerSubjects.map(async (subject) => {
        const availableNodes = await this.subjectsService.getAvailableNodesForUser(
          userId,
          subject.id,
        );
        return {
          ...subject,
          availableNodesCount: availableNodes.length,
          totalNodesCount: (await this.nodesService.findBySubject(subject.id))
            .length,
        };
      }),
    );

    // Get scholar subjects with unlock status
    const scholarSubjectsWithStatus = await Promise.all(
      scholarSubjects.map(async (subject) => {
        const status = await this.subjectsService.getSubjectForUser(
          userId,
          subject.id,
        );
        return {
          ...subject,
          isUnlocked: status.isUnlocked,
          canUnlock: status.canUnlock,
          requiredCoins: status.requiredCoins,
          userCoins: status.userCoins,
        };
      }),
    );

    // Get active learning (subjects with progress > 0 but < 100%)
    const activeLearning = [];
    for (const subject of explorerSubjects) {
      const nodes = await this.nodesService.findBySubject(subject.id);
      let totalProgress = 0;
      let completedNodes = 0;

      for (const node of nodes) {
        try {
          const progress = await this.progressService.getProgress(
            userId,
            node.id,
          );
          if (progress.progressPercentage > 0) {
            totalProgress += progress.progressPercentage;
            if (progress.isCompleted) {
              completedNodes++;
            }
          }
        } catch (e) {
          // No progress yet
        }
      }

      if (totalProgress > 0 && completedNodes < nodes.length) {
        const avgProgress = totalProgress / nodes.length;
        activeLearning.push({
          subject: {
            id: subject.id,
            name: subject.name,
            icon: subject.metadata?.icon,
            color: subject.metadata?.color,
          },
          progress: Math.round(avgProgress),
          completedNodes,
          totalNodes: nodes.length,
        });
      }
    }

    // Calculate stats
    const totalNodesCompleted = completedNodeIds.length;
    const totalXP = currency.xp;
    const currentStreak = currency.currentStreak;
    const totalCoins = currency.coins;

    // Get real daily quests
    const dailyQuests = await this.questsService.getDailyQuests(userId);

    return {
      stats: {
        totalXP,
        currentStreak,
        totalCoins,
        totalNodesCompleted,
        shards: currency.shards,
      },
      activeLearning,
      explorer: {
        subjects: explorerSubjectsWithNodes,
      },
      scholar: {
        subjects: scholarSubjectsWithStatus,
      },
      dailyQuests,
      explore: {
        // Suggested subjects to explore
        suggested: explorerSubjectsWithNodes
          .filter((s) => s.availableNodesCount > 0)
          .slice(0, 3),
      },
    };
  }
}

