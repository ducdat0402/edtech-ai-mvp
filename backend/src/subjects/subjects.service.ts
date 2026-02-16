import { Injectable, BadRequestException, Inject, forwardRef } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Subject } from './entities/subject.entity';
import { UserProgressService } from '../user-progress/user-progress.service';
import { LearningNodesService } from '../learning-nodes/learning-nodes.service';
import { UserCurrencyService } from '../user-currency/user-currency.service';
import { DomainsService } from '../domains/domains.service';
import { UnlockTransactionsService } from '../unlock-transactions/unlock-transactions.service';

@Injectable()
export class SubjectsService {
  constructor(
    @InjectRepository(Subject)
    private subjectRepository: Repository<Subject>,
    @Inject(forwardRef(() => UserProgressService))
    private progressService: UserProgressService,
    @Inject(forwardRef(() => LearningNodesService))
    private nodesService: LearningNodesService,
    private currencyService: UserCurrencyService,
    @Inject(forwardRef(() => DomainsService))
    private domainsService: DomainsService,
    @Inject(forwardRef(() => UnlockTransactionsService))
    private unlockService: UnlockTransactionsService,
  ) {}

  async findByTrack(track: 'explorer' | 'scholar'): Promise<Subject[]> {
    return this.subjectRepository.find({
      where: { track },
      order: { createdAt: 'ASC' },
    });
  }

  async findAll(): Promise<Subject[]> {
    return this.subjectRepository.find({
      order: { createdAt: 'ASC' },
    });
  }

  async findById(id: string): Promise<Subject | null> {
    return this.subjectRepository.findOne({
      where: { id },
      relations: ['nodes', 'domains'],
    });
  }

  /**
   * Tìm subject theo tên (case-insensitive)
   */
  async findByName(name: string): Promise<Subject | null> {
    const allSubjects = [
      ...(await this.findByTrack('explorer')),
      ...(await this.findByTrack('scholar')),
    ];
    
    return allSubjects.find(
      s => s.name.toLowerCase() === name.toLowerCase()
    ) || null;
  }

  /**
   * Tạo subject mới nếu chưa tồn tại
   */
  async createIfNotExists(
    name: string,
    description?: string,
    track: 'explorer' | 'scholar' = 'explorer',
  ): Promise<Subject> {
    // Check if exists
    const existing = await this.findByName(name);
    if (existing) {
      return existing;
    }

    // Create new subject
    const newSubject = this.subjectRepository.create({
      name: name.charAt(0).toUpperCase() + name.slice(1), // Capitalize first letter
      description: description || `Khóa học về ${name}`,
      track: track,
      metadata: {
        icon: this.getSubjectIcon(name),
        color: this.getSubjectColor(name),
      },
    });

    return await this.subjectRepository.save(newSubject);
  }

  /**
   * Get icon for subject based on name
   */
  private getSubjectIcon(subjectName: string): string {
    const name = subjectName.toLowerCase();
    if (name.includes('piano')) return '🎹';
    if (name.includes('guitar')) return '🎸';
    if (name.includes('violin')) return '🎻';
    if (name.includes('drum')) return '🥁';
    if (name.includes('nhạc') || name.includes('music')) return '🎵';
    if (name.includes('excel')) return '📊';
    if (name.includes('python')) return '🐍';
    if (name.includes('javascript') || name.includes('js')) return '📜';
    if (name.includes('java')) return '☕';
    if (name.includes('web')) return '🌐';
    if (name.includes('vẽ') || name.includes('drawing')) return '🎨';
    if (name.includes('english') || name.includes('tiếng anh')) return '🇬🇧';
    return '📚'; // Default icon
  }

  /**
   * Get color for subject based on name
   */
  private getSubjectColor(subjectName: string): string {
    const name = subjectName.toLowerCase();
    if (name.includes('piano') || name.includes('guitar') || name.includes('violin') || name.includes('drum') || name.includes('nhạc') || name.includes('music')) {
      return '#FF6B6B'; // Red for music
    }
    if (name.includes('excel')) return '#4ECDC4'; // Teal
    if (name.includes('python')) return '#45B7D1'; // Blue
    if (name.includes('javascript') || name.includes('js')) return '#FFA07A'; // Light salmon
    if (name.includes('java')) return '#FF8C00'; // Dark orange
    if (name.includes('web')) return '#98D8C8'; // Mint
    if (name.includes('vẽ') || name.includes('drawing')) return '#F7DC6F'; // Yellow
    if (name.includes('english') || name.includes('tiếng anh')) return '#BB8FCE'; // Purple
    return '#95A5A6'; // Default gray
  }

