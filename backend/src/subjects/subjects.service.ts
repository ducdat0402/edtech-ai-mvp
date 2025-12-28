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
}

