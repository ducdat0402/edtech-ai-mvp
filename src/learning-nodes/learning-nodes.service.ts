import { Injectable, Inject, forwardRef } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { LearningNode } from './entities/learning-node.entity';
import { AiService } from '../ai/ai.service';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { DomainsService } from '../domains/domains.service';
import { GenerationProgressService } from './generation-progress.service';
import { UserPremium } from '../payment/entities/user-premium.entity';

// Number of free nodes before requiring premium
const FREE_NODES_LIMIT = 2;

@Injectable()
export class LearningNodesService {
  constructor(
    @InjectRepository(LearningNode)
    private nodeRepository: Repository<LearningNode>,
    @InjectRepository(ContentItem)
    private contentItemRepository: Repository<ContentItem>,
    @InjectRepository(UserPremium)
    private userPremiumRepository: Repository<UserPremium>,
    private aiService: AiService,
    @Inject(forwardRef(() => DomainsService))
    private domainsService: DomainsService,
    private progressService: GenerationProgressService,
  ) {}

  async findBySubject(subjectId: string): Promise<LearningNode[]> {
    return this.nodeRepository.find({
      where: { subjectId },
      order: { order: 'ASC' },
    });
  }

  /**
   * Check if user has active premium
   */
  private async checkUserPremium(userId: string): Promise<boolean> {
    if (!userId) return false;
    
    const userPremium = await this.userPremiumRepository.findOne({
      where: { userId },
    });

    if (!userPremium) return false;

    const now = new Date();
    return userPremium.isPremium && userPremium.premiumExpiresAt > now;
  }

  /**
   * Get learning nodes with premium lock status
   * First 2 nodes are free, rest require premium
   */
  async findBySubjectWithPremiumStatus(
    subjectId: string,
    userId?: string,
  ): Promise<(LearningNode & { isLocked: boolean; requiresPremium: boolean })[]> {
    const nodes = await this.nodeRepository.find({
      where: { subjectId },
      order: { order: 'ASC' },
    });

    const isPremium = userId ? await this.checkUserPremium(userId) : false;

    return nodes.map((node, index) => ({
      ...node,
      isLocked: !isPremium && index >= FREE_NODES_LIMIT,
      requiresPremium: index >= FREE_NODES_LIMIT,
    }));
  }

  /**
   * Get learning nodes by domain with premium lock status
   */
  async findByDomainWithPremiumStatus(
    domainId: string,
    userId?: string,
  ): Promise<(LearningNode & { isLocked: boolean; requiresPremium: boolean })[]> {
    const nodes = await this.nodeRepository.find({
      where: { domainId },
      order: { order: 'ASC' },
    });

    const isPremium = userId ? await this.checkUserPremium(userId) : false;

    return nodes.map((node, index) => ({
      ...node,
      isLocked: !isPremium && index >= FREE_NODES_LIMIT,
      requiresPremium: index >= FREE_NODES_LIMIT,
    }));
  }

  /**
   * Check if user can access a specific node
   */
  async canAccessNode(nodeId: string, userId?: string): Promise<{ canAccess: boolean; requiresPremium: boolean }> {
    // Find the node and its position in the subject
    const node = await this.nodeRepository.findOne({ where: { id: nodeId } });
    if (!node) {
      return { canAccess: false, requiresPremium: false };
    }

    // Get all nodes in the same subject to determine position
    const allNodes = await this.nodeRepository.find({
      where: { subjectId: node.subjectId },
      order: { order: 'ASC' },
    });

    const nodeIndex = allNodes.findIndex(n => n.id === nodeId);
    
    // First 2 nodes are always accessible
    if (nodeIndex < FREE_NODES_LIMIT) {
      return { canAccess: true, requiresPremium: false };
    }

    // Check premium for other nodes
    const isPremium = userId ? await this.checkUserPremium(userId) : false;
    
    return {
      canAccess: isPremium,
      requiresPremium: true,
    };
  }

