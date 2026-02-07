import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThan } from 'typeorm';
import { ContentVersion } from './entities/content-version.entity';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { ContentEdit, ContentEditStatus } from './entities/content-edit.entity';
import { EditHistoryService } from './edit-history.service';
import { EditHistoryAction } from './entities/edit-history.entity';

@Injectable()
export class ContentVersionService {
  private readonly logger = new Logger(ContentVersionService.name);

  constructor(
    @InjectRepository(ContentVersion)
    private contentVersionRepository: Repository<ContentVersion>,
    @InjectRepository(ContentItem)
    private contentItemRepository: Repository<ContentItem>,
    @InjectRepository(ContentEdit)
    private contentEditRepository: Repository<ContentEdit>,
    private editHistoryService: EditHistoryService,
  ) {}

  /**
   * Create a new version when an edit is approved
   */
  async createVersion(
    contentItemId: string,
    relatedEditId: string,
    approvedByUserId: string,
    createdByUserId: string,
    description?: string,
  ): Promise<ContentVersion> {
    // Get the content item
    const contentItem = await this.contentItemRepository.findOne({
      where: { id: contentItemId },
    });

    if (!contentItem) {
      throw new NotFoundException(`Content item ${contentItemId} not found`);
    }

    // Get the next version number
    const lastVersion = await this.contentVersionRepository.findOne({
      where: { contentItemId },
      order: { versionNumber: 'DESC' },
    });

    const versionNumber = lastVersion ? lastVersion.versionNumber + 1 : 1;

    // Mark all previous versions as not current
    await this.contentVersionRepository.update(
      { contentItemId },
      { isCurrent: false },
    );

    // Create version snapshot
    const contentSnapshot = {
      title: contentItem.title,
      content: contentItem.content,
      richContent: (contentItem as any).richContent || null,
      media: contentItem.media || null,
      quizData: contentItem.quizData || null,
      format: contentItem.format || null,
      difficulty: contentItem.difficulty || null,
      rewards: contentItem.rewards || null,
    };

    // Create new version
    const version = this.contentVersionRepository.create({
      contentItemId,
      relatedEditId,
      approvedByUserId,
      createdByUserId,
      versionNumber,
      contentSnapshot,
      description: description || `Version ${versionNumber}`,
      isCurrent: true,
    });

    const savedVersion = await this.contentVersionRepository.save(version);
    this.logger.log(
      `✅ Created version ${versionNumber} for content item ${contentItemId}`,
    );

    return savedVersion;
  }

  /**
   * Get all versions for a content item (for admin)
   */
  async getVersionsForContent(
    contentItemId: string,
  ): Promise<ContentVersion[]> {
    return this.contentVersionRepository.find({
      where: { contentItemId },
      relations: ['createdBy', 'approvedBy', 'relatedEdit'],
      order: { versionNumber: 'DESC' },
    });
  }

  /**
   * Get versions created by a specific user (for user)
   */
  async getVersionsByUser(
    userId: string,
    contentItemId?: string,
  ): Promise<ContentVersion[]> {
    const where: any = { createdByUserId: userId };
    if (contentItemId) {
      where.contentItemId = contentItemId;
    }

    return this.contentVersionRepository.find({
      where,
      relations: ['contentItem', 'approvedBy', 'relatedEdit'],
      order: { createdAt: 'DESC' },
    });
  }

