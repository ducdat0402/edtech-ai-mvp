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
import { UserProgress } from '../user-progress/entities/user-progress.entity';

@Injectable()
export class SkillTreeService {
  constructor(
    @InjectRepository(SkillTree)
    private skillTreeRepository: Repository<SkillTree>,
    @InjectRepository(SkillNode)
    private skillNodeRepository: Repository<SkillNode>,
    @InjectRepository(UserSkillProgress)
    private userProgressRepository: Repository<UserSkillProgress>,
    @InjectRepository(UserProgress)
    private learningProgressRepository: Repository<UserProgress>,
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

    // Sort by order for sequential processing
    const sortedSkillNodes = [...savedNodes].sort((a, b) => a.order - b.order);

    for (let i = 0; i < sortedSkillNodes.length; i++) {
      const skillNode = sortedSkillNodes[i];
      const learningNode = learningNodeMap.get(skillNode.learningNodeId);
      
      // Set prerequisites from learning node
      if (learningNode?.prerequisites) {
        const skillPrerequisites: string[] = [];
        for (const prereqId of learningNode.prerequisites) {
          const prereqNode = nodeMap.get(prereqId);
          if (prereqNode) {
            skillPrerequisites.push(prereqNode.id);
          }
        }
        skillNode.prerequisites = skillPrerequisites;

        // Update children for prerequisite nodes
        for (const prereqId of learningNode.prerequisites) {
          const prereqNode = nodeMap.get(prereqId);
          if (prereqNode && !prereqNode.children.includes(skillNode.id)) {
            prereqNode.children.push(skillNode.id);
          }
        }
      }
      
      // ✅ Also set children based on sequential order (next node in sequence)
      // This ensures that even if prerequisites are empty, we still unlock the next node
      if (i < sortedSkillNodes.length - 1) {
        const nextNode = sortedSkillNodes[i + 1];
        // Only add if not already in children (avoid duplicates)
        if (!skillNode.children.includes(nextNode.id)) {
          skillNode.children.push(nextNode.id);
        }
      }
    }

    // Save updated nodes
    await this.skillNodeRepository.save(savedNodes);
  }

