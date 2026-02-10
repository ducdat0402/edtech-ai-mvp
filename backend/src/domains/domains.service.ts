import { Injectable, NotFoundException, BadRequestException, Inject, forwardRef } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Domain } from './entities/domain.entity';
import { SubjectsService } from '../subjects/subjects.service';
import { LearningNodesService } from '../learning-nodes/learning-nodes.service';

@Injectable()
export class DomainsService {
  constructor(
    @InjectRepository(Domain)
    private domainRepository: Repository<Domain>,
    @Inject(forwardRef(() => SubjectsService))
    private subjectsService: SubjectsService,
    @Inject(forwardRef(() => LearningNodesService))
    private nodesService: LearningNodesService,
  ) {}

  /**
   * Lấy tất cả domains trong database
   */
  async findAll(): Promise<Domain[]> {
    return this.domainRepository.find({
      order: { order: 'ASC' },
      relations: ['nodes', 'subject'],
    });
  }

  /**
   * Lấy tất cả domains của một subject
   */
  async findBySubject(subjectId: string): Promise<Domain[]> {
    return this.domainRepository.find({
      where: { subjectId },
      order: { order: 'ASC' },
      relations: ['topics', 'nodes'],
    });
  }

  /**
   * Lấy domain theo ID
   */
  async findById(id: string): Promise<Domain | null> {
    return this.domainRepository.findOne({
      where: { id },
      relations: ['subject', 'topics', 'nodes'],
    });
  }

  /**
   * Tạo domain mới
   */
  async create(
    subjectId: string,
    data: {
      name: string;
      description?: string;
      order?: number;
      difficulty?: 'easy' | 'medium' | 'hard';
      expReward?: number;
      coinReward?: number;
      metadata?: {
        icon?: string;
        color?: string;
        estimatedDays?: number;
        topics?: string[];
      };
    },
  ): Promise<Domain> {
    // Verify subject exists
    const subject = await this.subjectsService.findById(subjectId);
    if (!subject) {
      throw new NotFoundException(`Subject ${subjectId} not found`);
    }

    // Get max order if not provided
    let order = data.order;
    if (order === undefined) {
      const existingDomains = await this.findBySubject(subjectId);
      order = existingDomains.length > 0 
        ? Math.max(...existingDomains.map(d => d.order)) + 1 
        : 0;
    }

    const domain = this.domainRepository.create({
      subjectId,
      name: data.name,
      description: data.description,
      order,
      difficulty: data.difficulty || 'medium',
      expReward: data.expReward || 0,
      coinReward: data.coinReward || 0,
      metadata: data.metadata || {},
    });

    return await this.domainRepository.save(domain);
  }

  /**
   * Cập nhật domain
   */
  async update(
    id: string,
    data: {
      name?: string;
      description?: string;
      order?: number;
      difficulty?: 'easy' | 'medium' | 'hard';
      expReward?: number;
      coinReward?: number;
      metadata?: any;
    },
  ): Promise<Domain> {
    const domain = await this.findById(id);
    if (!domain) {
      throw new NotFoundException(`Domain ${id} not found`);
    }

    if (data.name !== undefined) domain.name = data.name;
    if (data.description !== undefined) domain.description = data.description;
    if (data.order !== undefined) domain.order = data.order;
    if (data.difficulty !== undefined) domain.difficulty = data.difficulty;
    if (data.expReward !== undefined) domain.expReward = data.expReward;
    if (data.coinReward !== undefined) domain.coinReward = data.coinReward;
    if (data.metadata !== undefined) domain.metadata = { ...domain.metadata, ...data.metadata };

    return await this.domainRepository.save(domain);
  }

  /**
   * Xóa domain (chỉ khi không có nodes)
   */
  async delete(id: string): Promise<void> {
    const domain = await this.findById(id);
    if (!domain) {
      throw new NotFoundException(`Domain ${id} not found`);
    }

    // Check if domain has nodes
    const nodes = await this.nodesService.findByDomain(id);
    if (nodes.length > 0) {
      throw new BadRequestException(
        `Cannot delete domain with ${nodes.length} nodes. Please move or delete nodes first.`,
      );
    }

    await this.domainRepository.remove(domain);
  }

  /**
   * Lấy domains với thông tin progress của user
   */
  async findBySubjectWithProgress(
    subjectId: string,
    userId: string,
  ): Promise<(Domain & { progress?: { completed: number; total: number } })[]> {
    const domains = await this.findBySubject(subjectId);
    
    // TODO: Calculate progress for each domain
    // This will be implemented when we have user progress tracking per domain
    
    return domains;
  }
}

