import { Injectable, NotFoundException } from '@nestjs/common';
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

  async update(
    id: string,
    updates: Partial<{
      title: string;
      content: string;
      order: number;
      rewards: { xp?: number; coin?: number; shard?: string; shardAmount?: number };
      media: { videoUrl?: string; imageUrl?: string; interactiveUrl?: string };
      quizData: {
        question?: string;
        options?: string[];
        correctAnswer?: number;
        explanation?: string;
      };
    }>,
  ): Promise<ContentItem> {
    const item = await this.contentItemRepository.findOne({ where: { id } });
    if (!item) {
      throw new NotFoundException(`Content item ${id} not found`);
    }

    Object.assign(item, updates);
    return this.contentItemRepository.save(item);
  }

  async delete(id: string): Promise<void> {
    const item = await this.contentItemRepository.findOne({ where: { id } });
    if (!item) {
      throw new NotFoundException(`Content item ${id} not found`);
    }

    await this.contentItemRepository.remove(item);
  }

  async reorder(nodeId: string, itemIds: string[]): Promise<ContentItem[]> {
    const items = await this.contentItemRepository.find({
      where: { nodeId },
    });

    // Update order based on itemIds array
    items.forEach((item, index) => {
      const newIndex = itemIds.indexOf(item.id);
      if (newIndex !== -1) {
        item.order = newIndex + 1;
      }
    });

    return this.contentItemRepository.save(items);
  }
}