  /**
   * Unlock root nodes (nodes without prerequisites)
   * Also unlock the first node(s) to ensure user can start learning
   */
  private async unlockRootNodes(
    userId: string,
    skillTreeId: string,
  ): Promise<void> {
    // Find all nodes
    const allNodes = await this.skillNodeRepository.find({
      where: { skillTreeId },
      order: { order: 'ASC' },
    });

    if (allNodes.length === 0) {
      console.log('⚠️  No nodes found to unlock');
      return;
    }

    // Find nodes with empty prerequisites (root nodes)
    const rootNodes = allNodes.filter((n) => !n.prerequisites || n.prerequisites.length === 0);

    // ✅ Always unlock at least the first node (order = 0 or minimum order)
    // This ensures user can always start learning even if all nodes have prerequisites
    const firstNode = allNodes[0]; // First node by order
    const nodesToUnlock = new Set<string>();

    // Add root nodes
    rootNodes.forEach(node => nodesToUnlock.add(node.id));

    // If no root nodes, unlock first node anyway
    if (rootNodes.length === 0 && firstNode) {
      console.log(`⚠️  No root nodes found, unlocking first node (order: ${firstNode.order})`);
      nodesToUnlock.add(firstNode.id);
    } else if (firstNode && !nodesToUnlock.has(firstNode.id)) {
      // Also unlock first node if it's not already a root node
      console.log(`✅ Also unlocking first node (order: ${firstNode.order}) to ensure user can start`);
      nodesToUnlock.add(firstNode.id);
    }

    // Unlock all selected nodes (bypass prerequisites check for root nodes)
    for (const nodeId of nodesToUnlock) {
      try {
        const node = allNodes.find(n => n.id === nodeId);
        if (!node) continue;

        // Check if already unlocked
        let progress = await this.userProgressRepository.findOne({
          where: { userId, skillNodeId: nodeId },
        });

        if (progress && progress.status !== NodeStatus.LOCKED) {
          console.log(`✅ Node ${nodeId} already unlocked`);
          continue;
        }

        // Create or update progress (bypass prerequisites for root nodes)
        if (!progress) {
          progress = this.userProgressRepository.create({
            userId,
            skillNodeId: nodeId,
            status: NodeStatus.UNLOCKED,
            progress: 0,
          });
        } else {
          progress.status = NodeStatus.UNLOCKED;
        }

        progress.unlockedAt = new Date();
        await this.userProgressRepository.save(progress);
        console.log(`✅ Unlocked node: ${nodeId} (order: ${node.order})`);
      } catch (error) {
        console.error(`❌ Error unlocking node ${nodeId}:`, error);
        // Continue with other nodes
      }
    }

    // Update skill tree stats
    const allProgress = await this.userProgressRepository.find({
      where: {
        userId,
        skillNodeId: In(allNodes.map(n => n.id)),
      },
    });

    const skillTree = await this.skillTreeRepository.findOne({
      where: { id: skillTreeId },
    });

    if (skillTree) {
      skillTree.unlockedNodes = allProgress.filter(
        (p) => p.status !== NodeStatus.LOCKED,
      ).length;
      await this.skillTreeRepository.save(skillTree);
    }

    console.log(`✅ Unlocked ${nodesToUnlock.size} root/starting node(s)`);
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
      relations: ['nodes', 'nodes.userProgress', 'subject'],
      order: { createdAt: 'DESC' },
    });

    if (!skillTree) {
      return null;
    }

    // Load user progress for all nodes
    const nodeIds = skillTree.nodes.map((n) => n.id);
    let userProgress =
      nodeIds.length > 0
        ? await this.userProgressRepository.find({
            where: {
              userId,
              skillNodeId: In(nodeIds),
            },
          })
        : [];

    // ✅ Nếu không có progress nào, có thể skill tree mới được tạo
    // Tự động unlock root nodes để đảm bảo user có thể bắt đầu học
    if (userProgress.length === 0 && skillTree.nodes.length > 0) {
      console.log(`⚠️  No user progress found, auto-unlocking root nodes for skill tree ${skillTree.id}`);
      await this.unlockRootNodes(userId, skillTree.id);
      
      // Reload progress after unlocking
      userProgress = await this.userProgressRepository.find({
        where: {
          userId,
          skillNodeId: In(nodeIds),
        },
      });
    }

    const progressMap = new Map(
      userProgress.map((p) => [p.skillNodeId, p]),
    );

    // ✅ Sync skill node completion with learning node completion
    // Check if any learning nodes are completed but skill nodes are not
    const nodesToSync: SkillNode[] = [];
    for (const node of skillTree.nodes) {
      if (node.learningNodeId) {
        const progress = progressMap.get(node.id);
        // If skill node is not completed, check if learning node is completed
        if (!progress || progress.status !== NodeStatus.COMPLETED) {
          try {
            const learningProgress = await this.learningProgressRepository.findOne({
              where: { userId, nodeId: node.learningNodeId },
            });
            if (learningProgress && learningProgress.isCompleted) {
              console.log(`🔄 Learning node ${node.learningNodeId} is completed but skill node ${node.id} is not. Syncing...`);
              nodesToSync.push(node);
            }
          } catch (error) {
            console.error(`❌ Error checking learning node progress for ${node.learningNodeId}:`, error);
          }
        }
      }
    }

    // Complete skill nodes that have completed learning nodes
    for (const node of nodesToSync) {
      try {
        await this.completeSkillNodeFromLearningNode(userId, node.learningNodeId);
        console.log(`✅ Synced skill node ${node.id} completion from learning node ${node.learningNodeId}`);
      } catch (error) {
        console.error(`❌ Error syncing skill node ${node.id}:`, error);
      }
    }

    // Reload progress after syncing
    if (nodesToSync.length > 0) {
      userProgress = await this.userProgressRepository.find({
        where: {
          userId,
          skillNodeId: In(nodeIds),
        },
      });
      // Rebuild progress map
      for (const p of userProgress) {
        progressMap.set(p.skillNodeId, p);
      }
    }

    // ✅ Attach userProgress to each node for frontend
    // Ensure userProgress is properly serialized for frontend
    for (const node of skillTree.nodes) {
      const progress = progressMap.get(node.id);
      
      // Attach progress as array (matching frontend expectation)
      // Convert to plain object to ensure proper serialization
      if (progress) {
        (node as any).userProgress = [{
          id: progress.id,
          userId: progress.userId,
          skillNodeId: progress.skillNodeId,
          status: progress.status,
          progress: progress.progress,
          xpEarned: progress.xpEarned,
          coinsEarned: progress.coinsEarned,
          unlockedAt: progress.unlockedAt,
          startedAt: progress.startedAt,
          completedAt: progress.completedAt,
          progressData: progress.progressData,
        }];
      } else {
        (node as any).userProgress = [];
      }
    }

    // ✅ Always recalculate skill tree stats from database (don't trust cached values)
    // Reuse nodeIds from above (already defined at line 444)
    const allProgressForTree = nodeIds.length > 0
      ? await this.userProgressRepository.find({
          where: {
            userId,
            skillNodeId: In(nodeIds),
          },
        })
      : [];
    
    let unlockedCount = 0;
    let completedCount = 0;
    let totalXP = 0;

    for (const progress of allProgressForTree) {
        if (progress.status !== NodeStatus.LOCKED) {
          unlockedCount++;
        }
        if (progress.status === NodeStatus.COMPLETED) {
          completedCount++;
        }
      totalXP += progress.xpEarned || 0;
    }

    // Update skill tree stats
    skillTree.unlockedNodes = unlockedCount;
    skillTree.completedNodes = completedCount;
    skillTree.totalXP = totalXP;
    
    // Save updated stats to database
    await this.skillTreeRepository.save(skillTree);
    
    console.log(`📊 Skill tree stats recalculated: ${completedCount}/${skillTree.totalNodes} completed, ${unlockedCount} unlocked`);

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

    // Check prerequisites (skip check if this is called from unlockRootNodes)
    // We'll check if this is a root node (no prerequisites or first node)
    const isRootNode = !node.prerequisites || node.prerequisites.length === 0;
    const canUnlock = isRootNode || await this.checkUnlockConditions(userId, node);
    
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
    try {
      console.log(`🔍 Looking for skill node with learningNodeId: ${learningNodeId}`);
    // Find skill node linked to this learning node
    const skillNode = await this.skillNodeRepository.findOne({
      where: { learningNodeId },
      relations: ['skillTree'],
    });

    if (!skillNode) {
      // No skill tree exists for this learning node yet
        console.log(`⚠️  No skill node found for learning node ${learningNodeId}`);
        // Try to find by searching all skill nodes (debug)
        const allNodes = await this.skillNodeRepository.find({
          relations: ['skillTree'],
        });
        console.log(`📋 Total skill nodes in system: ${allNodes.length}`);
        console.log(`📋 Learning node IDs in skill nodes: ${allNodes.map(n => n.learningNodeId).filter(Boolean).join(', ')}`);
      return null;
    }
      
      console.log(`✅ Found skill node ${skillNode.id} (${skillNode.title}) for learning node ${learningNodeId}`);

    // Check if already completed
      let progress = await this.userProgressRepository.findOne({
      where: { userId, skillNodeId: skillNode.id },
    });

    if (progress && progress.status === NodeStatus.COMPLETED) {
      return progress;
    }

      // ✅ Ensure node is unlocked before completing
      if (!progress || progress.status === NodeStatus.LOCKED) {
        console.log(`⚠️  Skill node ${skillNode.id} not unlocked, unlocking first...`);
        try {
          await this.unlockNode(userId, skillNode.id);
          // Reload progress after unlocking
          progress = await this.userProgressRepository.findOne({
            where: { userId, skillNodeId: skillNode.id },
          });
        } catch (unlockError) {
          console.error(`❌ Error unlocking skill node ${skillNode.id}:`, unlockError);
          // Try to unlock anyway (might be root node)
          if (!progress) {
            progress = this.userProgressRepository.create({
              userId,
              skillNodeId: skillNode.id,
              status: NodeStatus.UNLOCKED,
              progress: 0,
            });
            progress = await this.userProgressRepository.save(progress);
          } else {
            progress.status = NodeStatus.UNLOCKED;
            progress = await this.userProgressRepository.save(progress);
          }
        }
      }

    // Complete the skill node
      console.log(`🎯 Completing skill node ${skillNode.id}...`);
      const result = await this.completeNode(userId, skillNode.id, {
      completedItems: [], // Will be populated from learning node progress
      autoCompleted: true,
    });
      console.log(`✅ Skill node ${skillNode.id} completed! Status: ${result.status}`);
      return result;
    } catch (error) {
      console.error(`❌ Error completing skill node from learning node ${learningNodeId}:`, error);
      // Don't throw - this is called from user progress service and shouldn't break the flow
      return null;
    }
  }

  /**
   * Complete a skill node
   */
  async completeNode(
    userId: string,
    skillNodeId: string,
    progressData?: any,
  ): Promise<UserSkillProgress> {
    try {
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
      progress.xpEarned = node.rewardXP || 0;
      progress.coinsEarned = node.rewardCoins || 0;
    if (progressData) {
      progress.progressData = progressData;
    }

    await this.userProgressRepository.save(progress);

      // Award XP and coins (with error handling)
      try {
        if (node.rewardXP && node.rewardXP > 0) {
    await this.currencyService.addXP(userId, node.rewardXP);
        }
        if (node.rewardCoins && node.rewardCoins > 0) {
    await this.currencyService.addCoins(userId, node.rewardCoins);
        }
      } catch (currencyError) {
        console.error(`❌ Error awarding currency for node ${skillNodeId}:`, currencyError);
        // Continue even if currency update fails
      }

      // Update skill tree stats (with error handling)
      try {
    const skillTree = node.skillTree;
        
        if (skillTree) {
          // ✅ Load nodes if not already loaded
          if (!skillTree.nodes || skillTree.nodes.length === 0) {
            const allNodes = await this.skillNodeRepository.find({
              where: { skillTreeId: skillTree.id },
            });
            skillTree.nodes = allNodes;
          }
          
    const nodeIds = skillTree.nodes.map((n) => n.id);
          const completedCount = nodeIds.length > 0
        ? await this.userProgressRepository.count({
            where: {
              userId,
              skillNodeId: In(nodeIds),
              status: NodeStatus.COMPLETED,
            },
          })
        : 0;
          skillTree.completedNodes = completedCount;
          skillTree.totalXP = (skillTree.totalXP || 0) + (node.rewardXP || 0);
          
          console.log(`📊 Updated skill tree stats: ${completedCount}/${skillTree.totalNodes} nodes completed`);

    if (skillTree.metadata) {
      skillTree.metadata.completionPercentage =
        skillTree.totalNodes > 0
          ? Math.round((skillTree.completedNodes / skillTree.totalNodes) * 100)
          : 0;
      skillTree.metadata.lastUnlockedAt = new Date();
          } else {
            // Initialize metadata if not exists
            // Get placement test level from user or default to beginner
            try {
              const user = await this.usersService.findById(userId);
              const defaultLevel = user?.placementTestLevel || 'beginner';
              
              skillTree.metadata = {
                level: defaultLevel,
                completionPercentage: skillTree.totalNodes > 0
                  ? Math.round((skillTree.completedNodes / skillTree.totalNodes) * 100)
                  : 0,
                lastUnlockedAt: new Date(),
              };
            } catch (userError) {
              console.error(`❌ Error getting user for skill tree metadata:`, userError);
              // Use default level if user lookup fails
              skillTree.metadata = {
                level: 'beginner',
                completionPercentage: skillTree.totalNodes > 0
                  ? Math.round((skillTree.completedNodes / skillTree.totalNodes) * 100)
                  : 0,
                lastUnlockedAt: new Date(),
              };
            }
    }

    await this.skillTreeRepository.save(skillTree);
        }
      } catch (skillTreeError) {
        console.error(`❌ Error updating skill tree stats:`, skillTreeError);
        // Continue even if skill tree update fails
      }

      // ✅ Removed auto-unlock logic - user will unlock next node manually via button
      console.log(`✅ Node ${node.id} completed. Next nodes can be unlocked via unlock button.`);

      return progress;
    } catch (error) {
      console.error(`❌ Error completing skill node ${skillNodeId}:`, error);
      throw error; // Re-throw to let caller handle
    }
  }

  /**
   * Find next unlockable node(s) for a user
   * Returns nodes that can be unlocked based on completed prerequisites
   */
  async getNextUnlockableNodes(
    userId: string,
    skillTreeId: string,
  ): Promise<SkillNode[]> {
    console.log(`🔍 Finding next unlockable nodes for user ${userId}, skillTree ${skillTreeId}`);
    
    // Get all nodes in skill tree
    const allNodes = await this.skillNodeRepository.find({
      where: { skillTreeId },
      order: { order: 'ASC' },
    });

    console.log(`📋 Total nodes in skill tree: ${allNodes.length}`);

    // Get user progress for all nodes
    const nodeIds = allNodes.map((n) => n.id);
    const userProgress =
      nodeIds.length > 0
        ? await this.userProgressRepository.find({
            where: {
              userId,
              skillNodeId: In(nodeIds),
            },
          })
        : [];

    console.log(`📊 User progress count: ${userProgress.length}`);
    console.log(`📊 Completed nodes: ${userProgress.filter(p => p.status === NodeStatus.COMPLETED).map(p => p.skillNodeId).join(', ')}`);

    const progressMap = new Map(
      userProgress.map((p) => [p.skillNodeId, p]),
    );

    // Find nodes that are locked but have all prerequisites completed
    const unlockableNodes: SkillNode[] = [];

    for (const node of allNodes) {
      const progress = progressMap.get(node.id);
      
      // Skip if already unlocked or completed
      if (progress && progress.status !== NodeStatus.LOCKED) {
        console.log(`⏭️  Skipping node ${node.id} (${node.title}): status=${progress.status}`);
        continue;
      }

      // Check if prerequisites are met
      if (node.prerequisites && node.prerequisites.length > 0) {
        // Check each prerequisite individually
        let allPrereqsMet = true;
        const missingPrereqs: string[] = [];
        
        for (const prereqId of node.prerequisites) {
          const prereqProgress = userProgress.find(p => p.skillNodeId === prereqId);
          if (!prereqProgress || prereqProgress.status !== NodeStatus.COMPLETED) {
            allPrereqsMet = false;
            missingPrereqs.push(prereqId);
            console.log(`❌ Prerequisite ${prereqId} not completed. Progress: ${prereqProgress ? prereqProgress.status : 'not found'}`);
          } else {
            console.log(`✅ Prerequisite ${prereqId} completed (status: ${prereqProgress.status})`);
          }
        }

        console.log(`🔍 Node ${node.id} (${node.title}): ${node.prerequisites.length - missingPrereqs.length}/${node.prerequisites.length} prerequisites completed. Missing: ${missingPrereqs.join(', ') || 'none'}`);

        if (allPrereqsMet) {
          unlockableNodes.push(node);
          console.log(`✅ Node ${node.id} (${node.title}) is unlockable! All prerequisites met.`);
        } else {
          console.log(`⏸️  Node ${node.id} (${node.title}) cannot be unlocked yet. Missing ${missingPrereqs.length} prerequisites.`);
        }
      } else {
        // No prerequisites - only unlock if it's the first node (order 1) or if previous nodes are completed
        // For now, allow unlocking root nodes (order 1) or nodes with no prerequisites
        if (!progress || progress.status === NodeStatus.LOCKED) {
          // Additional check: if this is not the first node, make sure previous nodes are completed
          if (node.order === 1) {
            unlockableNodes.push(node);
            console.log(`✅ Node ${node.id} (${node.title}) is unlockable (root node, no prerequisites)!`);
          } else {
            // Check if previous node (order - 1) is completed
            const previousNode = allNodes.find(n => n.order === node.order - 1);
            if (previousNode) {
              const prevProgress = userProgress.find(p => p.skillNodeId === previousNode.id);
              if (prevProgress && prevProgress.status === NodeStatus.COMPLETED) {
                unlockableNodes.push(node);
                console.log(`✅ Node ${node.id} (${node.title}) is unlockable (previous node completed, no prerequisites)!`);
              } else {
                console.log(`⏸️  Node ${node.id} (${node.title}) cannot be unlocked yet. Previous node (order ${previousNode.order}) not completed.`);
              }
            } else {
              // No previous node found, allow unlock
              unlockableNodes.push(node);
              console.log(`✅ Node ${node.id} (${node.title}) is unlockable (no prerequisites, no previous node)!`);
            }
          }
        }
      }
    }

    // Sort by order
    unlockableNodes.sort((a, b) => a.order - b.order);

    console.log(`🎯 Found ${unlockableNodes.length} unlockable nodes: ${unlockableNodes.map(n => `${n.title} (order: ${n.order})`).join(', ')}`);

    return unlockableNodes;
  }

  /**
   * Unlock next available node(s) for a user
   * Unlocks the first unlockable node(s) based on prerequisites
   */
  async unlockNextNode(
    userId: string,
    skillTreeId: string,
  ): Promise<{ unlocked: SkillNode[]; message: string }> {
    const unlockableNodes = await this.getNextUnlockableNodes(
      userId,
      skillTreeId,
    );

    if (unlockableNodes.length === 0) {
      return {
        unlocked: [],
        message: 'Không có node nào có thể mở khóa',
      };
    }

    // Unlock the first unlockable node (or all if they're at the same order level)
    const firstOrder = unlockableNodes[0].order;
    const nodesToUnlock = unlockableNodes.filter((n) => n.order === firstOrder);

    const unlocked: SkillNode[] = [];

    for (const node of nodesToUnlock) {
      try {
        await this.unlockNode(userId, node.id);
        unlocked.push(node);
        console.log(`✅ Unlocked next node: ${node.id} (${node.title})`);
      } catch (error) {
        console.error(`❌ Error unlocking node ${node.id}:`, error);
      }
    }

    if (unlocked.length > 0) {
      return {
        unlocked,
        message: `Đã mở khóa ${unlocked.length} node mới! 🎉`,
      };
    }

    return {
      unlocked: [],
      message: 'Không thể mở khóa node',
    };
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

