import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ContentEdit, ContentEditStatus, ContentEditType } from './entities/content-edit.entity';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { EditHistoryService } from './edit-history.service';
import { EditHistoryAction } from './entities/edit-history.entity';
import { ContentVersionService } from './content-version.service';

@Injectable()
export class ContentEditsService {
  constructor(
    @InjectRepository(ContentEdit)
    private contentEditRepository: Repository<ContentEdit>,
    @InjectRepository(ContentItem)
    private contentItemRepository: Repository<ContentItem>,
    private editHistoryService: EditHistoryService,
    private contentVersionService: ContentVersionService,
  ) { }

  /**
   * Submit a new content edit (video, image, or text)
   */
  async submitEdit(
    contentItemId: string,
    userId: string,
    type: ContentEditType,
    data: {
      videoUrl?: string;
      imageUrl?: string;
      textContent?: string;
      description?: string;
      caption?: string;
    },
  ): Promise<ContentEdit> {
    // Verify content item exists
    const contentItem = await this.contentItemRepository.findOne({
      where: { id: contentItemId },
    });
    if (!contentItem) {
      throw new NotFoundException(`Content item ${contentItemId} not found`);
    }

    // Validate based on type
    if (type === ContentEditType.ADD_VIDEO && !data.videoUrl) {
      throw new BadRequestException('Video URL is required for add_video type');
    }
    if (type === ContentEditType.ADD_IMAGE && !data.imageUrl) {
      throw new BadRequestException('Image URL is required for add_image type');
    }
    if (
      (type === ContentEditType.ADD_TEXT ||
        type === ContentEditType.UPDATE_CONTENT) &&
      !data.textContent
    ) {
      throw new BadRequestException(
        'Text content is required for text-related types',
      );
    }

    // Create content edit
    try {
      const edit = this.contentEditRepository.create({
        contentItemId,
        userId,
        type,
        status: ContentEditStatus.PENDING,
        media:
          type === ContentEditType.ADD_VIDEO || type === ContentEditType.ADD_IMAGE
            ? {
              videoUrl: data.videoUrl,
              imageUrl: data.imageUrl,
              caption: data.caption,
            }
            : null,
        textContent: data.textContent,
        description: data.description,
        upvotes: 0,
        downvotes: 0,
        voters: [],
      });

      const savedEdit = await this.contentEditRepository.save(edit);
      console.log('✅ Content edit created:', savedEdit.id);

      // Log history
      try {
        await this.editHistoryService.logHistory(
          EditHistoryAction.SUBMIT,
          userId,
          {
            contentItemId,
            relatedEditId: savedEdit.id,
            description: `Đã gửi đóng góp ${type === ContentEditType.ADD_VIDEO ? 'video' : type === ContentEditType.ADD_IMAGE ? 'hình ảnh' : 'nội dung'} cho bài học`,
            changes: {
              type,
              hasMedia: !!(data.videoUrl || data.imageUrl),
              hasDescription: !!data.description,
            },
          },
        );
      } catch (error) {
        // Don't fail if history logging fails
        console.error('Failed to log history:', error);
      }

      return savedEdit;
    } catch (error) {
      console.error('❌ Error creating content edit:', error);
      throw error;
    }
  }