  /**
   * Update subject fields
   */
  async update(id: string, data: Partial<{ name: string; description: string; track: string; metadata: any }>): Promise<Subject> {
    const subject = await this.findById(id);
    if (!subject) {
      throw new BadRequestException('Subject not found');
    }
    Object.assign(subject, data);
    return this.subjectRepository.save(subject);
  }

  /**
   * Delete a subject
   */
  async delete(id: string): Promise<void> {
    const subject = await this.findById(id);
    if (!subject) {
      throw new BadRequestException('Subject not found');
    }
    await this.subjectRepository.remove(subject);
  }

  // Fog of War: Chỉ hiện nodes đã unlock
  async getAvailableNodesForUser(
    userId: string,
    subjectId: string,
  ): Promise<any[]> {
    const completedNodeIds =
      await this.progressService.getCompletedNodes(userId);
    const availableNodes = await this.nodesService.getAvailableNodes(
      subjectId,
      completedNodeIds,
    );

    return availableNodes.map((node) => ({
      id: node.id,
      title: node.title,
      description: node.description,
      order: node.order,
      metadata: node.metadata,
      // Don't expose prerequisites to client
    }));
  }

  // Check if user can access Scholar subject
  async canAccessScholar(
    userId: string,
    subjectId: string,
  ): Promise<{ canAccess: boolean; reason?: string; requiredCoins?: number }> {
    const subject = await this.findById(subjectId);
    if (!subject || subject.track !== 'scholar') {
      return { canAccess: false, reason: 'Subject not found or not Scholar' };
    }

    const currency = await this.currencyService.getCurrency(userId);
    const requiredCoins = subject.unlockConditions?.minCoin || 20;

    if (currency.coins < requiredCoins) {
      return {
        canAccess: false,
        reason: 'Insufficient coins',
        requiredCoins,
      };
    }

    return { canAccess: true };
  }

  // Get subject with unlock status for user
  async getSubjectForUser(
    userId: string,
    subjectId: string,
  ): Promise<{
    subject: Subject;
    isUnlocked: boolean;
    canUnlock: boolean;
    requiredCoins?: number;
    userCoins?: number;
  }> {
    const subject = await this.findById(subjectId);
    if (!subject) {
      throw new BadRequestException('Subject not found');
    }

    const currency = await this.currencyService.getCurrency(userId);
    const requiredCoins = subject.unlockConditions?.minCoin || 0;

    // Check if already unlocked (có thể lưu vào bảng user_subjects hoặc check progress)
    // Tạm thời check xem có progress nào không
    const nodes = await this.nodesService.findBySubject(subjectId);
    const hasProgress = nodes.length > 0; // Simplified check

    return {
      subject,
      isUnlocked: hasProgress || subject.track === 'explorer', // Explorer luôn mở
      canUnlock: currency.coins >= requiredCoins,
      requiredCoins,
      userCoins: currency.coins,
    };
  }

