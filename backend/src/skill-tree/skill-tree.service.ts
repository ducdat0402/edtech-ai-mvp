import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { SkillTree, SkillTreeStatus } from './entities/skill-tree.entity';
import { SkillNode, NodeType } from './entities/skill-node.entity';
import { NodeStatus } from './entities/node-status.enum';
import { UserSkillProgress } from './entities/user-skill-progress.entity';
import { UsersService } from '../users/users.service';
import { SubjectsService } from '../subjects/subjects.service';
import { LearningNodesService } from '../learning-nodes/learning-nodes.service';
import { UserCurrencyService } from '../user-currency/user-currency.service';

@Injectable()
export class SkillTreeService {
  constructor(
    @InjectRepository(SkillTree)
    private skillTreeRepository: Repository<SkillTree>,
    @InjectRepository(SkillNode)
    private skillNodeRepository: Repository<SkillNode>,
    @InjectRepository(UserSkillProgress)
    private userProgressRepository: Repository<UserSkillProgress>,
    private usersService: UsersService,
    private subjectsService: SubjectsService,
    private nodesService: LearningNodesService,
    private currencyService: UserCurrencyService,
  ) {}

  /**
   * Generate Skill Tree từ Learning Nodes của một subject
   */
  async generateSkillTree(
    userId: string,
    subjectId: string,
  ): Promise<SkillTree & { isNewSubject?: boolean; generatingMessage?: string }> {
    // Check if user already has a skill tree for this subject
    const existing = await this.skillTreeRepository.findOne({
      where: {
        userId,
        subjectId,
        status: SkillTreeStatus.ACTIVE,
      },
    });

    if (existing) {
      return existing;
    }

    // Get user data
    const user = await this.usersService.findById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Get subject
    const subject = await this.subjectsService.findById(subjectId);
    if (!subject) {
      throw new NotFoundException('Subject not found');
    }

    // ✅ Check if subject is newly created (within last 5 minutes)
    const isNewSubject = subject.createdAt && 
      (new Date().getTime() - new Date(subject.createdAt).getTime()) < 5 * 60 * 1000;

    // Get placement test result
    const placementTestLevel = user.placementTestLevel || 'beginner';
    const onboardingData = user.onboardingData || {};

    // Get all learning nodes for this subject
    let learningNodes = await this.nodesService.findBySubject(subjectId);

    // ✅ Nếu chưa có nodes, tự động tạo bằng AI
    if (learningNodes.length === 0) {
      console.log(
        `⚠️  No learning nodes found for subject "${subject.name}". Auto-generating with AI...`,
      );

      // Nếu là subject mới, thêm message
      const generatingMessage = isNewSubject 
        ? 'Bạn đợi tí, môn học này chưa có trong hệ thống, bạn chờ chúng mình tạo skill tree trong giây lát nhé'
        : 'Đang tạo learning nodes cho môn học này...';

      try {
        const numberOfNodes = 12;
        const subjectName = subject.name;
        const subjectDescription = subject.description;

        let topics: string[] | undefined;
        if (subject.metadata && (subject.metadata as any).topics) {
          topics = (subject.metadata as any).topics;
        }

        const generatedNodes =
          await this.nodesService.generateNodesFromRawData(
            subjectId,
            subjectName,
            subjectDescription,
            topics,
            numberOfNodes,
          );

        learningNodes = generatedNodes;
        console.log(
          `✅ Auto-generated ${learningNodes.length} Learning Nodes for "${subjectName}"`,
        );

        // Return skill tree with message if it's a new subject
        const skillTree = await this.createSkillTreeFromNodes(
          userId,
          subjectId,
          learningNodes,
          placementTestLevel,
        );

        return {
          ...skillTree,
          isNewSubject,
          generatingMessage: isNewSubject ? generatingMessage : undefined,
        } as SkillTree & { isNewSubject?: boolean; generatingMessage?: string };
      } catch (error) {
        console.error('❌ Error auto-generating learning nodes:', error);
        throw new BadRequestException(
          `Failed to generate learning nodes for this subject. Please try again later. Error: ${error.message}`,
        );
      }
    }

    if (learningNodes.length === 0) {
      throw new BadRequestException(
        'No learning nodes available for this subject',
      );
    }

    // Create skill tree from existing nodes
    return await this.createSkillTreeFromNodes(
      userId,
      subjectId,
      learningNodes,
      placementTestLevel,
    );
  }

