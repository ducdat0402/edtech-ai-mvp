import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { LessonTypeContent } from './entities/lesson-type-content.entity';
import { LessonTypeContentVersion } from './entities/lesson-type-content-version.entity';

@Injectable()
export class LessonTypeContentsService {
  constructor(
    @InjectRepository(LessonTypeContent)
    private readonly lessonTypeContentRepo: Repository<LessonTypeContent>,
    @InjectRepository(LessonTypeContentVersion)
    private readonly versionRepo: Repository<LessonTypeContentVersion>,
  ) {}

  /**
   * Get all lesson type contents for a learning node
   */
  async getByNodeId(nodeId: string): Promise<LessonTypeContent[]> {
    return this.lessonTypeContentRepo.find({
      where: { nodeId },
      order: { createdAt: 'ASC' },
    });
  }

  /**
   * Get a specific lesson type content for a node
   */
  async getByNodeIdAndType(
    nodeId: string,
    lessonType: string,
  ): Promise<LessonTypeContent | null> {
    return this.lessonTypeContentRepo.findOne({
      where: { nodeId, lessonType: lessonType as any },
    });
  }

  /**
   * Get count of available lesson types for a node
   */
  async getTypeCountByNodeId(nodeId: string): Promise<number> {
    return this.lessonTypeContentRepo.count({ where: { nodeId } });
  }

  /**
   * Get available lesson type keys for a node
   */
  async getAvailableTypes(nodeId: string): Promise<string[]> {
    const contents = await this.lessonTypeContentRepo.find({
      where: { nodeId },
      select: ['lessonType'],
    });
    return contents.map((c) => c.lessonType);
  }

  /**
   * Create a new lesson type content for a node
   */
  async create(data: {
    nodeId: string;
    lessonType: 'image_quiz' | 'image_gallery' | 'video' | 'text';
    lessonData: Record<string, any>;
    endQuiz: Record<string, any>;
  }): Promise<LessonTypeContent> {
    // Check for duplicate
    const existing = await this.getByNodeIdAndType(data.nodeId, data.lessonType);
    if (existing) {
      throw new ConflictException(
        `Lesson type "${data.lessonType}" already exists for node ${data.nodeId}`,
      );
    }

    const content = this.lessonTypeContentRepo.create({
      nodeId: data.nodeId,
      lessonType: data.lessonType,
      lessonData: data.lessonData,
      endQuiz: data.endQuiz as any,
    });

    return this.lessonTypeContentRepo.save(content);
  }

  /**
   * Update an existing lesson type content
   */
  async update(
    nodeId: string,
    lessonType: string,
    data: {
      lessonData?: Record<string, any>;
      endQuiz?: Record<string, any>;
    },
  ): Promise<LessonTypeContent> {
    const content = await this.getByNodeIdAndType(nodeId, lessonType);
    if (!content) {
      throw new NotFoundException(
        `Lesson type "${lessonType}" not found for node ${nodeId}`,
      );
    }

    if (data.lessonData !== undefined) content.lessonData = data.lessonData;
    if (data.endQuiz !== undefined) content.endQuiz = data.endQuiz as any;

    return this.lessonTypeContentRepo.save(content);
  }

  /**
   * Delete a lesson type content
   */
  async delete(nodeId: string, lessonType: string): Promise<void> {
    const content = await this.getByNodeIdAndType(nodeId, lessonType);
    if (!content) {
      throw new NotFoundException(
        `Lesson type "${lessonType}" not found for node ${nodeId}`,
      );
    }
    await this.lessonTypeContentRepo.remove(content);
  }

  // ==================== Version History ====================

  /**
   * Save the current content as a version snapshot before updating.
   * Returns the created version record.
   */
  async saveVersionSnapshot(
    nodeId: string,
    lessonType: string,
    contributorId?: string,
    note?: string,
  ): Promise<LessonTypeContentVersion> {
    const content = await this.getByNodeIdAndType(nodeId, lessonType);
    if (!content) {
      throw new NotFoundException(
        `Lesson type "${lessonType}" not found for node ${nodeId}`,
      );
    }

    // Determine the next version number
    const lastVersion = await this.versionRepo.findOne({
      where: { nodeId, lessonType: lessonType as any },
      order: { version: 'DESC' },
    });
    const nextVersion = lastVersion ? lastVersion.version + 1 : 1;

    const version = this.versionRepo.create({
      nodeId,
      lessonType: lessonType as any,
      version: nextVersion,
      lessonData: content.lessonData,
      endQuiz: content.endQuiz,
      contributorId,
      note,
    });

    return this.versionRepo.save(version);
  }

  /**
   * Get version history for a specific lesson type of a node.
   * Returns versions ordered from newest to oldest.
   */
  async getHistory(
    nodeId: string,
    lessonType: string,
  ): Promise<LessonTypeContentVersion[]> {
    return this.versionRepo.find({
      where: { nodeId, lessonType: lessonType as any },
      order: { version: 'DESC' },
    });
  }

  /**
   * Get a specific version by ID.
   */
  async getVersionById(
    versionId: string,
  ): Promise<LessonTypeContentVersion> {
    const version = await this.versionRepo.findOne({
      where: { id: versionId },
    });
    if (!version) {
      throw new NotFoundException(`Version ${versionId} not found`);
    }
    return version;
  }
}