  // Get subject introduction with knowledge graph and tutorial
  async getSubjectIntro(
    userId: string,
    subjectId: string,
  ): Promise<{
    subject: {
      id: string;
      name: string;
      description: string;
      track: string;
      metadata: any;
      domains?: any[]; // Include domains with topics for frontend
    };
    knowledgeGraph: {
      nodes: Array<{
        id: string;
        title: string;
        position: { x: number; y: number };
        order: number;
        isUnlocked: boolean;
        isCompleted: boolean;
      }>;
      edges: Array<{
        from: string;
        to: string;
      }>;
    };
    tutorialSteps: Array<{
      step: number;
      title: string;
      description: string;
      highlight?: string; // 'explorer' | 'scholar' | 'node' | 'fog'
    }>;
    courseOutline: {
      totalLessons: number;
      totalTopics: number;
      totalDomains: number;
      totalConcepts: number;
      totalExamples: number;
      estimatedDays: number;
    };
  }> {
    const subject = await this.findById(subjectId);
    if (!subject) {
      throw new BadRequestException('Subject not found');
    }

    // Get all nodes and domains for this subject
    const allNodes = await this.nodesService.findBySubject(subjectId);
    const completedNodeIds = await this.progressService.getCompletedNodes(userId);

    // Auto-unlock first topic and get unlocked node IDs
    await this.unlockService.ensureFirstTopicUnlocked(userId, subjectId);
    const unlockedNodeIds = await this.unlockService.getUserUnlockedNodeIds(userId, subjectId);

    // Get domains for this subject
    let domains = [];
    try {
      domains = await this.domainsService.findBySubject(subjectId);
    } catch (e) {
      // domains service might fail if no domains exist
    }

    // Build hierarchical mind map: Subject (level 1) -> Domain (level 2) -> Topic (level 3)
    const graphNodes: Array<any> = [];
    const edges: Array<{ from: string; to: string }> = [];

    // Level 1: Subject node
    const subjectNodeId = `subject-${subjectId}`;
    graphNodes.push({
      id: subjectNodeId,
      title: subject.name,
      level: 1,
      parentId: null,
      position: { x: 400, y: 50 },
      order: 0,
      isUnlocked: true,
      isCompleted: false,
      nodeType: 'subject',
    });

    // Level 2: Domain nodes
    let domainIndex = 0;
    for (const domain of domains) {
      const domainNodeId = `domain-${domain.id}`;
      const xPos = 100 + (domainIndex % 4) * 200;
      const yPos = 200 + Math.floor(domainIndex / 4) * 150;

      graphNodes.push({
        id: domainNodeId,
        title: domain.name,
        level: 2,
        parentId: subjectNodeId,
        position: { x: xPos, y: yPos },
        order: domainIndex,
        isUnlocked: true,
        isCompleted: false,
        nodeType: 'domain',
        entityId: domain.id,
      });

      edges.push({ from: subjectNodeId, to: domainNodeId });

      // Level 3: Topic nodes (from topics table)
      const topics = domain.topics || [];
      let topicIndex = 0;
      let domainAllTopicsCompleted = topics.length > 0;

      for (const topic of topics) {
        const topicNodeId = `topic-${topic.id}`;
        const topicXPos = xPos - 50 + (topicIndex % 3) * 100;
        const topicYPos = yPos + 130 + Math.floor(topicIndex / 3) * 100;

        // Get learning nodes for this topic and calculate completion
        const topicNodes = allNodes.filter((n) => n.topicId === topic.id);
        const topicCompletedNodes = topicNodes.filter((n) =>
          completedNodeIds.includes(n.id),
        );
        const topicIsCompleted =
          topicNodes.length > 0 &&
          topicCompletedNodes.length === topicNodes.length;

        if (!topicIsCompleted) domainAllTopicsCompleted = false;

        // Calculate total rewards for this topic
        const topicTotalXp = topicNodes.reduce(
          (sum, n) => sum + (n.expReward || 0),
          0,
        );
        const topicTotalCoins = topicNodes.reduce(
          (sum, n) => sum + (n.coinReward || 0),
          0,
        );

        graphNodes.push({
          id: topicNodeId,
          title: topic.name,
          level: 3,
          parentId: domainNodeId,
          position: { x: topicXPos, y: topicYPos },
          order: topic.order || topicIndex,
          isUnlocked: true,
          isCompleted: topicIsCompleted,
          nodeType: 'topic',
          entityId: topic.id,
          totalLessons: topicNodes.length,
          completedLessons: topicCompletedNodes.length,
          totalXp: topicTotalXp,
          totalCoins: topicTotalCoins,
          // Include learning nodes under this topic with lock status
          learningNodes: topicNodes.map((n) => ({
            id: n.id,
            title: n.title,
            description: n.description,
            order: n.order,
            isCompleted: completedNodeIds.includes(n.id),
            isLocked: !unlockedNodeIds.has(n.id),
            expReward: n.expReward || 0,
            coinReward: n.coinReward || 0,
          })),
        });

        edges.push({ from: domainNodeId, to: topicNodeId });
        topicIndex++;
      }

      // Update domain completion
      if (domainAllTopicsCompleted && topics.length > 0) {
        const domainNode = graphNodes.find((n) => n.id === domainNodeId);
        if (domainNode) domainNode.isCompleted = true;
      }

      domainIndex++;
    }

    // If no domains, fall back to flat learning nodes display
    if (domains.length === 0 && allNodes.length > 0) {
      allNodes.forEach((node, idx) => {
        const position = node.metadata?.position || {
          x: (idx % 3) * 150 + 100,
          y: Math.floor(idx / 3) * 150 + 200,
        };

        graphNodes.push({
          id: node.id,
          title: node.title,
          level: 2,
          parentId: subjectNodeId,
          position,
          order: node.order || idx,
          isUnlocked: true,
          isCompleted: completedNodeIds.includes(node.id),
          nodeType: 'learning_node',
        });

        edges.push({ from: subjectNodeId, to: node.id });
      });
    }

    // Calculate course outline
    const totalConcepts = allNodes.reduce(
      (sum, node) => sum + (node.contentStructure?.concepts || 0),
      0,
    );
    const totalExamples = allNodes.reduce(
      (sum, node) => sum + (node.contentStructure?.examples || 0),
      0,
    );
    const estimatedDays = subject.metadata?.estimatedDays || 30;

    // Tutorial steps
    const tutorialSteps = [
      {
        step: 1,
        title: 'Chào mừng đến với khóa học!',
        description:
          'Đây là bản đồ kiến thức của bạn. Mỗi điểm là một chủ đề bạn sẽ học.',
        highlight: 'node',
      },
      {
        step: 2,
        title: 'Fog of War - Khám phá từng bước',
        description:
          'Bạn chỉ thấy các chủ đề đã mở khóa. Hoàn thành chủ đề trước để mở khóa chủ đề tiếp theo.',
        highlight: 'fog',
      },
      {
        step: 3,
        title: 'Explorer vs Scholar',
        description:
          subject.track === 'explorer'
            ? 'Bạn đang ở nhánh Explorer - miễn phí và dễ tiếp cận.'
            : 'Bạn đang ở nhánh Scholar - nâng cao và chuyên sâu hơn.',
        highlight: subject.track === 'explorer' ? 'explorer' : 'scholar',
      },
      {
        step: 4,
        title: 'Bắt đầu học tập!',
        description:
          'Chạm vào một chủ đề để bắt đầu. Chúc bạn học tập vui vẻ! 🎉',
        highlight: 'node',
      },
    ];

    // Count total topics across all domains
    const totalTopics = domains.reduce((sum, domain) => {
      return sum + (domain.topics?.length || 0);
    }, 0);

    return {
      subject: {
        id: subject.id,
        name: subject.name,
        description: subject.description || '',
        track: subject.track,
        metadata: subject.metadata || {},
        domains, // Include domains with topics for frontend
      },
      knowledgeGraph: {
        nodes: graphNodes,
        edges,
      },
      tutorialSteps,
      courseOutline: {
        totalLessons: allNodes.length,
        totalTopics,
        totalDomains: domains.length,
        totalConcepts,
        totalExamples,
        estimatedDays,
      },
    };
  }