  /**
   * Helper method to create skill tree from learning nodes
   */
  private async createSkillTreeFromNodes(
    userId: string,
    subjectId: string,
    learningNodes: any[],
    placementTestLevel: string,
  ): Promise<SkillTree> {
    // Create skill tree
    const skillTree = this.skillTreeRepository.create({
      userId,
      subjectId,
      status: SkillTreeStatus.ACTIVE,
      totalNodes: learningNodes.length,
      unlockedNodes: 0,
      completedNodes: 0,
      totalXP: 0,
      metadata: {
        level: placementTestLevel,
        startingLevel: placementTestLevel,
        completionPercentage: 0,
      },
    });

    const savedTree = await this.skillTreeRepository.save(skillTree);

    // Generate skill nodes from learning nodes
    await this.generateSkillNodes(savedTree, learningNodes, placementTestLevel);

    // Unlock root nodes (nodes without prerequisites)
    await this.unlockRootNodes(userId, savedTree.id);

    return this.getSkillTree(userId, subjectId);
  }

  /**
   * Generate Skill Nodes từ Learning Nodes
   */
  private async generateSkillNodes(
    skillTree: SkillTree,
    learningNodes: any[],
    level: string,
  ): Promise<void> {
    const skillNodes: SkillNode[] = [];

    // Calculate XP và rewards dựa trên level
    const xpMultiplier = {
      beginner: 1,
      intermediate: 1.5,
      advanced: 2,
    };
    const multiplier = xpMultiplier[level] || 1;

    // Sort nodes by order
    const sortedNodes = [...learningNodes].sort((a, b) => a.order - b.order);

    for (let i = 0; i < sortedNodes.length; i++) {
      const learningNode = sortedNodes[i];
      const tier = Math.floor(i / 5); // 5 nodes per tier
      const positionInTier = i % 5;

      // Determine node type
      let nodeType = NodeType.SKILL;
      if (i === sortedNodes.length - 1) {
        nodeType = NodeType.BOSS; // Last node is boss
      } else if (learningNode.contentStructure?.hiddenRewards > 0) {
        nodeType = NodeType.REWARD;
      }

      // Calculate position
      const x = (positionInTier + 1) * 20; // 20, 40, 60, 80, 100
      const y = tier * 25; // 0, 25, 50, 75...

      // Calculate rewards
      const baseXP = 100;
      const baseCoins = 50;
      const rewardXP = Math.floor(baseXP * multiplier);
      const rewardCoins = Math.floor(baseCoins * multiplier);

      // Get prerequisites (previous nodes)
      const prerequisites: string[] = [];
      if (learningNode.prerequisites && learningNode.prerequisites.length > 0) {
        // Map learning node prerequisites to skill node IDs
        // We'll update this after creating all nodes
      }

      const skillNode = this.skillNodeRepository.create({
        skillTreeId: skillTree.id,
        learningNodeId: learningNode.id,
        title: learningNode.title,
        description: learningNode.description,
        order: learningNode.order,
        prerequisites: prerequisites,
        children: [],
        type: nodeType,
        requiredXP: 0, // Unlock based on prerequisites, not XP
        rewardXP,
        rewardCoins,
        unlockConditions: {
          prerequisites: learningNode.prerequisites || [],
        },
        position: {
          x,
          y,
          tier,
        },
        visual: {
          icon: learningNode.metadata?.icon || 'star',
          color: this.getNodeColor(nodeType, tier),
          size: nodeType === NodeType.BOSS ? 'large' : 'medium',
          glow: nodeType === NodeType.BOSS,
        },
        metadata: {
          difficulty: level,
          estimatedMinutes: 20,
          tags: [],
        },
      });

      skillNodes.push(skillNode);
    }

    // Save all nodes
    const savedNodes = await this.skillNodeRepository.save(skillNodes);

    // Update prerequisites and children relationships
    const nodeMap = new Map(
      savedNodes.map((node) => [node.learningNodeId, node]),
    );
    const learningNodeMap = new Map(
      learningNodes.map((node) => [node.id, node]),
    );

    for (const skillNode of savedNodes) {
      const learningNode = learningNodeMap.get(skillNode.learningNodeId);
      if (learningNode?.prerequisites) {
        const skillPrerequisites: string[] = [];
        for (const prereqId of learningNode.prerequisites) {
          const prereqNode = nodeMap.get(prereqId);
          if (prereqNode) {
            skillPrerequisites.push(prereqNode.id);
          }
        }
        skillNode.prerequisites = skillPrerequisites;

        // Update children
        for (const prereqId of learningNode.prerequisites) {
          const prereqNode = nodeMap.get(prereqId);
          if (prereqNode && !prereqNode.children.includes(skillNode.id)) {
            prereqNode.children.push(skillNode.id);
          }
        }
      }
    }

    // Save updated nodes
    await this.skillNodeRepository.save(savedNodes);
  }

