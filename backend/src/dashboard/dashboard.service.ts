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

    // Get user progress for all subjects
    const completedNodeIds =
      await this.progressService.getCompletedNodes(userId);

    // Get all subjects (no distinction between explorer and scholar)
    const allSubjects = await this.subjectsService.findAll();

    // Get all subjects with nodes and unlock status
    const allSubjectsWithInfo = await Promise.all(
      allSubjects.map(async (subject) => {
        const availableNodes = await this.subjectsService.getAvailableNodesForUser(
          userId,
          subject.id,
        );
        const status = await this.subjectsService.getSubjectForUser(
          userId,
          subject.id,
        );
        return {
          ...subject,
          availableNodesCount: availableNodes.length,
          totalNodesCount: (await this.nodesService.findBySubject(subject.id))
            .length,
          isUnlocked: status.isUnlocked,
          canUnlock: status.canUnlock,
          requiredCoins: status.requiredCoins,
          userCoins: status.userCoins,
        };
      }),
    );

    // Get active learning (subjects with progress > 0 but < 100%)
    const activeLearning = [];
    // Get current learning nodes (nodes with progress > 0 and < 100%)
    const currentLearningNodes = [];
    
    // Use allSubjects already fetched above for progress calculation
    for (const subject of allSubjects) {
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
            
            // Add to current learning nodes if in progress (0 < progress < 100)
            if (progress.progressPercentage > 0 && progress.progressPercentage < 100 && !progress.isCompleted) {
              currentLearningNodes.push({
                id: node.id,
                title: node.title,
                description: node.description,
                icon: node.metadata?.icon,
                subjectId: subject.id,
                subjectName: subject.name,
                progress: Math.round(progress.progressPercentage),
                domainId: node.domainId,
              });
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
      currentLearningNodes, // Nodes currently being learned (0 < progress < 100)
      dailyQuests,
      subjects: allSubjectsWithInfo, // All subjects from database
    };
  }
}