  /**
   * Lấy tất cả nodes của một domain
   */
  async findByDomain(domainId: string): Promise<LearningNode[]> {
    return this.nodeRepository.find({
      where: { domainId },
      order: { order: 'ASC' },
    });
  }

  async findById(id: string): Promise<LearningNode | null> {
    return this.nodeRepository.findOne({
      where: { id },
      relations: ['subject', 'contentItems'],
    });
  }

  /**
   * Tạo Learning Node mới (Admin only)
   */
  async createNode(data: {
    subjectId: string;
    domainId?: string;
    title: string;
    description?: string;
    order?: number;
    type?: 'theory' | 'practice' | 'assessment';
    difficulty?: 'easy' | 'medium' | 'hard';
    prerequisites?: string[];
    metadata?: { icon?: string; position?: { x: number; y: number } };
  }): Promise<LearningNode> {
    // Get the next order if not provided
    let order = data.order;
    if (order === undefined) {
      const existingNodes = await this.nodeRepository.find({
        where: { subjectId: data.subjectId },
        order: { order: 'DESC' },
        take: 1,
      });
      order = existingNodes.length > 0 ? (existingNodes[0].order || 0) + 1 : 1;
    }

    const node = this.nodeRepository.create({
      subjectId: data.subjectId,
      domainId: data.domainId || null,
      title: data.title,
      description: data.description || '',
      order,
      type: data.type || 'theory',
      difficulty: data.difficulty || 'medium',
      prerequisites: data.prerequisites || [],
      metadata: data.metadata || {},
      contentStructure: {
        concepts: 0,
        examples: 0,
        hiddenRewards: 0,
        bossQuiz: 0,
      },
    });

    return this.nodeRepository.save(node);
  }

  /**
   * Xóa Learning Node và tất cả content items thuộc node (Admin only)
   */
  async deleteNode(id: string): Promise<void> {
    // First delete all content items belonging to this node
    await this.contentItemRepository.delete({ nodeId: id });
    
    // Then delete the node
    await this.nodeRepository.delete(id);
  }

  /**
   * Tìm learning nodes theo topicNodeId (lưu trong metadata)
   */
  async findByTopicNodeId(topicNodeId: string): Promise<LearningNode[]> {
    // Query learning nodes where metadata->topicNodeId = topicNodeId
    return this.nodeRepository
      .createQueryBuilder('node')
      .where("node.metadata->>'topicNodeId' = :topicNodeId", { topicNodeId })
      .orderBy('node.order', 'ASC')
      .getMany();
  }

  async getAvailableNodes(
    subjectId: string,
    completedNodeIds: string[],
  ): Promise<LearningNode[]> {
    const allNodes = await this.findBySubject(subjectId);

    return allNodes.filter((node) => {
      // Root node (no prerequisites) is always available
      if (!node.prerequisites || node.prerequisites.length === 0) {
        return true;
      }

      // Check if all prerequisites are completed
      return node.prerequisites.every((prereqId) =>
        completedNodeIds.includes(prereqId),
      );
    });
  }