  /**
   * Unlock root nodes (nodes without prerequisites)
   */
  private async unlockRootNodes(
    userId: string,
    skillTreeId: string,
  ): Promise<void> {
    // Find nodes with empty prerequisites (root nodes)
    const allNodes = await this.skillNodeRepository.find({
      where: { skillTreeId },
    });
    const rootNodes = allNodes.filter((n) => !n.prerequisites || n.prerequisites.length === 0);

    for (const node of rootNodes) {
      await this.unlockNode(userId, node.id);
    }
  }

  /**
   * Get Skill Tree với progress
   */
  async getSkillTree(
    userId: string,
    subjectId?: string,
  ): Promise<SkillTree | null> {
    const where: any = { userId, status: SkillTreeStatus.ACTIVE };
    if (subjectId) {
      where.subjectId = subjectId;
    }

    const skillTree = await this.skillTreeRepository.findOne({
      where,
      relations: ['nodes', 'subject'],
      order: { createdAt: 'DESC' },
    });

    if (!skillTree) {
      return null;
    }

    // Load user progress for all nodes
    const nodeIds = skillTree.nodes.map((n) => n.id);
    const userProgress =
      nodeIds.length > 0
        ? await this.userProgressRepository.find({
            where: {
              userId,
              skillNodeId: In(nodeIds),
            },
          })
        : [];

    const progressMap = new Map(
      userProgress.map((p) => [p.skillNodeId, p]),
    );

    // Update skill tree stats
    let unlockedCount = 0;
    let completedCount = 0;
    let totalXP = 0;

    for (const node of skillTree.nodes) {
      const progress = progressMap.get(node.id);
      if (progress) {
        if (progress.status !== NodeStatus.LOCKED) {
          unlockedCount++;
        }
        if (progress.status === NodeStatus.COMPLETED) {
          completedCount++;
        }
        totalXP += progress.xpEarned;
      }
    }

    skillTree.unlockedNodes = unlockedCount;
    skillTree.completedNodes = completedCount;
    skillTree.totalXP = totalXP;

    if (skillTree.metadata) {
      skillTree.metadata.completionPercentage =
        skillTree.totalNodes > 0
          ? Math.round((completedCount / skillTree.totalNodes) * 100)
          : 0;
    }

    return skillTree;
  }

  /**
   * Unlock a skill node
   */
  async unlockNode(userId: string, skillNodeId: string): Promise<SkillNode> {
    const node = await this.skillNodeRepository.findOne({
      where: { id: skillNodeId },
      relations: ['skillTree'],
    });

    if (!node) {
      throw new NotFoundException('Skill node not found');
    }

    // Check if already unlocked
    let progress = await this.userProgressRepository.findOne({
      where: { userId, skillNodeId },
    });

    if (progress && progress.status !== NodeStatus.LOCKED) {
      return node;
    }

    // Check prerequisites
    const canUnlock = await this.checkUnlockConditions(userId, node);
    if (!canUnlock) {
      throw new BadRequestException(
        'Cannot unlock node. Prerequisites not met.',
      );
    }

    // Create or update progress
    if (!progress) {
      progress = this.userProgressRepository.create({
        userId,
        skillNodeId,
        status: NodeStatus.UNLOCKED,
        progress: 0,
      });
    } else {
      progress.status = NodeStatus.UNLOCKED;
    }

    progress.unlockedAt = new Date();
    await this.userProgressRepository.save(progress);

    // Update skill tree stats
    const skillTree = node.skillTree;
    const nodeIds = skillTree.nodes.map((n) => n.id);
    const allProgress =
      nodeIds.length > 0
        ? await this.userProgressRepository.find({
            where: {
              userId,
              skillNodeId: In(nodeIds),
            },
          })
        : [];
    skillTree.unlockedNodes = allProgress.filter(
      (p) => p.status !== NodeStatus.LOCKED,
    ).length;

    await this.skillTreeRepository.save(skillTree);

    return node;
  }

