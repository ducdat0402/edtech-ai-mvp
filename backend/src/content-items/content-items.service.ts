import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ContentItem } from './entities/content-item.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { AiService } from '../ai/ai.service';

@Injectable()
export class ContentItemsService {
  private readonly logger = new Logger(ContentItemsService.name);

  constructor(
    @InjectRepository(ContentItem)
    private contentItemRepository: Repository<ContentItem>,
    @InjectRepository(LearningNode)
    private learningNodeRepository: Repository<LearningNode>,
    private aiService: AiService,
  ) {}

  /**
   * Auto-detect content format based on media and quizData
   */
  detectFormat(item: Partial<ContentItem>): 'video' | 'image' | 'mixed' | 'quiz' | 'text' {
    const hasVideo = item.media?.videoUrl && item.media.videoUrl.trim() !== '';
    const hasImage = item.media?.imageUrl && item.media.imageUrl.trim() !== '';
    const hasQuiz = item.quizData && item.quizData.question;
    const hasContent = item.content && item.content.trim() !== '';

    if (hasQuiz) {
      return 'quiz';
    }
    if (hasVideo && hasImage) {
      return 'mixed';
    }
    if (hasVideo) {
      return 'video';
    }
    if (hasImage) {
      return 'image';
    }
    if (hasContent) {
      return 'text';
    }
    // Default to text if nothing matches
    return 'text';
  }

  /**
   * Calculate rewards based on difficulty level
   */
  calculateRewards(difficulty: 'easy' | 'medium' | 'hard' | 'expert'): {
    xp: number;
    coin: number;
  } {
    const rewardsMap = {
      easy: { xp: 10, coin: 5 },
      medium: { xp: 25, coin: 10 },
      hard: { xp: 50, coin: 20 },
      expert: { xp: 100, coin: 50 },
    };
    return rewardsMap[difficulty];
  }

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

  async findByFormat(format: 'video' | 'image' | 'mixed' | 'quiz' | 'text'): Promise<ContentItem[]> {
    return this.contentItemRepository.find({
      where: { format },
      order: { createdAt: 'DESC' },
    });
  }

  async findByDifficulty(
    difficulty: 'easy' | 'medium' | 'hard' | 'expert',
  ): Promise<ContentItem[]> {
    return this.contentItemRepository.find({
      where: { difficulty },
      order: { createdAt: 'DESC' },
    });
  }

