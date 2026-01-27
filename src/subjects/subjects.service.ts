import { Injectable, BadRequestException, Inject, forwardRef } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Subject } from './entities/subject.entity';
import { UserProgressService } from '../user-progress/user-progress.service';
import { LearningNodesService } from '../learning-nodes/learning-nodes.service';
import { UserCurrencyService } from '../user-currency/user-currency.service';
import { KnowledgeGraphService } from '../knowledge-graph/knowledge-graph.service';
import { KnowledgeNode, NodeType } from '../knowledge-graph/entities/knowledge-node.entity';
import { EdgeType } from '../knowledge-graph/entities/knowledge-edge.entity';
import { AiService } from '../ai/ai.service';
import { GenerationProgressService } from '../learning-nodes/generation-progress.service';

@Injectable()
export class SubjectsService {
  constructor(
    @InjectRepository(Subject)
    private subjectRepository: Repository<Subject>,
    @Inject(forwardRef(() => UserProgressService))
    private progressService: UserProgressService,
    private nodesService: LearningNodesService,
    private currencyService: UserCurrencyService,
    @Inject(forwardRef(() => KnowledgeGraphService))
    private knowledgeGraphService: KnowledgeGraphService,
    private generationProgressService: GenerationProgressService,
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
      totalNodes: number;
      totalConcepts: number;
      totalExamples: number;
      estimatedDays: number;
    };
  }> {
    const subject = await this.findById(subjectId);
    if (!subject) {
      throw new BadRequestException('Subject not found');
    }

    // Try to get mind map from knowledge graph first
    let mindMapNodes: any[] = [];
    let mindMapEdges: any[] = [];
    
    try {
      const mindMap = await this.knowledgeGraphService.getMindMapForSubject(subjectId);
      
      if (mindMap.nodes.length > 0) {
        // Separate nodes by type/level
        const subjectNode = mindMap.nodes.find(n => 
          n.type === NodeType.SUBJECT || n.name === subject.name
        );
        const domainNodes = mindMap.nodes.filter(n => 
          n.type === NodeType.DOMAIN || (n.metadata as any)?.originalType === 'domain'
        );
        const topicNodes = mindMap.nodes.filter(n => 
          n.type === NodeType.CONCEPT || 
          n.type === NodeType.LEARNING_NODE ||
          (n.metadata as any)?.originalType === 'topic' || 
          (n.metadata as any)?.originalType === 'concept'
        );

        // Canvas size: 1200x1200
        const centerX = 600;
        const centerY = 600;

        // Build mind map structure with 3-layer hierarchy
        const nodesWithLevel: any[] = [];

        // Lớp 1: Subject ở giữa
        if (subjectNode) {
          nodesWithLevel.push({
            id: subjectNode.id,
            title: subjectNode.name,
            position: { x: centerX, y: centerY },
            order: 0,
            level: 1,
            type: 'subject',
            isUnlocked: true,
            isCompleted: false,
          });
        }

        // Lớp 2: Domains xung quanh subject (vòng tròn bán kính 200-250)
        domainNodes.forEach((domain, index) => {
          const angle = (index / domainNodes.length) * 2 * Math.PI;
          const radius = 200 + (domainNodes.length > 6 ? 50 : 0); // Tăng radius nếu có nhiều domains
          nodesWithLevel.push({
            id: domain.id,
            title: domain.name,
            position: {
              x: centerX + radius * Math.cos(angle),
              y: centerY + radius * Math.sin(angle),
            },
            order: index + 1,
            level: 2,
            type: 'domain',
            parentId: subjectNode?.id,
            isUnlocked: true,
            isCompleted: false,
          });
        });

        // Lớp 3: Topics xung quanh domain cha (vòng tròn bán kính 250-350, tùy thuộc vào domain)
        // Group topics by domain
        const topicsByDomain = new Map<string, typeof topicNodes>();
        topicNodes.forEach(topic => {
          // Tìm domain cha của topic này thông qua edges
          // Edge type 'part_of' nghĩa là topic là phần của domain, vậy fromNodeId là domain, toNodeId là topic
          const domainEdge = mindMap.edges.find(e => 
            e.toNodeId === topic.id && e.type === EdgeType.PART_OF
          );
          if (domainEdge) {
            const domainId = domainEdge.fromNodeId;
            if (!topicsByDomain.has(domainId)) {
              topicsByDomain.set(domainId, []);
            }
            topicsByDomain.get(domainId)!.push(topic);
          } else {
            // Nếu không tìm thấy domain cha, gán vào domain đầu tiên
            if (domainNodes.length > 0) {
              const firstDomainId = domainNodes[0].id;
              if (!topicsByDomain.has(firstDomainId)) {
                topicsByDomain.set(firstDomainId, []);
              }
              topicsByDomain.get(firstDomainId)!.push(topic);
            }
          }
        });

        // Đặt topics xung quanh domain cha
        domainNodes.forEach((domain, domainIndex) => {
          const domainTopics = topicsByDomain.get(domain.id) || [];
          const domainAngle = (domainIndex / domainNodes.length) * 2 * Math.PI;
          const domainRadius = 200 + (domainNodes.length > 6 ? 50 : 0);
          const domainX = centerX + domainRadius * Math.cos(domainAngle);
          const domainY = centerY + domainRadius * Math.sin(domainAngle);
          
          domainTopics.forEach((topic, topicIndex) => {
            // Tính góc xoay quanh domain
            const topicAngle = (topicIndex / domainTopics.length) * 2 * Math.PI;
            const topicRadius = 120 + (domainTopics.length > 5 ? 30 : 0); // Tăng radius nếu có nhiều topics
            const finalAngle = domainAngle + (topicAngle - Math.PI / 2); // Xoay 90 độ
            
            nodesWithLevel.push({
              id: topic.id,
              title: topic.name,
              position: {
                x: domainX + topicRadius * Math.cos(finalAngle),
                y: domainY + topicRadius * Math.sin(finalAngle),
              },
              order: (domainIndex + 1) * 100 + topicIndex,
              level: 3,
              type: 'topic',
              parentId: domain.id,
              isUnlocked: true,
              isCompleted: false,
            });
          });
        });

        // Nếu có topics không có domain cha, đặt chúng ở vòng ngoài
        const orphanTopics = topicNodes.filter(topic => {
          const hasDomainEdge = mindMap.edges.some(e => 
            e.toNodeId === topic.id && e.type === EdgeType.PART_OF
          );
          return !hasDomainEdge;
        });

        orphanTopics.forEach((topic, index) => {
          const angle = (index / Math.max(orphanTopics.length, 1)) * 2 * Math.PI;
          const radius = 400; // Vòng ngoài cùng cho orphan topics
          nodesWithLevel.push({
            id: topic.id,
            title: topic.name,
            position: {
              x: centerX + radius * Math.cos(angle),
              y: centerY + radius * Math.sin(angle),
            },
            order: 10000 + index,
            level: 3,
            type: 'topic',
            isUnlocked: true,
            isCompleted: false,
          });
        });

        mindMapNodes = nodesWithLevel;
        mindMapEdges = mindMap.edges.map(edge => ({
          from: edge.fromNodeId,
          to: edge.toNodeId,
        }));
      }
    } catch (error) {
      // If knowledge graph doesn't have mind map, fallback to learning nodes
      console.warn('Could not load mind map from knowledge graph, using learning nodes:', error);
    }

    // Get all nodes for this subject (for fallback or course outline)
    const allNodes = await this.nodesService.findBySubject(subjectId);
    const completedNodeIds = await this.progressService.getCompletedNodes(userId);
    const availableNodes = await this.nodesService.getAvailableNodes(
      subjectId,
      completedNodeIds,
    );

    // Use mind map if available, otherwise use learning nodes
    let graphNodes: any[];
    let edges: Array<{ from: string; to: string }>;

    if (mindMapNodes.length > 0) {
      // Use mind map from knowledge graph
      graphNodes = mindMapNodes;
      edges = mindMapEdges;
    } else {
      // Fallback: Build knowledge graph nodes from learning nodes
      graphNodes = allNodes.map((node) => {
        const position = node.metadata?.position || {
          x: (node.order % 3) * 150 + 100,
          y: Math.floor(node.order / 3) * 150 + 100,
        };

        return {
          id: node.id,
          title: node.title,
          position,
          order: node.order,
          isUnlocked: availableNodes.some((n) => n.id === node.id),
          isCompleted: completedNodeIds.includes(node.id),
        };
      });

      // Build edges from prerequisites
      edges = [];
      allNodes.forEach((node) => {
        if (node.prerequisites && node.prerequisites.length > 0) {
          node.prerequisites.forEach((prereqId) => {
            edges.push({ from: prereqId, to: node.id });
          });
        }
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

    return {
      subject: {
        id: subject.id,
        name: subject.name,
        description: subject.description || '',
        track: subject.track,
        metadata: subject.metadata || {},
      },
      knowledgeGraph: {
        nodes: graphNodes,
        edges,
      },
      tutorialSteps,
      courseOutline: {
        totalNodes: allNodes.length,
        totalConcepts,
        totalExamples,
        estimatedDays,
      },
    };
  }

  /**
   * Generate learning nodes from knowledge graph topic node
   */
  async generateLearningNodesFromTopic(
    subjectId: string,
    topicNodeId: string,
  ): Promise<{ success: boolean; message: string; nodesCount?: number; alreadyExists?: boolean; taskId?: string }> {
    try {
      // Get knowledge graph topic node
      const topicNode = await this.knowledgeGraphService.getNodeById(topicNodeId);

      if (!topicNode) {
        throw new BadRequestException('Topic node not found');
      }

      // Get subject
      const subject = await this.findById(subjectId);
      if (!subject) {
        throw new BadRequestException('Subject not found');
      }

      // Kiểm tra xem đã có learning nodes nào được tạo từ topic này chưa
      const existingNodes = await this.nodesService.findByTopicNodeId(topicNodeId);
      
      if (existingNodes.length > 0) {
        // Đã có nodes rồi, không tạo lại
        return {
          success: true,
          message: `Đã có ${existingNodes.length} bài học cho chủ đề "${topicNode.name}". Đang mở...`,
          nodesCount: existingNodes.length,
          alreadyExists: true,
        };
      }

      // Chưa có, tạo mới với progress tracking
      const topicName = topicNode.name;
      const topicDescription = topicNode.description || `Bài học về ${topicName}`;
      const numberOfNodes = 5; // Generate 5 learning nodes for each topic

      // Generate taskId
      const taskId = `task_${subjectId}_${topicNodeId}_${Date.now()}`;
      
      // Initialize progress
      this.generationProgressService.createTask(taskId, numberOfNodes);
      
      // Generate learning nodes in background (don't await)
      this.nodesService.generateNodesFromRawData(
        subjectId,
        topicName,
        topicDescription,
        [topicName], // Use topic name as the topic/chapter
        numberOfNodes,
        topicNodeId, // Pass topicNodeId để lưu vào metadata
        taskId, // Pass taskId để track progress
      ).catch((error) => {
        console.error('Error generating learning nodes in background:', error);
        this.generationProgressService.updateProgress(taskId, {
          status: 'error',
          error: error.message,
        });
      });

      return {
        success: true,
        message: `Đang tạo ${numberOfNodes} bài học cho chủ đề "${topicName}"...`,
        nodesCount: numberOfNodes,
        alreadyExists: false,
        taskId,
      };
    } catch (error) {
      console.error('Error generating learning nodes from topic:', error);
      throw new BadRequestException(
        `Failed to generate learning nodes: ${error.message}`,
      );
    }
  }
}