  /**
   * Check if node can be unlocked
   */
  private async checkUnlockConditions(
    userId: string,
    node: SkillNode,
  ): Promise<boolean> {
    // Check prerequisites
    if (node.prerequisites && node.prerequisites.length > 0) {
      const prereqProgress = await this.userProgressRepository.find({
        where: {
          userId,
          skillNodeId: In(node.prerequisites),
          status: NodeStatus.COMPLETED,
        },
      });

      if (prereqProgress.length !== node.prerequisites.length) {
        return false;
      }
    }

    // Check XP requirement
    if (node.requiredXP > 0) {
      const userCurrency = await this.currencyService.getCurrency(userId);
      if (!userCurrency || userCurrency.xp < node.requiredXP) {
        return false;
      }
    }

    return true;
  }

  /**
   * Complete skill node from learning node ID
   * Called automatically when learning node is completed
   */
  async completeSkillNodeFromLearningNode(
    userId: string,
    learningNodeId: string,
  ): Promise<UserSkillProgress | null> {
    // Find skill node linked to this learning node
    const skillNode = await this.skillNodeRepository.findOne({
      where: { learningNodeId },
      relations: ['skillTree'],
    });

    if (!skillNode) {
      // No skill tree exists for this learning node yet
      return null;
    }

    // Check if already completed
    const progress = await this.userProgressRepository.findOne({
      where: { userId, skillNodeId: skillNode.id },
    });

    if (progress && progress.status === NodeStatus.COMPLETED) {
      return progress;
    }

    // Complete the skill node
    return this.completeNode(userId, skillNode.id, {
      completedItems: [], // Will be populated from learning node progress
      autoCompleted: true,
    });
  }

  /**
   * Complete a skill node
   */
  async completeNode(
    userId: string,
    skillNodeId: string,
    progressData?: any,
  ): Promise<UserSkillProgress> {
    const node = await this.skillNodeRepository.findOne({
      where: { id: skillNodeId },
      relations: ['skillTree'],
    });

    if (!node) {
      throw new NotFoundException('Skill node not found');
    }

    let progress = await this.userProgressRepository.findOne({
      where: { userId, skillNodeId },
    });

    if (!progress) {
      throw new BadRequestException('Node not unlocked yet');
    }

    // Update progress
    progress.status = NodeStatus.COMPLETED;
    progress.progress = 100;
    progress.completedAt = new Date();
    progress.xpEarned = node.rewardXP;
    progress.coinsEarned = node.rewardCoins;
    if (progressData) {
      progress.progressData = progressData;
    }

    await this.userProgressRepository.save(progress);

    // Award XP and coins
    await this.currencyService.addXP(userId, node.rewardXP);
    await this.currencyService.addCoins(userId, node.rewardCoins);

    // Update skill tree stats
    const skillTree = node.skillTree;
    const nodeIds = skillTree.nodes.map((n) => n.id);
    skillTree.completedNodes =
      nodeIds.length > 0
        ? await this.userProgressRepository.count({
            where: {
              userId,
              skillNodeId: In(nodeIds),
              status: NodeStatus.COMPLETED,
            },
          })
        : 0;
    skillTree.totalXP += node.rewardXP;

    if (skillTree.metadata) {
      skillTree.metadata.completionPercentage =
        skillTree.totalNodes > 0
          ? Math.round((skillTree.completedNodes / skillTree.totalNodes) * 100)
          : 0;
      skillTree.metadata.lastUnlockedAt = new Date();
    }

    await this.skillTreeRepository.save(skillTree);

    // Auto-unlock children nodes
    if (node.children && node.children.length > 0) {
      for (const childId of node.children) {
        try {
          await this.unlockNode(userId, childId);
        } catch (e) {
          // Ignore errors (might already be unlocked or prerequisites not met)
        }
      }
    }

    return progress;
  }

  /**
   * Get node color based on type and tier
   */
  private getNodeColor(type: NodeType, tier: number): string {
    if (type === NodeType.BOSS) {
      return '#FF6B6B'; // Red
    }
    if (type === NodeType.REWARD) {
      return '#FFD93D'; // Yellow
    }

    // Color by tier
    const colors = ['#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA15E'];
    return colors[tier % colors.length];
  }
}

