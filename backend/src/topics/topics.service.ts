import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Topic } from './entities/topic.entity';
import { DomainsService } from '../domains/domains.service';

@Injectable()
export class TopicsService {
  constructor(
    @InjectRepository(Topic)
    private topicRepository: Repository<Topic>,
    @Inject(forwardRef(() => DomainsService))
    private domainsService: DomainsService,
  ) {}

  /**
   * Lấy tất cả topics
   */
  async findAll(): Promise<Topic[]> {
    return this.topicRepository.find({
      order: { order: 'ASC' },
      relations: ['domain', 'nodes'],
    });
  }

  /**
   * Lấy tất cả topics của một domain
   */
  async findByDomain(domainId: string): Promise<Topic[]> {
    return this.topicRepository.find({
      where: { domainId },
      order: { order: 'ASC' },
      relations: ['nodes'],
    });
  }

  /**
   * Lấy topic theo ID
   */
  async findById(id: string): Promise<Topic | null> {
    return this.topicRepository.findOne({
      where: { id },
      relations: ['domain', 'nodes'],
    });
  }

  /**
   * Tạo topic mới
   */
  async create(
    domainId: string,
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
      };
    },
  ): Promise<Topic> {
    // Verify domain exists
    const domain = await this.domainsService.findById(domainId);
    if (!domain) {
      throw new NotFoundException(`Domain ${domainId} not found`);
    }

    // Get max order if not provided
    let order = data.order;
    if (order === undefined) {
      const existingTopics = await this.findByDomain(domainId);
      order =
        existingTopics.length > 0
          ? Math.max(...existingTopics.map((t) => t.order)) + 1
          : 0;
    }

    const topic = this.topicRepository.create({
      domainId,
      name: data.name,
      description: data.description,
      order,
      difficulty: data.difficulty || 'medium',
      expReward: data.expReward || 0,
      coinReward: data.coinReward || 0,
      metadata: data.metadata || {},
    });

    return await this.topicRepository.save(topic);
  }

  /**
   * Cập nhật topic
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
  ): Promise<Topic> {
    const topic = await this.findById(id);
    if (!topic) {
      throw new NotFoundException(`Topic ${id} not found`);
    }

    if (data.name !== undefined) topic.name = data.name;
    if (data.description !== undefined) topic.description = data.description;
    if (data.order !== undefined) topic.order = data.order;
    if (data.difficulty !== undefined) topic.difficulty = data.difficulty;
    if (data.expReward !== undefined) topic.expReward = data.expReward;
    if (data.coinReward !== undefined) topic.coinReward = data.coinReward;
    if (data.metadata !== undefined)
      topic.metadata = { ...topic.metadata, ...data.metadata };

    return await this.topicRepository.save(topic);
  }

  /**
   * Xóa topic (chỉ khi không có learning nodes)
   */
  async delete(id: string): Promise<void> {
    const topic = await this.findById(id);
    if (!topic) {
      throw new NotFoundException(`Topic ${id} not found`);
    }

    // Check if topic has learning nodes
    if (topic.nodes && topic.nodes.length > 0) {
      throw new BadRequestException(
        `Cannot delete topic with ${topic.nodes.length} learning nodes. Please move or delete nodes first.`,
      );
    }

    await this.topicRepository.remove(topic);
  }
}
