import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ContentItem } from './entities/content-item.entity';

@Injectable()
export class ContentItemsService {
  constructor(
    @InjectRepository(ContentItem)
    private contentItemRepository: Repository<ContentItem>,
  ) {}

  async findByNode(nodeId: string): Promise<ContentItem[]> {
    return this.contentItemRepository.find({
      where: { nodeId },
      order: { order: 'ASC' },
    });
  }

  async findById(id: string): Promise<ContentItem | null> {
    return this.contentItemRepository.findOne({ where: { id } });
  }

  async findByNodeAndType(
    nodeId: string,
    type: 'concept' | 'example' | 'hidden_reward' | 'boss_quiz',
  ): Promise<ContentItem[]> {
    return this.contentItemRepository.find({
      where: { nodeId, type },
      order: { order: 'ASC' },
    });
  }
}

