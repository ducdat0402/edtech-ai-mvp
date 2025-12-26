import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ContentItem } from './entities/content-item.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { AiService } from '../ai/ai.service';
import { FileParserService } from './file-parser.service';

@Injectable()
export class ContentImportService {
  constructor(
    private aiService: AiService,
    private fileParserService: FileParserService,
    @InjectRepository(ContentItem)
    private contentItemRepository: Repository<ContentItem>,
    @InjectRepository(LearningNode)
    private nodeRepository: Repository<LearningNode>,
  ) {}

  /**
   * Import raw text and generate concepts using AI
   */
  async importRawTextToConcepts(
    nodeId: string,
    rawText: string,
    topic: string,
    count: number = 5,
  ): Promise<ContentItem[]> {
    // Validate node exists
    const node = await this.nodeRepository.findOne({ where: { id: nodeId } });
    if (!node) {
      throw new NotFoundException(`Learning node ${nodeId} not found`);
    }

    // Limit text length to avoid token limits (keep first 8000 chars)
    const truncatedText = rawText.substring(0, 8000);

    console.log(`🤖 Generating ${count} concepts from raw text for node: ${node.title}`);

    // Generate concepts using AI
    const concepts = await this.aiService.generateMultipleConceptsFromDocument(
      truncatedText,
      topic || node.title,
      count,
    );

    // Save to database
    const savedConcepts: ContentItem[] = [];
    for (let i = 0; i < concepts.length; i++) {
      const concept = this.contentItemRepository.create({
        nodeId,
        type: 'concept',
        title: concepts[i].title,
        content: concepts[i].content,
        order: i + 1,
        rewards: concepts[i].rewards,
      });

      const saved = await this.contentItemRepository.save(concept);
      savedConcepts.push(saved);
      console.log(`✅ Saved concept: ${saved.title}`);
    }

    return savedConcepts;
  }

  /**
   * Generate a single concept from raw text
   */
  async generateSingleConcept(
    nodeId: string,
    rawText: string,
    topic: string,
    difficulty: 'beginner' | 'intermediate' | 'advanced' = 'beginner',
  ): Promise<ContentItem> {
    // Validate node exists
    const node = await this.nodeRepository.findOne({ where: { id: nodeId } });
    if (!node) {
      throw new NotFoundException(`Learning node ${nodeId} not found`);
    }

    console.log(`🤖 Generating single concept for node: ${node.title}`);

    // Generate concept using AI
    const concept = await this.aiService.generateConceptFromRawData(
      rawText.substring(0, 2000), // Limit to 2000 chars for single concept
      topic || node.title,
      difficulty,
    );

    // Get current max order
    const existingItems = await this.contentItemRepository.find({
      where: { nodeId, type: 'concept' },
      order: { order: 'DESC' },
      take: 1,
    });
    const nextOrder = existingItems.length > 0 ? existingItems[0].order + 1 : 1;

    // Save to database
    const contentItem = this.contentItemRepository.create({
      nodeId,
      type: 'concept',
      title: concept.title,
      content: concept.content,
      order: nextOrder,
      rewards: concept.rewards,
    });

    const saved = await this.contentItemRepository.save(contentItem);
    console.log(`✅ Saved concept: ${saved.title}`);

    return saved;
  }

  /**
   * Generate examples from raw text
   */
  async generateExamples(
    nodeId: string,
    rawText: string,
    topic: string,
    count: number = 3,
  ): Promise<ContentItem[]> {
    // Validate node exists
    const node = await this.nodeRepository.findOne({ where: { id: nodeId } });
    if (!node) {
      throw new NotFoundException(`Learning node ${nodeId} not found`);
    }

    console.log(`🤖 Generating ${count} examples for node: ${node.title}`);

    // Get current max order
    const existingItems = await this.contentItemRepository.find({
      where: { nodeId, type: 'example' },
      order: { order: 'DESC' },
      take: 1,
    });
    const nextOrder = existingItems.length > 0 ? existingItems[0].order + 1 : 1;

    const savedExamples: ContentItem[] = [];

    // Generate examples one by one
    for (let i = 0; i < count; i++) {
      try {
        const example = await this.aiService.generateExampleFromRawData(
          rawText.substring(0, 2000),
          topic || node.title,
        );

        const contentItem = this.contentItemRepository.create({
          nodeId,
          type: 'example',
          title: example.title,
          content: example.content,
          order: nextOrder + i,
          rewards: example.rewards,
        });

        const saved = await this.contentItemRepository.save(contentItem);
        savedExamples.push(saved);
        console.log(`✅ Saved example: ${saved.title}`);

        // Small delay to avoid rate limiting
        if (i < count - 1) {
          await new Promise((resolve) => setTimeout(resolve, 500));
        }
      } catch (error) {
        console.error(`Error generating example ${i + 1}:`, error);
        // Continue with next example
      }
    }

    return savedExamples;
  }