  /**
   * Generate learning nodes from a topic
   */
  async generateLearningNodesFromTopic(
    subjectId: string,
    topicNodeId: string,
    topicName?: string,
    topicDescription?: string,
  ): Promise<{ success: boolean; message: string; nodesCount?: number; alreadyExists?: boolean }> {
    try {
      // Get subject
      const subject = await this.findById(subjectId);
      if (!subject) {
        throw new BadRequestException('Subject not found');
      }

      // Check if learning nodes already exist for this topic
      const existingNodes = await this.nodesService.findByTopicNodeId(topicNodeId);

      if (existingNodes.length > 0) {
        return {
          success: true,
          message: `Đã có ${existingNodes.length} bài học cho chủ đề "${topicName || topicNodeId}". Đang mở...`,
          nodesCount: existingNodes.length,
          alreadyExists: true,
        };
      }

      // Generate new learning nodes
      const name = topicName || 'Unknown Topic';
      const description = topicDescription || `Bài học về ${name}`;
      const numberOfNodes = 5;

      await this.nodesService.generateNodesFromRawData(
        subjectId,
        name,
        description,
        [name],
        numberOfNodes,
        topicNodeId,
      );

      return {
        success: true,
        message: `Đang tạo ${numberOfNodes} bài học cho chủ đề "${name}"...`,
        nodesCount: numberOfNodes,
        alreadyExists: false,
      };
    } catch (error) {
      console.error('Error generating learning nodes from topic:', error);
      throw new BadRequestException(
        `Failed to generate learning nodes: ${error.message}`,
      );
    }
  }
}

