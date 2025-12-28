import { Injectable, BadRequestException, Inject, forwardRef } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Subject } from './entities/subject.entity';
import { UserProgressService } from '../user-progress/user-progress.service';
import { LearningNodesService } from '../learning-nodes/learning-nodes.service';
import { UserCurrencyService } from '../user-currency/user-currency.service';

@Injectable()
export class SubjectsService {
  constructor(
    @InjectRepository(Subject)
    private subjectRepository: Repository<Subject>,
    @Inject(forwardRef(() => UserProgressService))
    private progressService: UserProgressService,
    private nodesService: LearningNodesService,
    private currencyService: UserCurrencyService,
  ) {}

  async findByTrack(track: 'explorer' | 'scholar'): Promise<Subject[]> {
    return this.subjectRepository.find({
      where: { track },
      order: { createdAt: 'ASC' },
    });
  }

  async findById(id: string): Promise<Subject | null> {
    return this.subjectRepository.findOne({
      where: { id },
      relations: ['nodes'],
    });
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

    // Get all nodes for this subject
    const allNodes = await this.nodesService.findBySubject(subjectId);
    const completedNodeIds = await this.progressService.getCompletedNodes(userId);
    const availableNodes = await this.nodesService.getAvailableNodes(
      subjectId,
      completedNodeIds,
    );

    // Build knowledge graph nodes
    const graphNodes = allNodes.map((node) => {
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
    const edges: Array<{ from: string; to: string }> = [];
    allNodes.forEach((node) => {
      if (node.prerequisites && node.prerequisites.length > 0) {
        node.prerequisites.forEach((prereqId) => {
          edges.push({ from: prereqId, to: node.id });
        });
      }
    });

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
}