  /**
   * Submit a community edit for a lesson (full lesson edit with title, rich content, multiple images, video)
   */
  async submitLessonEdit(
    contentItemId: string,
    userId: string,
    data: {
      title: string;
      richContent?: any; // JSON from flutter_quill (optional for quiz) - detailed version
      textVariants?: {
        simple?: string;
        detailed?: string;
        comprehensive?: string;
        simpleRichContent?: any;
        detailedRichContent?: any;
        comprehensiveRichContent?: any;
      };
      imageUrls?: string[]; // Multiple images (max 5)
      videoUrl?: string;
      description?: string;
      quizData?: {
        question?: string;
        options?: string[];
        correctAnswer?: number;
        explanation?: string;
      };
    },
  ): Promise<ContentEdit> {
    // Verify content item exists
    const contentItem = await this.contentItemRepository.findOne({
      where: { id: contentItemId },
    });
    if (!contentItem) {
      throw new NotFoundException(`Content item ${contentItemId} not found`);
    }

    // Validate
    if (!data.title || data.title.trim().length === 0) {
      throw new BadRequestException('Title is required');
    }
    // Rich content is optional if quizData is provided
    if (!data.richContent && !data.quizData) {
      throw new BadRequestException('Either rich content or quiz data is required');
    }
    if (data.imageUrls && data.imageUrls.length > 5) {
      throw new BadRequestException('Maximum 5 images allowed');
    }
    // Validate quiz data if provided
    if (data.quizData) {
      if (!data.quizData.question || data.quizData.question.trim().length === 0) {
        throw new BadRequestException('Quiz question is required');
      }
      if (!data.quizData.options || data.quizData.options.length < 2) {
        throw new BadRequestException('Quiz must have at least 2 options');
      }
      if (data.quizData.correctAnswer === undefined || data.quizData.correctAnswer < 0 || data.quizData.correctAnswer >= data.quizData.options.length) {
        throw new BadRequestException('Valid correct answer index is required');
      }
    }

    // Save snapshot of current content BEFORE creating edit
    const originalContentSnapshot = {
      title: contentItem.title,
      content: contentItem.content,
      richContent: (contentItem as any).richContent || null,
      textVariants: (contentItem as any).textVariants || null,
      media: contentItem.media ? { ...contentItem.media } : null,
      quizData: contentItem.quizData ? { ...contentItem.quizData } : null,
    };

    // Create content edit
    try {
      const edit = this.contentEditRepository.create({
        contentItemId,
        userId,
        type: ContentEditType.UPDATE_CONTENT,
        status: ContentEditStatus.PENDING,
        title: data.title,
        richContent: data.richContent,
        textVariants: data.textVariants,
        media: {
          imageUrls: data.imageUrls || [],
          videoUrl: data.videoUrl,
        },
        quizData: data.quizData,
        description: data.description,
        originalContentSnapshot, // Save snapshot when creating edit
        upvotes: 0,
        downvotes: 0,
        voters: [],
      });

      const savedEdit = await this.contentEditRepository.save(edit);
      console.log('✅ Lesson edit created:', savedEdit.id);

      // Log history
      try {
        await this.editHistoryService.logHistory(
          EditHistoryAction.SUBMIT,
          userId,
          {
            contentItemId,
            relatedEditId: savedEdit.id,
            description: `Đã gửi chỉnh sửa bài học: ${data.title}`,
            changes: {
              type: 'lesson_edit',
              hasImages: !!(data.imageUrls && data.imageUrls.length > 0),
              hasVideo: !!data.videoUrl,
              hasRichContent: !!data.richContent,
            },
          },
        );
      } catch (error) {
        console.error('Failed to log history:', error);
      }

      return savedEdit;
    } catch (error) {
      console.error('❌ Error creating lesson edit:', error);
      throw error;
    }
  }

  /**
   * Get all edits for a content item (approved ones are shown to users)
   */
  async getEditsForContent(
    contentItemId: string,
    includePending: boolean = false,
  ): Promise<ContentEdit[]> {
    const where: any = { contentItemId };
    if (!includePending) {
      where.status = ContentEditStatus.APPROVED;
    }

    return this.contentEditRepository.find({
      where,
      relations: ['user'],
      order: { createdAt: 'DESC' },
    });
  }

  /**
   * Get edit by ID
   */
  async getEditById(id: string): Promise<ContentEdit> {
    const edit = await this.contentEditRepository.findOne({
      where: { id },
      relations: ['user', 'contentItem'],
    });
    if (!edit) {
      throw new NotFoundException(`Content edit ${id} not found`);
    }
    return edit;
  }