  /**
   * Tự động tạo Learning Nodes từ dữ liệu thô
   * Chỉ cần cung cấp: subject name, description, hoặc topics
   */
  async generateNodesFromRawData(
    subjectId: string,
    subjectName: string,
    subjectDescription?: string,
    topicsOrChapters?: string[],
    numberOfNodes: number = 10,
    topicNodeId?: string, // Optional: ID của topic node trong knowledge graph
    taskId?: string, // Optional: Task ID để track progress
  ): Promise<LearningNode[]> {
    console.log(`🤖 Generating ${numberOfNodes} Learning Nodes for "${subjectName}" using AI...`);
    
    if (taskId) {
      this.progressService.updateProgress(taskId, {
        status: 'generating',
        progress: 5,
        currentStep: 'Đang khởi tạo...',
      });
    }

    // 1. AI generate structure
    if (taskId) {
      this.progressService.updateProgress(taskId, {
        progress: 15,
        currentStep: 'Đang tạo cấu trúc bài học với AI...',
      });
    }
    
    const nodesStructure = await this.aiService.generateLearningNodesStructure(
      subjectName,
      subjectDescription,
      topicsOrChapters,
      numberOfNodes,
    );

    if (taskId) {
      this.progressService.updateProgress(taskId, {
        progress: 30,
        currentStep: `Đang tạo ${nodesStructure.length} bài học...`,
      });
    }

    // 2. Tạo Learning Nodes và Content Items
    const savedNodes: LearningNode[] = [];
    const domainCache = new Map<string, string>(); // Cache domain name -> domainId

    for (let nodeIndex = 0; nodeIndex < nodesStructure.length; nodeIndex++) {
      const nodeData = nodesStructure[nodeIndex];
      
      if (taskId) {
        // Update progress: 30% + (nodeIndex / totalNodes) * 70%
        const progress = 30 + Math.floor((nodeIndex / nodesStructure.length) * 70);
        this.progressService.updateProgress(taskId, {
          progress,
          currentStep: `Đang tạo bài học ${nodeIndex + 1}/${nodesStructure.length}: ${nodeData.title}`,
          completedNodes: nodeIndex,
        });
      }
      // Tìm hoặc tạo domain cho node này
      let domainId: string | null = null;
      const domainName = nodeData.domain || 'Chương chung';
      
      if (domainCache.has(domainName)) {
        // Sử dụng domain đã tạo trước đó
        domainId = domainCache.get(domainName)!;
      } else {
        // Tìm domain theo tên trong subject này
        const existingDomains = await this.domainsService.findBySubject(subjectId);
        const existingDomain = existingDomains.find(
          d => d.name.toLowerCase().trim() === domainName.toLowerCase().trim()
        );

        if (existingDomain) {
          // Domain đã tồn tại
          domainId = existingDomain.id;
          domainCache.set(domainName, domainId);
          console.log(`📚 Found existing domain: "${domainName}"`);
        } else {
          // Tạo domain mới
          try {
            const newDomain = await this.domainsService.create(subjectId, {
              name: domainName,
              description: `Chương học về ${domainName}`,
            });
            domainId = newDomain.id;
            domainCache.set(domainName, domainId);
            console.log(`✨ Created new domain: "${domainName}"`);
          } catch (error) {
            console.error(`⚠️ Failed to create domain "${domainName}":`, error);
            // Tiếp tục tạo node mà không có domain
          }
        }
      }

      // Tạo Learning Node
      // Map type cũ sang type mới: video/image -> theory (vì logic mới không còn type riêng cho video/image)
      const nodeType: 'theory' | 'practice' | 'assessment' = 'theory';
      
      const node = this.nodeRepository.create({
        subjectId,
        domainId,
        title: nodeData.title,
        description: nodeData.description,
        order: nodeData.order,
        prerequisites: [], // Sẽ cập nhật sau
        type: nodeType, // Phân loại: theory, practice, hoặc assessment
        difficulty: nodeData.difficulty || 'medium', // Độ khó: easy, medium, hoặc hard
        contentStructure: {
          concepts: nodeData.concepts.length,
          examples: nodeData.examples?.length || 0,
          hiddenRewards: nodeData.hiddenRewards && nodeData.hiddenRewards.length > 0 ? 1 : 0, // CHỈ 1 phần thưởng
          bossQuiz: 1,
        },
        metadata: {
          icon: nodeData.icon,
          position: { x: (nodeData.order - 1) * 100, y: 0 },
          ...(topicNodeId && { topicNodeId }), // Lưu topicNodeId nếu có
        },
      });

      const savedNode = await this.nodeRepository.save(node);
      savedNodes.push(savedNode);

      // Cập nhật prerequisites: node sau phụ thuộc node trước
      if (savedNodes.length > 1) {
        const prevNode = savedNodes[savedNodes.length - 2];
        savedNode.prerequisites = [prevNode.id];
        await this.nodeRepository.save(savedNode);
      }

      // Tạo Concepts
      for (let i = 0; i < nodeData.concepts.length; i++) {
        const concept = this.contentItemRepository.create({
          nodeId: savedNode.id,
          type: 'concept',
          title: nodeData.concepts[i].title,
          content: nodeData.concepts[i].content,
          order: i + 1,
          rewards: { xp: 10, coin: 1 },
        });
        await this.contentItemRepository.save(concept);
      }

      // Tạo Examples (AI đã tạo sẵn)
      if (nodeData.examples && nodeData.examples.length > 0) {
        for (let i = 0; i < nodeData.examples.length; i++) {
          const example = this.contentItemRepository.create({
            nodeId: savedNode.id,
            type: 'example',
            title: nodeData.examples[i].title,
            content: nodeData.examples[i].content,
            order: i + 1,
            rewards: { xp: 15, coin: 2 },
          });
          await this.contentItemRepository.save(example);
        }
      }

      // Tạo Hidden Reward (CHỈ 1 phần thưởng)
      if (nodeData.hiddenRewards && nodeData.hiddenRewards.length > 0) {
        // Chỉ lấy phần thưởng đầu tiên
        const reward = this.contentItemRepository.create({
          nodeId: savedNode.id,
          type: 'hidden_reward',
          title: nodeData.hiddenRewards[0].title,
          content: nodeData.hiddenRewards[0].content,
          order: 50, // Sau examples, trước boss quiz
          rewards: { xp: 5, coin: 5 },
        });
        await this.contentItemRepository.save(reward);
      }

      // Tạo Boss Quiz (AI đã tạo sẵn với nội dung chất lượng)
      const bossQuiz = this.contentItemRepository.create({
        nodeId: savedNode.id,
        type: 'boss_quiz',
        title: `Boss Quiz: ${nodeData.title}`,
        content: `Kiểm tra kiến thức về ${nodeData.title}`,
        order: 100,
        quizData: {
          question: nodeData.bossQuiz.question,
          options: nodeData.bossQuiz.options,
          correctAnswer: nodeData.bossQuiz.correctAnswer,
          explanation: nodeData.bossQuiz.explanation,
        },
        rewards: { xp: 50, coin: 10 },
      });
      await this.contentItemRepository.save(bossQuiz);

      const totalItems = nodeData.concepts.length + 
                        (nodeData.examples?.length || 0) + 
                        (nodeData.hiddenRewards?.length || 0) + 
                        1; // boss quiz
      const domainInfo = domainId ? ` [Domain: ${domainName}]` : '';
      const rewardCount = nodeData.hiddenRewards && nodeData.hiddenRewards.length > 0 ? 1 : 0; // CHỈ 1 phần thưởng
      console.log(`✅ Created node: ${nodeData.title}${domainInfo} (${nodeData.concepts.length} concepts, ${nodeData.examples?.length || 0} examples, ${rewardCount} reward, 1 quiz)`);
    }

    const domainsCreated = domainCache.size;
    console.log(`\n✅ Successfully generated ${savedNodes.length} Learning Nodes with AI!`);
    console.log(`📚 Organized into ${domainsCreated} domain(s): ${Array.from(domainCache.keys()).join(', ')}`);
    
    if (taskId) {
      this.progressService.updateProgress(taskId, {
        status: 'completed',
        progress: 100,
        currentStep: 'Hoàn thành!',
        completedNodes: savedNodes.length,
      });
    }
    
    return savedNodes;
  }