  async update(
    id: string,
    updates: Partial<{
      title: string;
      content: string;
      order: number;
      format?: 'video' | 'image' | 'mixed' | 'quiz' | 'text';
      difficulty?: 'easy' | 'medium' | 'hard' | 'expert';
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

    // Auto-detect format if media or quizData changed
    if (updates.media !== undefined || updates.quizData !== undefined || updates.content !== undefined) {
      const updatedItem = { ...item, ...updates };
      updates.format = this.detectFormat(updatedItem);
      this.logger.log(`Auto-detected format: ${updates.format} for content item ${id}`);
    }

    // Auto-calculate rewards if difficulty changed
    if (updates.difficulty !== undefined) {
      const rewards = this.calculateRewards(updates.difficulty);
      updates.rewards = {
        ...(item.rewards || {}),
        ...rewards,
      };
      this.logger.log(`Auto-calculated rewards for difficulty ${updates.difficulty}: ${rewards.xp} XP, ${rewards.coin} Coin`);
    }

    Object.assign(item, updates);
    return this.contentItemRepository.save(item);
  }

  /**
   * Update format for all existing content items (migration helper)
   */
  async updateFormatsForAllItems(): Promise<{ updated: number; errors: number }> {
    const items = await this.contentItemRepository.find();
    let updated = 0;
    let errors = 0;

    for (const item of items) {
      try {
        const detectedFormat = this.detectFormat(item);
        if (item.format !== detectedFormat) {
          item.format = detectedFormat;
          await this.contentItemRepository.save(item);
          updated++;
          this.logger.log(`Updated format for ${item.id}: ${detectedFormat}`);
        }
      } catch (error) {
        errors++;
        this.logger.error(`Error updating format for ${item.id}: ${error.message}`);
      }
    }

    return { updated, errors };
  }

  /**
   * Update difficulty and rewards for all items without difficulty
   */
  async updateDifficultyForAllItems(): Promise<{ updated: number; errors: number }> {
    const items = await this.contentItemRepository.find({
      where: { difficulty: null as any },
    });
    let updated = 0;
    let errors = 0;

    for (const item of items) {
      try {
        item.difficulty = 'medium'; // Default difficulty
        const rewards = this.calculateRewards('medium');
        item.rewards = {
          ...(item.rewards || {}),
          ...rewards,
        };
        await this.contentItemRepository.save(item);
        updated++;
        this.logger.log(`Updated difficulty and rewards for ${item.id}`);
      } catch (error) {
        errors++;
        this.logger.error(`Error updating difficulty for ${item.id}: ${error.message}`);
      }
    }

    return { updated, errors };
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

  /**
   * Find content items by node and difficulty
   */
  async findByNodeAndDifficulty(
    nodeId: string,
    difficulty: 'easy' | 'medium' | 'hard' | 'expert',
  ): Promise<ContentItem[]> {
    return this.contentItemRepository.find({
      where: { nodeId, difficulty },
      order: { order: 'ASC' },
    });
  }

  /**
   * Generate content at a specific difficulty level for a node
   * Uses AI to create concepts and examples tailored to the difficulty
   */
  async generateContentByDifficulty(
    nodeId: string,
    difficulty: 'easy' | 'medium' | 'hard',
  ): Promise<{
    success: boolean;
    concepts: ContentItem[];
    examples: ContentItem[];
    message: string;
  }> {
    // Get the learning node
    const node = await this.learningNodeRepository.findOne({
      where: { id: nodeId },
      relations: ['subject'],
    });

    if (!node) {
      throw new NotFoundException(`Learning node ${nodeId} not found`);
    }

    // Check if content at this difficulty already exists
    const existingContent = await this.findByNodeAndDifficulty(nodeId, difficulty);
    if (existingContent.length > 0) {
      this.logger.log(`Content at ${difficulty} level already exists for node ${nodeId}`);
      return {
        success: true,
        concepts: existingContent.filter(c => c.type === 'concept'),
        examples: existingContent.filter(c => c.type === 'example'),
        message: `Đã có ${existingContent.length} nội dung ở mức ${difficulty}`,
      };
    }

    // Get existing content titles to avoid duplicates
    const existingItems = await this.findByNode(nodeId);
    const existingConceptTitles = existingItems
      .filter(i => i.type === 'concept')
      .map(i => i.title);
    const existingExampleTitles = existingItems
      .filter(i => i.type === 'example')
      .map(i => i.title);

    // Generate new content using AI
    const aiContent = await this.aiService.generateContentByDifficulty(
      node.title,
      node.description || '',
      node.subject?.name || 'Không xác định',
      difficulty,
      existingConceptTitles,
      existingExampleTitles,
    );

    const createdConcepts: ContentItem[] = [];
    const createdExamples: ContentItem[] = [];

    // Calculate rewards based on difficulty
    const rewards = {
      easy: { xp: 8, coin: 1 },
      medium: { xp: 12, coin: 2 },
      hard: { xp: 18, coin: 3 },
    };

    // Get current max order
    const maxConceptOrder = existingItems
      .filter(i => i.type === 'concept')
      .reduce((max, i) => Math.max(max, i.order || 0), 0);
    const maxExampleOrder = existingItems
      .filter(i => i.type === 'example')
      .reduce((max, i) => Math.max(max, i.order || 0), 0);

    // Create concepts
    let conceptOrder = maxConceptOrder;
    for (const concept of aiContent.concepts) {
      conceptOrder++;
      const newConcept = this.contentItemRepository.create({
        nodeId,
        type: 'concept',
        difficulty,
        title: concept.title,
        content: concept.content,
        order: conceptOrder,
        format: 'text',
        rewards: rewards[difficulty],
      });
      const saved = await this.contentItemRepository.save(newConcept);
      createdConcepts.push(saved);
    }

    // Create examples
    let exampleOrder = maxExampleOrder;
    for (const example of aiContent.examples) {
      exampleOrder++;
      const newExample = this.contentItemRepository.create({
        nodeId,
        type: 'example',
        difficulty,
        title: example.title,
        content: example.content,
        order: exampleOrder,
        format: 'text',
        rewards: { xp: rewards[difficulty].xp + 5, coin: rewards[difficulty].coin + 1 },
      });
      const saved = await this.contentItemRepository.save(newExample);
      createdExamples.push(saved);
    }

    this.logger.log(
      `Generated ${createdConcepts.length} concepts and ${createdExamples.length} examples at ${difficulty} level for node ${nodeId}`,
    );

    return {
      success: true,
      concepts: createdConcepts,
      examples: createdExamples,
      message: `Đã tạo ${createdConcepts.length} khái niệm và ${createdExamples.length} ví dụ ở mức ${difficulty}`,
    };
  }
}