  /**
   * Approve an edit (auto-apply to content item)
   */
  async approveEdit(id: string, adminUserId: string): Promise<ContentEdit> {
    const edit = await this.getEditById(id);

    if (edit.status === ContentEditStatus.APPROVED) {
      return edit; // Already approved
    }

    // Update content item based on edit type
    const contentItem = await this.contentItemRepository.findOne({
      where: { id: edit.contentItemId },
    });

    if (!contentItem) {
      throw new NotFoundException('Content item not found');
    }

    // Save snapshot of original content BEFORE applying edit (if not already saved)
    if (!edit.originalContentSnapshot) {
      edit.originalContentSnapshot = {
        title: contentItem.title,
        content: contentItem.content,
        richContent: (contentItem as any).richContent || null,
        textVariants: (contentItem as any).textVariants || null,
        media: contentItem.media ? { ...contentItem.media } : null,
        quizData: contentItem.quizData ? { ...contentItem.quizData } : null,
      };
      await this.contentEditRepository.save(edit);
    }

    // Apply the edit to content item
    if (edit.type === ContentEditType.ADD_VIDEO && edit.media?.videoUrl) {
      // Add video to existing media or create new media object
      // ✅ Include description and caption from the edit
      contentItem.media = {
        ...(contentItem.media || {}),
        videoUrl: edit.media.videoUrl,
        ...(edit.description ? { description: edit.description } : {}),
        ...(edit.media.caption ? { caption: edit.media.caption } : {}),
      };
      // ✅ Update status from placeholder to published
      if ((contentItem as any).status === 'placeholder' || (contentItem as any).status === 'awaiting_review') {
        (contentItem as any).status = 'published';
        // Remove placeholder emoji from title if present
        contentItem.title = contentItem.title?.replace(/^(🎬|🖼️)\s*/, '') || contentItem.title;
      }
      // Record contributor info
      (contentItem as any).contributorId = edit.userId;
      (contentItem as any).contributedAt = new Date();
    } else if (edit.type === ContentEditType.ADD_IMAGE && edit.media?.imageUrl) {
      // Add image to existing media or create new media object
      // ✅ Include description and caption from the edit
      contentItem.media = {
        ...(contentItem.media || {}),
        imageUrl: edit.media.imageUrl,
        ...(edit.description ? { description: edit.description } : {}),
        ...(edit.media.caption ? { caption: edit.media.caption } : {}),
      };
      // ✅ Update status from placeholder to published
      if ((contentItem as any).status === 'placeholder' || (contentItem as any).status === 'awaiting_review') {
        (contentItem as any).status = 'published';
        // Remove placeholder emoji from title if present
        contentItem.title = contentItem.title?.replace(/^(🎬|🖼️)\s*/, '') || contentItem.title;
      }
      // Record contributor info
      (contentItem as any).contributorId = edit.userId;
      (contentItem as any).contributedAt = new Date();
    } else if (
      edit.type === ContentEditType.UPDATE_CONTENT &&
      edit.textContent
    ) {
      // Update content text (legacy)
      contentItem.content = edit.textContent;
    } else if (edit.type === ContentEditType.UPDATE_CONTENT && edit.title) {
      // Handle full lesson edit (title, richContent, textVariants, images, video, quizData)
      if (edit.title) {
        contentItem.title = edit.title;
      }
      if (edit.richContent) {
        // Store richContent in content item (detailed version)
        (contentItem as any).richContent = edit.richContent;
        // Also store as JSON string in content field for backward compatibility
        contentItem.content = JSON.stringify(edit.richContent);
      }
      // Apply text variants for 3 complexity levels (Đơn giản, Chi tiết, Chuyên sâu)
      if ((edit as any).textVariants) {
        (contentItem as any).textVariants = {
          ...((contentItem as any).textVariants || {}),
          ...(edit as any).textVariants,
        };
      }
      if (edit.media) {
        // Merge media, prioritizing new values
        contentItem.media = {
          ...(contentItem.media || {}),
          ...(edit.media.imageUrls ? { imageUrls: edit.media.imageUrls } : {}),
          ...(edit.media.imageUrl ? { imageUrl: edit.media.imageUrl } : {}),
          ...(edit.media.videoUrl ? { videoUrl: edit.media.videoUrl } : {}),
        };
      }
      // Apply quiz data if provided
      if (edit.quizData !== undefined && edit.quizData !== null) {
        contentItem.quizData = {
          question: edit.quizData.question,
          options: edit.quizData.options,
          correctAnswer: edit.quizData.correctAnswer,
          explanation: edit.quizData.explanation,
        };
      }
    }

    // Save previous state for history
    const previousState = {
      media: contentItem.media,
      content: contentItem.content,
    };

    // Save content item
    await this.contentItemRepository.save(contentItem);

    // Update edit status
    edit.status = ContentEditStatus.APPROVED;
    const savedEdit = await this.contentEditRepository.save(edit);

    // Create a version snapshot
    try {
      await this.contentVersionService.createVersion(
        contentItem.id,
        edit.id,
        adminUserId,
        edit.userId,
        `Version được tạo từ đóng góp: ${edit.title || edit.type}`,
      );
    } catch (error) {
      console.error('Failed to create version:', error);
      // Don't fail the approval if version creation fails
    }

    // Save userId of the original contributor before saving
    const originalContributorId = edit.userId;

    // Log history for both admin and the original contributor
    try {
      // Log history entry for admin (who performed the approval)
      await this.editHistoryService.logHistory(
        EditHistoryAction.APPROVE,
        adminUserId, // Admin who approved
        {
          contentItemId: edit.contentItemId,
          relatedEditId: edit.id,
          description: `Đã duyệt đóng góp ${edit.type === ContentEditType.ADD_VIDEO ? 'video' : edit.type === ContentEditType.ADD_IMAGE ? 'hình ảnh' : 'nội dung'}`,
          previousState,
          newState: {
            media: contentItem.media,
            content: contentItem.content,
          },
          changes: {
            type: edit.type,
            applied: true,
          },
        },
      );

      // Log history entry for the original contributor (whose edit was approved)
      if (originalContributorId !== adminUserId) {
        await this.editHistoryService.logHistory(
          EditHistoryAction.APPROVE,
          originalContributorId, // Original contributor whose edit was approved
          {
            contentItemId: edit.contentItemId,
            relatedEditId: edit.id,
            description: `Bài đóng góp ${edit.type === ContentEditType.ADD_VIDEO ? 'video' : edit.type === ContentEditType.ADD_IMAGE ? 'hình ảnh' : 'nội dung'} của bạn đã được duyệt`,
            previousState,
            newState: {
              media: contentItem.media,
              content: contentItem.content,
            },
            changes: {
              type: edit.type,
              applied: true,
              approvedBy: adminUserId,
            },
          },
        );
      }
    } catch (error) {
      console.error('Failed to log history:', error);
    }

    return savedEdit;
  }