  /**
   * Revert to a specific version
   */
  async revertToVersion(
    versionId: string,
    adminUserId: string,
  ): Promise<{ message: string; affectedEdits: string[] }> {
    const version = await this.contentVersionRepository.findOne({
      where: { id: versionId },
      relations: ['contentItem', 'relatedEdit'],
    });

    if (!version) {
      throw new NotFoundException(`Version ${versionId} not found`);
    }

    const contentItem = version.contentItem;
    if (!contentItem) {
      throw new NotFoundException('Content item not found');
    }

    // Check if this is reverting to an older version
    const currentVersion = await this.contentVersionRepository.findOne({
      where: { contentItemId: contentItem.id, isCurrent: true },
    });

    const isRevertingToOlder =
      currentVersion && version.versionNumber < currentVersion.versionNumber;

    // Find all edits approved after this version that will be affected
    const affectedEditIds: string[] = [];
    if (isRevertingToOlder && currentVersion) {
      const versionsAfter = await this.contentVersionRepository.find({
        where: {
          contentItemId: contentItem.id,
          versionNumber: MoreThan(version.versionNumber),
        },
        relations: ['relatedEdit'],
      });

      for (const v of versionsAfter) {
        if (v.relatedEditId) {
          affectedEditIds.push(v.relatedEditId);
        }
      }
    }

    // Revert content item to version snapshot
    contentItem.title = version.contentSnapshot.title;
    contentItem.content = version.contentSnapshot.content;
    (contentItem as any).richContent = version.contentSnapshot.richContent;
    contentItem.media = version.contentSnapshot.media || null;
    contentItem.quizData = version.contentSnapshot.quizData || null;
    if (version.contentSnapshot.format) {
      contentItem.format = version.contentSnapshot.format as any;
    }
    if (version.contentSnapshot.difficulty) {
      contentItem.difficulty = version.contentSnapshot.difficulty as any;
    }
    if (version.contentSnapshot.rewards) {
      contentItem.rewards = version.contentSnapshot.rewards;
    }

    await this.contentItemRepository.save(contentItem);

    // Mark all versions as not current, then mark this version as current
    await this.contentVersionRepository.update(
      { contentItemId: contentItem.id },
      { isCurrent: false },
    );
    version.isCurrent = true;
    await this.contentVersionRepository.save(version);

    // Handle affected edits
    const affectedUsers: Set<string> = new Set();
    for (const editId of affectedEditIds) {
      const edit = await this.contentEditRepository.findOne({
        where: { id: editId },
      });

      if (edit && edit.status === ContentEditStatus.APPROVED) {
        // Reject the edit (it's being reverted)
        edit.status = ContentEditStatus.REJECTED;
        await this.contentEditRepository.save(edit);

        // Notify the user who created this edit
        if (edit.userId) {
          affectedUsers.add(edit.userId);

          // Log history for the user
          await this.editHistoryService.logHistory(
            EditHistoryAction.REJECT,
            edit.userId,
            {
              contentItemId: contentItem.id,
              relatedEditId: edit.id,
              description:
                'Bài đóng góp của bạn đã bị gỡ do hệ thống đã revert về phiên bản cũ hơn',
              changes: {
                reason: 'version_revert',
                revertedToVersion: version.versionNumber,
              },
            },
          );
        }
      }
    }

    // If reverting to a user's version, notify them
    if (version.createdByUserId && version.createdByUserId !== adminUserId) {
      // Log history for the user whose version is being restored
      await this.editHistoryService.logHistory(
        EditHistoryAction.APPROVE,
        version.createdByUserId,
        {
          contentItemId: contentItem.id,
          relatedEditId: version.relatedEditId || null,
          description:
            'Bài đóng góp của bạn đã được admin sử dụng lại (revert về phiên bản của bạn)',
          changes: {
            reason: 'version_restore',
            versionNumber: version.versionNumber,
          },
        },
      );
    }

    // Log history for admin
    await this.editHistoryService.logHistory(
      EditHistoryAction.UPDATE,
      adminUserId,
      {
        contentItemId: contentItem.id,
        description: `Đã revert về phiên bản ${version.versionNumber}`,
        changes: {
          action: 'revert_version',
          versionId: version.id,
          versionNumber: version.versionNumber,
          affectedEdits: affectedEditIds,
        },
      },
    );

    this.logger.log(
      `✅ Reverted content item ${contentItem.id} to version ${version.versionNumber}`,
    );

    return {
      message: `Đã revert về phiên bản ${version.versionNumber}`,
      affectedEdits: affectedEditIds,
    };
  }
}

