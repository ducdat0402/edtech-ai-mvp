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
   * Logic mới: format chỉ có 'text', 'mixed', 'quiz'
   * - text: chỉ có nội dung văn bản
   * - mixed: có text + image và/hoặc video
   * - quiz: có câu hỏi trắc nghiệm
   */
  detectFormat(item: Partial<ContentItem>): 'text' | 'mixed' | 'quiz' {
    const hasVideo = item.media?.videoUrl && item.media.videoUrl.trim() !== '';
    const hasImage = item.media?.imageUrl && item.media.imageUrl.trim() !== '';
    const hasQuiz = item.quizData && item.quizData.question;

    if (hasQuiz) {
      return 'quiz';
    }
    if (hasVideo || hasImage) {
      return 'mixed';
    }
    // Default to text
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

  async findByNode(nodeId: string, includeBossQuiz = false): Promise<ContentItem[]> {
    const items = await this.contentItemRepository.find({
      where: { nodeId },
      order: { order: 'ASC' },
    });
    
    // Filter out boss_quiz by default (boss quiz is now separate)
    if (!includeBossQuiz) {
      return items.filter(item => item.type !== 'boss_quiz');
    }
    return items;
  }

  async findById(id: string): Promise<ContentItem | null> {
    return this.contentItemRepository.findOne({ where: { id } });
  }

  async findAll(): Promise<ContentItem[]> {
    return this.contentItemRepository.find({
      order: { createdAt: 'DESC' },
      take: 500, // Limit to prevent memory issues
    });
  }

  /**
   * Create a new content item (Admin)
   */
  async create(data: {
    nodeId: string;
    title: string;
    content?: string;
    type?: 'concept' | 'example' | 'hidden_reward' | 'boss_quiz';
    format?: 'text' | 'mixed' | 'quiz';
    difficulty?: 'easy' | 'medium' | 'hard' | 'expert';
    order?: number;
    rewards?: { xp?: number; coin?: number };
    media?: {
      videoUrl?: string;
      imageUrl?: string;
      imageUrls?: string[];
      videoScript?: string;
      videoDescription?: string;
      videoDuration?: string;
      imagePrompt?: string;
      imageDescription?: string;
    };
    textVariants?: {
      simple?: string;
      detailed?: string;
      comprehensive?: string;
    };
    quizData?: {
      question?: string;
      options?: string[];
      correctAnswer?: number;
      explanation?: string;
    };
  }): Promise<ContentItem> {
    // Check if node exists
    const node = await this.learningNodeRepository.findOne({
      where: { id: data.nodeId },
    });
    if (!node) {
      throw new NotFoundException(`Learning node not found: ${data.nodeId}`);
    }

    // Get the next order if not provided
    let order = data.order;
    if (order === undefined) {
      const existingItems = await this.contentItemRepository.find({
        where: { nodeId: data.nodeId },
        order: { order: 'DESC' },
        take: 1,
      });
      order = existingItems.length > 0 ? (existingItems[0].order || 0) + 1 : 1;
    }

    const difficulty = data.difficulty || 'medium';
    const defaultRewards = this.calculateRewards(difficulty);

    const contentItem = this.contentItemRepository.create({
      nodeId: data.nodeId,
      title: data.title,
      content: data.content || '',
      type: data.type || 'concept',
      format: data.format || this.detectFormat(data),
      difficulty,
      order,
      rewards: data.rewards || defaultRewards,
      media: data.media || {},
      textVariants: data.textVariants,
      quizData: data.quizData,
      status: 'published',
    });

    const saved = await this.contentItemRepository.save(contentItem);

    // Update node's content structure
    await this.updateNodeContentStructure(data.nodeId);

    return saved;
  }

  /**
   * Update node's content structure count
   */
  private async updateNodeContentStructure(nodeId: string): Promise<void> {
    const items = await this.contentItemRepository.find({ where: { nodeId } });
    
    const structure = {
      concepts: items.filter(i => i.type === 'concept').length,
      examples: items.filter(i => i.type === 'example').length,
      hiddenRewards: items.filter(i => i.type === 'hidden_reward').length,
      bossQuiz: items.filter(i => i.type === 'boss_quiz').length,
    };

    await this.learningNodeRepository.update(nodeId, {
      contentStructure: structure,
    });
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

  async findByFormat(format: 'text' | 'mixed' | 'quiz'): Promise<ContentItem[]> {
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
      format?: 'text' | 'mixed' | 'quiz';
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

  /**
   * @deprecated Logic mới: Mỗi bài học có 3 dạng (text + image + video) nên không cần tạo placeholders riêng
   * Hàm này giữ lại để backward compatibility nhưng không còn sử dụng
   */
  async generateMediaPlaceholders(nodeId: string): Promise<{
    success: boolean;
    message: string;
  }> {
    return {
      success: false,
      message: 'Logic mới: Mỗi bài học có 3 dạng nội dung (text + image + video). Không cần tạo placeholders riêng biệt.',
    };
  }

  /**
   * Find placeholders awaiting contribution
   */
  async findPlaceholders(nodeId?: string): Promise<ContentItem[]> {
    const where: any = { status: 'placeholder' };
    if (nodeId) {
      where.nodeId = nodeId;
    }
    return this.contentItemRepository.find({
      where,
      order: { createdAt: 'DESC' },
      relations: ['node'],
    });
  }

  /**
   * Submit contribution for a content item (add media to existing content)
   * Logic mới: Người dùng có thể đóng góp image hoặc video cho bất kỳ bài học nào
   */
  async submitContribution(
    contentId: string,
    contributorId: string,
    mediaUrl: string,
    mediaType: 'video' | 'image',
  ): Promise<ContentItem> {
    const content = await this.contentItemRepository.findOne({
      where: { id: contentId },
    });

    if (!content) {
      throw new NotFoundException(`Content ${contentId} not found`);
    }

    // Update content with contribution
    content.contributorId = contributorId;
    content.contributedAt = new Date();
    content.format = 'mixed'; // Update format to mixed since we're adding media

    if (mediaType === 'video') {
      content.media = {
        ...content.media,
        videoUrl: mediaUrl,
      };
    } else {
      content.media = {
        ...content.media,
        imageUrl: mediaUrl,
      };
    }

    const saved = await this.contentItemRepository.save(content);
    this.logger.log(`${mediaType} contribution submitted for content ${contentId} by user ${contributorId}`);

    return saved;
  }

  /**
   * Approve a contribution (admin only)
   */
  async approveContribution(contentId: string): Promise<ContentItem> {
    const content = await this.contentItemRepository.findOne({
      where: { id: contentId },
    });

    if (!content) {
      throw new NotFoundException(`Content ${contentId} not found`);
    }

    if (content.status !== 'awaiting_review') {
      throw new Error('This content is not awaiting review');
    }

    content.status = 'published' as any;
    // Update title to remove placeholder emoji
    content.title = content.title.replace(/^(🎬|🖼️)\s*/, '');

    const saved = await this.contentItemRepository.save(content);
    this.logger.log(`Contribution ${contentId} approved`);

    return saved;
  }

  /**
   * Reject a contribution (admin only)
   */
  async rejectContribution(contentId: string, reason?: string): Promise<ContentItem> {
    const content = await this.contentItemRepository.findOne({
      where: { id: contentId },
    });

    if (!content) {
      throw new NotFoundException(`Content ${contentId} not found`);
    }

    if (content.status !== 'awaiting_review') {
      throw new Error('This content is not awaiting review');
    }

    // Reset to placeholder status
    content.status = 'placeholder' as any;
    content.contributorId = null as any;
    content.contributedAt = null as any;
    content.media = null as any;

    const saved = await this.contentItemRepository.save(content);
    this.logger.log(`Contribution ${contentId} rejected${reason ? `: ${reason}` : ''}`);

    return saved;
  }

  /**
   * Create a new contribution for a node
   * Logic mới: Tạo bài học mới với cả text, image và video
   */
  async createNewContribution(
    nodeId: string,
    userId: string,
    data: {
      title: string;
      content: string;
      imageUrl?: string;
      videoUrl?: string;
    },
  ): Promise<ContentItem> {
    // Verify node exists
    const node = await this.learningNodeRepository.findOne({
      where: { id: nodeId },
    });

    if (!node) {
      throw new NotFoundException(`Learning node ${nodeId} not found`);
    }

    // Get the highest order for this node
    const existingItems = await this.contentItemRepository.find({
      where: { nodeId: nodeId },
      order: { order: 'DESC' },
      take: 1,
    });
    const nextOrder = existingItems.length > 0 ? (existingItems[0].order || 0) + 1 : 1;

    // Detect format based on media
    const hasMedia = data.imageUrl || data.videoUrl;
    const format = hasMedia ? 'mixed' : 'text';

    // Create new content item with awaiting_review status
    const newContent = this.contentItemRepository.create({
      nodeId: nodeId,
      type: 'concept', // Default type for contributions
      title: data.title,
      content: data.content,
      format: format,
      order: nextOrder,
      status: 'awaiting_review' as any,
      media: {
        imageUrl: data.imageUrl,
        videoUrl: data.videoUrl,
      },
      rewards: {
        xp: 10,
        coin: 5,
      },
      contributorId: userId,
      contributedAt: new Date(),
    });

    const saved = await this.contentItemRepository.save(newContent);
    this.logger.log(`New contribution created for node ${nodeId} by user ${userId}`);

    return saved;
  }

  /**
   * Generate 3 text variants (simple, detailed, comprehensive) for a content item
   * Only applicable for text-based content (concept, example)
   */
  async generateTextVariants(contentId: string): Promise<ContentItem> {
    const content = await this.contentItemRepository.findOne({
      where: { id: contentId },
      relations: ['node', 'node.subject'],
    });

    if (!content) {
      throw new NotFoundException(`Content ${contentId} not found`);
    }

    // Only generate for text-based content
    if (content.type === 'boss_quiz' || content.type === 'hidden_reward') {
      throw new Error('Text variants are only for concept and example content');
    }

    // Skip if already has variants
    if (content.textVariants?.simple && content.textVariants?.comprehensive) {
      this.logger.log(`Content ${contentId} already has text variants`);
      return content;
    }

    const originalContent = content.content || '';
    const subjectName = content.node?.subject?.name || 'Không xác định';

    // Generate 3 variants using AI
    const variants = await this.aiService.generateTextVariants(
      content.title,
      originalContent,
      subjectName,
      content.node?.title,
    );

    // Save variants
    content.textVariants = {
      simple: variants.simple,
      detailed: variants.detailed || originalContent,
      comprehensive: variants.comprehensive,
    };

    const saved = await this.contentItemRepository.save(content);
    this.logger.log(`✅ Generated 3 text variants for content ${contentId}`);

    return saved;
  }

  /**
   * Get content with text variant based on user preference
   */
  async getContentWithVariant(
    contentId: string,
    variant: 'simple' | 'detailed' | 'comprehensive' = 'detailed',
  ): Promise<ContentItem & { selectedContent: string }> {
    let content = await this.contentItemRepository.findOne({
      where: { id: contentId },
      relations: ['node'],
    });

    if (!content) {
      throw new NotFoundException(`Content ${contentId} not found`);
    }

    // Determine which content to return
    let selectedContent = content.content || '';

    if (content.textVariants) {
      switch (variant) {
        case 'simple':
          selectedContent = content.textVariants.simple || content.content || '';
          break;
        case 'comprehensive':
          selectedContent = content.textVariants.comprehensive || content.content || '';
          break;
        default:
          selectedContent = content.textVariants.detailed || content.content || '';
      }
    }

    return {
      ...content,
      selectedContent,
    };
  }

  /**
   * Batch generate text variants for all content in a node
   */
  async generateVariantsForNode(nodeId: string): Promise<{
    success: boolean;
    processed: number;
    message: string;
  }> {
    const contents = await this.findByNode(nodeId);
    const textContents = contents.filter(
      c => c.type === 'concept' || c.type === 'example'
    );

    let processed = 0;
    for (const content of textContents) {
      try {
        // Skip if already has variants
        if (content.textVariants?.simple && content.textVariants?.comprehensive) {
          continue;
        }
        await this.generateTextVariants(content.id);
        processed++;
      } catch (error) {
        this.logger.error(`Failed to generate variants for ${content.id}:`, error);
      }
    }

    return {
      success: true,
      processed,
      message: `Đã tạo ${processed}/${textContents.length} phiên bản nội dung`,
    };
  }
}