  /**
   * Generate a single learning node from a topic (one at a time for better quality)
   */
  async generateSingleLearningNodeFromTopic(
    subjectId: string,
    topicNodeId: string,
    topicName: string,
    topicDescription: string,
    subjectName: string,
    subjectDescription?: string,
    domainName?: string,
    order: number = 1,
    taskId?: string,
  ): Promise<LearningNode> {
    // Generate single node with focused prompt
    const nodeData = await this.aiService.generateSingleLearningNode(
      topicName,
      topicDescription,
      subjectName,
      subjectDescription,
      domainName,
      order,
    );

    // Find or create domain
    let domainId: string | null = null;
    const domainNameFinal = nodeData.domain || domainName || 'Chương chung';
    
    if (domainNameFinal !== 'Chương chung') {
      const existingDomains = await this.domainsService.findBySubject(subjectId);
      const existingDomain = existingDomains.find(
        d => d.name.toLowerCase().trim() === domainNameFinal.toLowerCase().trim()
      );

      if (existingDomain) {
        domainId = existingDomain.id;
      } else {
        try {
          const newDomain = await this.domainsService.create(subjectId, {
            name: domainNameFinal,
            description: `Chương học về ${domainNameFinal}`,
          });
          domainId = newDomain.id;
        } catch (error) {
          console.error(`⚠️ Failed to create domain "${domainNameFinal}":`, error);
        }
      }
    }

    // Create Learning Node
    // Map type cũ sang type mới
    const nodeType: 'theory' | 'practice' | 'assessment' = 'theory';
    
    const node = this.nodeRepository.create({
      subjectId,
      domainId,
      title: nodeData.title,
      description: nodeData.description,
      order: nodeData.order,
      prerequisites: [],
      type: nodeType,
      difficulty: nodeData.difficulty,
      contentStructure: {
        concepts: nodeData.concepts.length,
        examples: nodeData.examples?.length || 0,
        hiddenRewards: nodeData.hiddenRewards && nodeData.hiddenRewards.length > 0 ? 1 : 0, // CHỈ 1 phần thưởng
        bossQuiz: 1,
      },
      metadata: {
        icon: nodeData.icon,
        position: { x: (nodeData.order - 1) * 100, y: 0 },
        ...(topicNodeId && { topicNodeId }), // Lưu topicNodeId nếu có
      },
    });

    const savedNode = await this.nodeRepository.save(node);

    // Create Concepts
    for (let i = 0; i < nodeData.concepts.length; i++) {
      const concept = this.contentItemRepository.create({
        nodeId: savedNode.id,
        type: 'concept',
        title: nodeData.concepts[i].title,
        content: nodeData.concepts[i].content,
        order: i + 1,
        rewards: { xp: 10, coin: 1 },
      });
      await this.contentItemRepository.save(concept);
    }

    // Create Examples
    if (nodeData.examples && nodeData.examples.length > 0) {
      for (let i = 0; i < nodeData.examples.length; i++) {
        const example = this.contentItemRepository.create({
          nodeId: savedNode.id,
          type: 'example',
          title: nodeData.examples[i].title,
          content: nodeData.examples[i].content,
          order: i + 1,
          rewards: { xp: 15, coin: 2 },
        });
        await this.contentItemRepository.save(example);
      }
    }

    // Create Hidden Reward (CHỈ 1 phần thưởng)
    if (nodeData.hiddenRewards && nodeData.hiddenRewards.length > 0) {
      // Chỉ lấy phần thưởng đầu tiên
      const reward = this.contentItemRepository.create({
        nodeId: savedNode.id,
        type: 'hidden_reward',
        title: nodeData.hiddenRewards[0].title,
        content: nodeData.hiddenRewards[0].content,
        order: 50, // Sau examples, trước boss quiz
        rewards: { xp: 5, coin: 5 },
      });
      await this.contentItemRepository.save(reward);
    }

    // Create Boss Quiz
    const bossQuiz = this.contentItemRepository.create({
      nodeId: savedNode.id,
      type: 'boss_quiz',
      title: `Boss Quiz: ${nodeData.title}`,
      content: `Kiểm tra kiến thức về ${nodeData.title}`,
      order: 100,
      quizData: {
        question: nodeData.bossQuiz.question,
        options: nodeData.bossQuiz.options,
        correctAnswer: nodeData.bossQuiz.correctAnswer,
        explanation: nodeData.bossQuiz.explanation,
      },
      rewards: { xp: 50, coin: 10 },
    });
    await this.contentItemRepository.save(bossQuiz);

    console.log(`✅ Created single node: ${nodeData.title} (${nodeData.concepts.length} concepts, ${nodeData.examples?.length || 0} examples)`);
    return savedNode;
  }
}

