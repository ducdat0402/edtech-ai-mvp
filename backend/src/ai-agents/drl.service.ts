import { Injectable, Logger } from '@nestjs/common';
import { UserBehaviorService } from './user-behavior.service';
import { KnowledgeGraphService } from '../knowledge-graph/knowledge-graph.service';
import { UserProgressService } from '../user-progress/user-progress.service';
import { NodeType } from '../knowledge-graph/entities/knowledge-node.entity';
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
    private knowledgeGraphService: KnowledgeGraphService,
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
      // Get user's current mastery
      const currentMastery = await this.behaviorService.calculateMastery(
        userId,
        currentNodeId,
      );

      // Get learning nodes for this subject
      const subjectLearningNodes = await this.learningNodesService.findBySubject(
        subjectId,
      );
      const subjectNodeIds = new Set(subjectLearningNodes.map((n) => n.id));

      // Get knowledge graph nodes and filter by subject
      const allNodes = await this.knowledgeGraphService.getNodesByType(
        NodeType.LEARNING_NODE,
      );
      const subjectNodes = allNodes.filter((n) =>
        n.entityId && subjectNodeIds.has(n.entityId),
      );

      // Filter nodes where prerequisites are completed
      const availableNodes = await Promise.all(
        subjectNodes.map(async (node) => {
          const nodePrerequisites = await this.knowledgeGraphService.findPrerequisites(
            node.id,
          );
          const prerequisitesCompleted = await Promise.all(
            nodePrerequisites.map(async (prereq) => {
              if (!prereq.entityId) return false;
              const progress = await this.progressService.getOrCreate(
                userId,
                prereq.entityId,
              );
              return progress.isCompleted;
            }),
          );

          return {
            node,
            prerequisitesSatisfied: prerequisitesCompleted.length === 0 || prerequisitesCompleted.every((c) => c),
            prerequisitesCompleted: prerequisitesCompleted.filter((c) => c)
              .length,
            totalPrerequisites: prerequisitesCompleted.length,
          };
        }),
      );

      const candidateNodes = availableNodes.filter(
        (n) => n.prerequisitesSatisfied && n.node.id !== currentNodeId,
      );

      if (candidateNodes.length === 0) {
        return null;
      }

      // Calculate Q-values for each candidate node
      const qValues = await Promise.all(
        candidateNodes.map(async (candidate) => {
          const stateKey = `${userId}:${currentNodeId}:${candidate.node.id}`;
          let qValue = this.qTable.get(stateKey) || 0;

          // Calculate reward estimate
          const reward = await this.estimateReward(
            userId,
            currentNodeId,
            candidate.node.id,
            currentMastery,
          );

          // Update Q-value (simplified Q-learning)
          const learningRate = 0.1;
          const discountFactor = 0.9;
          qValue = qValue + learningRate * (reward - qValue);
          this.qTable.set(stateKey, qValue);

          return {
            nodeId: candidate.node.id,
            qValue,
            reward,
            node: candidate.node,
          };
        }),
      );

      // Select node with highest Q-value (epsilon-greedy: 90% exploit, 10% explore)
      const epsilon = 0.1;
      const shouldExplore = Math.random() < epsilon;

      let selected;
      if (shouldExplore) {
        // Explore: random selection
        selected = qValues[Math.floor(Math.random() * qValues.length)];
      } else {
        // Exploit: highest Q-value
        selected = qValues.reduce((best, current) =>
          current.qValue > best.qValue ? current : best,
        );
      }

      // Calculate confidence based on Q-value spread
      const maxQ = Math.max(...qValues.map((q) => q.qValue));
      const minQ = Math.min(...qValues.map((q) => q.qValue));
      const confidence = maxQ > minQ
        ? (selected.qValue - minQ) / (maxQ - minQ)
        : 0.5;

      const reason = this.generateReason(selected, currentMastery);

      this.logger.log(
        `DRL recommended node ${selected.nodeId} with confidence ${confidence.toFixed(2)}`,
      );

      return {
        nodeId: selected.nodeId,
        confidence,
        reason,
      };
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

    // Factor 1: Mastery gain potential (0-1)
    // Nodes with higher difficulty when user has high mastery = higher reward
    const targetNodeEntity = await this.knowledgeGraphService.getNodeByEntity(
      nextNodeId,
      NodeType.LEARNING_NODE,
    );
    const nextDifficulty = this.getDifficultyScore(
      targetNodeEntity?.metadata?.difficulty,
    );

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

      // Factor 4: Prerequisite mastery
      const targetNodeForPrereq = await this.knowledgeGraphService.getNodeByEntity(
        nextNodeId,
        NodeType.LEARNING_NODE,
      );
      if (!targetNodeForPrereq) {
        return 0;
      }
      
      const prerequisites = await this.knowledgeGraphService.findPrerequisites(
        targetNodeForPrereq.id,
      );
      const prereqMasteries = await Promise.all(
        prerequisites.map((prereq) => {
          if (!prereq.entityId) return 0;
          return this.behaviorService.calculateMastery(userId, prereq.entityId);
        }),
      );
    const avgPrereqMastery = prereqMasteries.length > 0
      ? prereqMasteries.reduce((a, b) => a + b, 0) / prereqMasteries.length
      : 0;

    if (avgPrereqMastery > 0.7) {
      reward += 0.3; // Strong foundation
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