  /**
   * Reject an edit
   */
  async rejectEdit(id: string, adminUserId: string): Promise<ContentEdit> {
    const edit = await this.getEditById(id);
    edit.status = ContentEditStatus.REJECTED;
    const savedEdit = await this.contentEditRepository.save(edit);

    // Save userId of the original contributor
    const originalContributorId = edit.userId;

    // Log history for both admin and the original contributor
    try {
      // Log history entry for admin (who performed the rejection)
      await this.editHistoryService.logHistory(
        EditHistoryAction.REJECT,
        adminUserId, // Admin who rejected
        {
          contentItemId: edit.contentItemId,
          relatedEditId: edit.id,
          description: `Đã từ chối đóng góp ${edit.type === ContentEditType.ADD_VIDEO ? 'video' : edit.type === ContentEditType.ADD_IMAGE ? 'hình ảnh' : 'nội dung'}`,
          changes: {
            type: edit.type,
            status: 'rejected',
          },
        },
      );

      // Log history entry for the original contributor (whose edit was rejected)
      if (originalContributorId !== adminUserId) {
        await this.editHistoryService.logHistory(
          EditHistoryAction.REJECT,
          originalContributorId, // Original contributor whose edit was rejected
          {
            contentItemId: edit.contentItemId,
            relatedEditId: edit.id,
            description: `Bài đóng góp ${edit.type === ContentEditType.ADD_VIDEO ? 'video' : edit.type === ContentEditType.ADD_IMAGE ? 'hình ảnh' : 'nội dung'} của bạn đã bị từ chối`,
            changes: {
              type: edit.type,
              status: 'rejected',
              rejectedBy: adminUserId,
            },
          },
        );
      }
    } catch (error) {
      console.error('Failed to log history:', error);
    }

    return savedEdit;
  }

  /**
   * Remove/Delete an approved edit (Admin only)
   * This will revert the changes applied to content item
   */
  async removeEdit(id: string, adminUserId: string): Promise<{ message: string }> {
    const edit = await this.getEditById(id);
    let contentItem = null;
    let previousState = null;

    if (edit.status === ContentEditStatus.APPROVED) {
      // Revert changes from content item
      contentItem = await this.contentItemRepository.findOne({
        where: { id: edit.contentItemId },
      });

      if (contentItem) {
        // Save state before deletion for history
        previousState = {
          contentItemMedia: contentItem.media,
          contentItemContent: contentItem.content,
        };

        // Revert media changes
        if (edit.type === ContentEditType.ADD_VIDEO && edit.media?.videoUrl) {
          // Remove video URL if it matches
          if (contentItem.media && contentItem.media['videoUrl'] === edit.media.videoUrl) {
            const media = { ...contentItem.media };
            delete media['videoUrl'];
            contentItem.media = Object.keys(media).length > 0 ? media : null;
          }
        } else if (edit.type === ContentEditType.ADD_IMAGE && edit.media?.imageUrl) {
          // Remove image URL if it matches
          if (contentItem.media && contentItem.media['imageUrl'] === edit.media.imageUrl) {
            const media = { ...contentItem.media };
            delete media['imageUrl'];
            contentItem.media = Object.keys(media).length > 0 ? media : null;
          }
        }

        await this.contentItemRepository.save(contentItem);
      }
    }

    // Save userId of the original contributor before deleting
    const originalContributorId = edit.userId;
    const editId = edit.id;

    // Delete the edit
    await this.contentEditRepository.remove(edit);

    // Log history for both admin and the original contributor
    try {
      // Log history entry for admin (who performed the removal)
      await this.editHistoryService.logHistory(
        EditHistoryAction.REMOVE,
        adminUserId, // Admin who removed
        {
          contentItemId: edit.contentItemId,
          relatedEditId: editId,
          description: `Đã gỡ đóng góp ${edit.type === ContentEditType.ADD_VIDEO ? 'video' : edit.type === ContentEditType.ADD_IMAGE ? 'hình ảnh' : 'nội dung'}`,
          previousState,
          changes: {
            type: edit.type,
            removed: true,
          },
        },
      );

      // Log history entry for the original contributor (whose edit was removed)
      if (originalContributorId !== adminUserId) {
        await this.editHistoryService.logHistory(
          EditHistoryAction.REMOVE,
          originalContributorId, // Original contributor whose edit was removed
          {
            contentItemId: edit.contentItemId,
            relatedEditId: editId,
            description: `Bài đóng góp ${edit.type === ContentEditType.ADD_VIDEO ? 'video' : edit.type === ContentEditType.ADD_IMAGE ? 'hình ảnh' : 'nội dung'} của bạn đã bị gỡ bởi admin`,
            previousState,
            changes: {
              type: edit.type,
              removed: true,
              removedBy: adminUserId,
            },
          },
        );
      }
    } catch (error) {
      console.error('Failed to log history:', error);
    }

    return { message: 'Content edit removed successfully' };
  }

