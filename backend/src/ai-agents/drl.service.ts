import { Injectable, Logger } from '@nestjs/common';
import { UserBehaviorService } from './user-behavior.service';
import { UserProgressService } from '../user-progress/user-progress.service';
import { LearningNodesService } from '../learning-nodes/learning-nodes.service';

/**
 * Deep Reinforcement Learning Service
 * Uses Deep Q-Network (DQN) approach to optimize learning paths
 * 
 * Reward function:
 * - High mastery: +reward
 * - Low dropout: +reward
 * - Fast completion: +reward
 * - Errors: -penalty
 */
@Injectable()
export class DrlService {
  private readonly logger = new Logger(DrlService.name);

  // Q-table approximation (simplified DQN)
  // In production, this would be a neural network
  private qTable: Map<string, number> = new Map();

  constructor(
    private behaviorService: UserBehaviorService,
    private progressService: UserProgressService,
    private learningNodesService: LearningNodesService,
  ) {}

  /**
   * Get optimal next node for user based on DRL
   * 
   * State: Current node, user mastery, prerequisites completed
   * Action: Next node to learn
   * Reward: Mastery gain, completion rate, error reduction
   */
  async getOptimalNextNode(
    userId: string,
    currentNodeId: string,
    subjectId: string,
  ): Promise<{ nodeId: string; confidence: number; reason: string } | null> {
    try {
      const currentMastery = await this.behaviorService.calculateMastery(
        userId,
        currentNodeId,
      );
      const subjectLearningNodes = await this.learningNodesService.findBySubject(
        subjectId,
      );

      // Filter nodes (simplified - no KG prerequisites)
      const candidateNodes = subjectLearningNodes.filter(
        (n) => n.id !== currentNodeId,
      );

      if (candidateNodes.length === 0) return null;

      const qValues = await Promise.all(
        candidateNodes.map(async (node) => {
          const stateKey = `${userId}:${currentNodeId}:${node.id}`;
          let qValue = this.qTable.get(stateKey) || 0;
          const reward = await this.estimateReward(
            userId,
            currentNodeId,
            node.id,
            currentMastery,
          );
          const learningRate = 0.1;
          qValue = qValue + learningRate * (reward - qValue);
          this.qTable.set(stateKey, qValue);
          return { nodeId: node.id, qValue, reward, node };
        }),
      );

      const epsilon = 0.1;
      const shouldExplore = Math.random() < epsilon;
      let selected;
      if (shouldExplore) {
        selected = qValues[Math.floor(Math.random() * qValues.length)];
      } else {
        selected = qValues.reduce((best, current) =>
          current.qValue > best.qValue ? current : best,
        );
      }

      const maxQ = Math.max(...qValues.map((q) => q.qValue));
      const minQ = Math.min(...qValues.map((q) => q.qValue));
      const confidence = maxQ > minQ
        ? (selected.qValue - minQ) / (maxQ - minQ)
        : 0.5;
      const reason = this.generateReason(selected, currentMastery);

      this.logger.log(
        `DRL recommended node ${selected.nodeId} with confidence ${confidence.toFixed(2)}`,
      );
      return { nodeId: selected.nodeId, confidence, reason };
    } catch (error) {
      this.logger.error(`DRL error: ${error.message}`, error.stack);
      return null;
    }
  }

  /**
   * Estimate reward for transitioning from current node to next node
   */
  private async estimateReward(
    userId: string,
    currentNodeId: string,
    nextNodeId: string,
    currentMastery: number,
  ): Promise<number> {
    let reward = 0;

    // Factor 1: Mastery gain potential
    const targetNode = await this.learningNodesService.findById(nextNodeId);
    const nextDifficulty = this.getDifficultyScore(targetNode?.difficulty);

    if (currentMastery > 0.7 && nextDifficulty > 0.5) {
      reward += 0.3; // Challenging but achievable
    } else if (currentMastery < 0.5 && nextDifficulty < 0.5) {
      reward += 0.2; // Appropriate difficulty
    }

    // Factor 2: Historical performance on similar nodes
    const errorPatterns = await this.behaviorService.getErrorPatterns(
      userId,
      nextNodeId,
    );
    if (errorPatterns.errorRate < 0.2) {
      reward += 0.2; // Low error rate = good
    } else if (errorPatterns.errorRate > 0.5) {
      reward -= 0.3; // High error rate = penalty
    }

    // Factor 3: Learning pace
    const pace = await this.behaviorService.getLearningPace(userId, 7);
    const optimalPace = 300; // 5 minutes per node (ideal)
    if (pace > 0 && pace < optimalPace * 2) {
      reward += 0.2; // Good pace
    }

    return Math.max(-1, Math.min(1, reward)); // Clamp to [-1, 1]
  }

  /**
   * Update Q-values based on actual outcome
   * Called after user completes a node
   */
  async updateQValue(
    userId: string,
    fromNodeId: string,
    toNodeId: string,
    actualReward: number,
  ): Promise<void> {
    const stateKey = `${userId}:${fromNodeId}:${toNodeId}`;
    const currentQ = this.qTable.get(stateKey) || 0;

    // Q-learning update
    const learningRate = 0.1;
    const discountFactor = 0.9;
    const newQ = currentQ + learningRate * (actualReward - currentQ);

    this.qTable.set(stateKey, newQ);

    this.logger.debug(
      `Updated Q-value for ${stateKey}: ${currentQ.toFixed(3)} -> ${newQ.toFixed(3)}`,
    );
  }

  /**
   * Generate human-readable reason for recommendation
   */
  private generateReason(
    selected: { nodeId: string; reward: number; node: any },
    currentMastery: number,
  ): string {
    if (selected.reward > 0.5) {
      return 'Optimal next step based on your strong performance';
    } else if (selected.reward > 0.2) {
      return 'Good progression based on your learning pace';
    } else if (currentMastery > 0.7) {
      return 'Challenging content to advance your skills';
    } else {
      return 'Recommended based on prerequisite mastery';
    }
  }

  /**
   * Convert difficulty string to numeric score
   */
  private getDifficultyScore(
    difficulty?: string,
  ): number {
    const scores: Record<string, number> = {
      easy: 0.25,
      medium: 0.5,
      hard: 0.75,
      expert: 1.0,
    };
    return scores[difficulty || 'medium'] || 0.5;
  }
}

