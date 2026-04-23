import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { LessonTypeContent } from './entities/lesson-type-content.entity';
import { LessonTypeContentVersion } from './entities/lesson-type-content-version.entity';
import { UsersService } from '../users/users.service';

export type LessonContentVersionContributorDto = {
  id: string;
  fullName: string;
  avatarUrl: string | null;
};

export type LessonContentVersionHistoryEntryDto = {
  id?: string;
  isCurrent?: boolean;
  version: number | null;
  createdAt: string;
  note: string | null;
  /** Ghi nhận nội dung (node.contributorId tại thời điểm lưu / phiên bản hiện tại). */
  contributor: LessonContentVersionContributorDto | null;
  /** Người gửi bản chỉnh đã duyệt — kích hoạt lưu snapshot (có thể trùng contributor). */
  editContributor: LessonContentVersionContributorDto | null;
};

@Injectable()
export class LessonTypeContentsService {
  constructor(
    @InjectRepository(LessonTypeContent)
    private readonly lessonTypeContentRepo: Repository<LessonTypeContent>,
    @InjectRepository(LessonTypeContentVersion)
    private readonly versionRepo: Repository<LessonTypeContentVersion>,
    private readonly usersService: UsersService,
  ) {}

  /**
   * Get all lesson type contents for a learning node
   */
  async getByNodeId(nodeId: string): Promise<LessonTypeContent[]> {
    const contents = await this.lessonTypeContentRepo.find({
      where: { nodeId },
      order: { createdAt: 'ASC' },
    });
    return contents.filter((c) => this.hasRenderableContent(c));
  }

  /**
   * Get a specific lesson type content for a node
   */
  async getByNodeIdAndType(
    nodeId: string,
    lessonType: string,
  ): Promise<LessonTypeContent | null> {
    const content = await this.lessonTypeContentRepo.findOne({
      where: { nodeId, lessonType: lessonType as any },
    });
    if (!content) return null;
    return this.hasRenderableContent(content) ? content : null;
  }

  /**
   * Get count of available lesson types for a node
   */
  async getTypeCountByNodeId(nodeId: string): Promise<number> {
    const contents = await this.getByNodeId(nodeId);
    return contents.length;
  }

  /**
   * Get available lesson type keys for a node
   */
  async getAvailableTypes(nodeId: string): Promise<string[]> {
    const contents = await this.getByNodeId(nodeId);
    return contents.map((c) => c.lessonType);
  }

  private hasRenderableContent(content: LessonTypeContent): boolean {
    const data = content.lessonData as Record<string, any> | null | undefined;
    if (!data || typeof data !== 'object') return false;
    switch (content.lessonType) {
      case 'image_quiz':
        return Array.isArray(data.slides) && data.slides.length > 0;
      case 'image_gallery':
        return Array.isArray(data.images) && data.images.length > 0;
      case 'video': {
        const hasUrl =
          typeof data.videoUrl === 'string' && data.videoUrl.trim().length > 0;
        const hasKeyPoints =
          Array.isArray(data.keyPoints) && data.keyPoints.length > 0;
        const hasSummary =
          typeof data.summary === 'string' && data.summary.trim().length > 0;
        return hasUrl || hasKeyPoints || hasSummary;
      }
      case 'text': {
        const hasSections =
          Array.isArray(data.sections) && data.sections.length > 0;
        const hasSummary =
          typeof data.summary === 'string' && data.summary.trim().length > 0;
        return hasSections || hasSummary;
      }
      default:
        return Object.keys(data).length > 0;
    }
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
    params: {
      /** Người gửi bản chỉnh đã duyệt (thay thế nội dung). */
      editContributorId?: string;
      /** Ghi nhận trên node cho nội dung đang được lưu vào snapshot. */
      contentCreditedContributorId?: string;
      note?: string;
    },
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
      contributorId: params.editContributorId,
      contentCreditedContributorId:
        params.contentCreditedContributorId ?? null,
      note: params.note,
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
   * Archived snapshots with resolved contributor profiles (newest version first).
   */
  async getHistoryWithContributors(
    nodeId: string,
    lessonType: string,
  ): Promise<LessonContentVersionHistoryEntryDto[]> {
    const versions = await this.getHistory(nodeId, lessonType);
    const ids = new Set<string>();
    for (const v of versions) {
      const a = v.contributorId?.trim();
      if (a) ids.add(a);
      const b = v.contentCreditedContributorId?.trim();
      if (b) ids.add(b);
    }
    const userMap = new Map<string, LessonContentVersionContributorDto>();
    await Promise.all(
      [...ids].map(async (id) => {
        const u = await this.usersService.findById(id);
        if (u) {
          userMap.set(id, {
            id: u.id,
            fullName: (u.fullName && u.fullName.trim()) || 'Thành viên',
            avatarUrl: u.avatarUrl ?? null,
          });
        }
      }),
    );

    return versions.map((v) => {
      const contentId = v.contentCreditedContributorId?.trim();
      const editId = v.contributorId?.trim();
      const contentContributor = contentId
        ? userMap.get(contentId) ?? null
        : null;
      const editContributor = editId ? userMap.get(editId) ?? null : null;
      return {
        id: v.id,
        version: v.version,
        createdAt:
          v.createdAt instanceof Date
            ? v.createdAt.toISOString()
            : String(v.createdAt),
        note: v.note ?? null,
        contributor: contentContributor,
        editContributor:
          contentContributor && editId === contentId
            ? null
            : editContributor,
      };
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