  /**
   * Vote on an edit (upvote/downvote)
   */
  async voteOnEdit(
    id: string,
    userId: string,
    isUpvote: boolean,
  ): Promise<ContentEdit> {
    const edit = await this.getEditById(id);

    // Check if user already voted
    if (edit.voters.includes(userId)) {
      throw new BadRequestException('User has already voted on this edit');
    }

    // Add vote
    if (isUpvote) {
      edit.upvotes += 1;
    } else {
      edit.downvotes += 1;
    }

    edit.voters.push(userId);

    return this.contentEditRepository.save(edit);
  }

  /**
   * Get pending edits (for admin review)
   */
  async getPendingEdits(): Promise<ContentEdit[]> {
    return this.contentEditRepository.find({
      where: { status: ContentEditStatus.PENDING },
      relations: ['user', 'contentItem'],
      order: { createdAt: 'DESC' },
    });
  }

  /**
   * Get all content items with their edits (for admin management)
   */
  async getAllContentItemsWithEdits(): Promise<any[]> {
    // Get all content items
    const contentItems = await this.contentItemRepository.find({
      order: { createdAt: 'DESC' },
      relations: ['node'],
    });

    // Get all approved edits grouped by contentItemId
    const allEdits = await this.contentEditRepository.find({
      where: { status: ContentEditStatus.APPROVED },
      relations: ['user'],
      order: { createdAt: 'DESC' },
    });

    // Group edits by contentItemId
    const editsByContentId: Record<string, ContentEdit[]> = {};
    allEdits.forEach((edit) => {
      if (!editsByContentId[edit.contentItemId]) {
        editsByContentId[edit.contentItemId] = [];
      }
      editsByContentId[edit.contentItemId].push(edit);
    });

    // Combine content items with their edits
    return contentItems.map((item) => ({
      id: item.id,
      title: item.title,
      type: item.type,
      nodeId: item.nodeId,
      nodeTitle: item.node?.title || 'N/A',
      createdAt: item.createdAt,
      editsCount: editsByContentId[item.id]?.length || 0,
      edits: editsByContentId[item.id] || [],
    }));
  }

  /**
   * Get all edits submitted by a user
   */
  async getEditsByUser(userId: string): Promise<ContentEdit[]> {
    return this.contentEditRepository.find({
      where: { userId },
      relations: ['contentItem'],
      order: { createdAt: 'DESC' },
    });
  }

  /**
   * Get comparison data for an edit (before/after)
   */
  async getEditComparison(editId: string): Promise<{
    original: any;
    proposed: any;
    contentItem: ContentItem;
  }> {
    const edit = await this.getEditById(editId);
    const contentItem = await this.contentItemRepository.findOne({
      where: { id: edit.contentItemId },
    });

    if (!contentItem) {
      throw new NotFoundException('Content item not found');
    }

    // Get original snapshot (before edit)
    const original = edit.originalContentSnapshot || {
      title: contentItem.title,
      content: contentItem.content,
      richContent: (contentItem as any).richContent || null,
      textVariants: (contentItem as any).textVariants || null,
      media: contentItem.media || null,
    };

    // Get proposed changes (from edit)
    const proposed = {
      title: edit.title || original.title,
      content: edit.textContent || original.content,
      richContent: edit.richContent || original.richContent,
      textVariants: (edit as any).textVariants || original.textVariants,
      media: edit.media || original.media,
    };

    return {
      original,
      proposed,
      contentItem,
    };
  }
}