  /**
   * Import from file (PDF, DOCX, TXT) and generate concepts
   */
  async importFromFile(
    nodeId: string,
    file: Express.Multer.File,
    topic: string,
    count: number = 5,
  ): Promise<ContentItem[]> {
    // Validate file
    this.fileParserService.validateFile(file);

    // Parse file to text
    console.log(`📄 Parsing file: ${file.originalname} (${file.mimetype})`);
    const rawText = await this.fileParserService.parseFile(
      file.buffer,
      file.mimetype,
      file.originalname,
    );

    console.log(`✅ Parsed ${rawText.length} characters from file`);

    // Import concepts from parsed text
    return this.importRawTextToConcepts(nodeId, rawText, topic, count);
  }

  /**
   * Generate single concept from file
   */
  async generateConceptFromFile(
    nodeId: string,
    file: Express.Multer.File,
    topic: string,
    difficulty: 'beginner' | 'intermediate' | 'advanced' = 'beginner',
  ): Promise<ContentItem> {
    // Validate file
    this.fileParserService.validateFile(file);

    // Parse file to text
    console.log(`📄 Parsing file: ${file.originalname} (${file.mimetype})`);
    const rawText = await this.fileParserService.parseFile(
      file.buffer,
      file.mimetype,
      file.originalname,
    );

    console.log(`✅ Parsed ${rawText.length} characters from file`);

    // Generate concept from parsed text
    return this.generateSingleConcept(nodeId, rawText, topic, difficulty);
  }

  /**
   * Generate examples from file
   */
  async generateExamplesFromFile(
    nodeId: string,
    file: Express.Multer.File,
    topic: string,
    count: number = 3,
  ): Promise<ContentItem[]> {
    // Validate file
    this.fileParserService.validateFile(file);

    // Parse file to text
    console.log(`📄 Parsing file: ${file.originalname} (${file.mimetype})`);
    const rawText = await this.fileParserService.parseFile(
      file.buffer,
      file.mimetype,
      file.originalname,
    );

    console.log(`✅ Parsed ${rawText.length} characters from file`);

    // Generate examples from parsed text
    return this.generateExamples(nodeId, rawText, topic, count);
  }

  /**
   * Preview file content without generating concepts
   */
  async previewFile(file: Express.Multer.File): Promise<{
    filename: string;
    size: number;
    mimetype: string;
    parsedText: string;
    textLength: number;
    estimatedConcepts: number;
    preview: string; // First 500 characters
  }> {
    // Validate file
    this.fileParserService.validateFile(file);

    // Parse file to text
    console.log(`📄 Preview parsing file: ${file.originalname} (${file.mimetype})`);
    const parsedText = await this.fileParserService.parseFile(
      file.buffer,
      file.mimetype,
      file.originalname,
    );

    // Estimate number of concepts (roughly 1 concept per 1000 characters)
    const estimatedConcepts = Math.max(1, Math.min(10, Math.floor(parsedText.length / 1000)));

    return {
      filename: file.originalname,
      size: file.size,
      mimetype: file.mimetype,
      parsedText,
      textLength: parsedText.length,
      estimatedConcepts,
      preview: parsedText.substring(0, 500) + (parsedText.length > 500 ? '...' : ''),
    };
  }

  /**
   * Preview raw text without generating concepts
   */
  async previewText(rawText: string, topic: string): Promise<{
    textLength: number;
    estimatedConcepts: number;
    preview: string;
    topic: string;
  }> {
    // Estimate number of concepts
    const estimatedConcepts = Math.max(1, Math.min(10, Math.floor(rawText.length / 1000)));

    return {
      textLength: rawText.length,
      estimatedConcepts,
      preview: rawText.substring(0, 500) + (rawText.length > 500 ? '...' : ''),
      topic,
    };
  }
}

