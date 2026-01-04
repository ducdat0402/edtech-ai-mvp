import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ContentEdit, ContentEditStatus, ContentEditType } from './entities/content-edit.entity';
import { ContentItem } from '../content-items/entities/content-item.entity';

@Injectable()
export class ContentEditsService {
  constructor(
    @InjectRepository(ContentEdit)
    private contentEditRepository: Repository<ContentEdit>,
    @InjectRepository(ContentItem)
    private contentItemRepository: Repository<ContentItem>,
  ) {}

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
      return savedEdit;
    } catch (error) {
      console.error('❌ Error creating content edit:', error);
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
  async approveEdit(id: string): Promise<ContentEdit> {
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

    // Apply the edit to content item
    if (edit.type === ContentEditType.ADD_VIDEO && edit.media?.videoUrl) {
      // Add video to existing media or create new media object
      contentItem.media = {
        ...(contentItem.media || {}),
        videoUrl: edit.media.videoUrl,
      };
    } else if (edit.type === ContentEditType.ADD_IMAGE && edit.media?.imageUrl) {
      // Add image to existing media or create new media object
      contentItem.media = {
        ...(contentItem.media || {}),
        imageUrl: edit.media.imageUrl,
      };
    } else if (
      edit.type === ContentEditType.UPDATE_CONTENT &&
      edit.textContent
    ) {
      // Update content text
      contentItem.content = edit.textContent;
    }

    // Save content item
    await this.contentItemRepository.save(contentItem);

    // Update edit status
    edit.status = ContentEditStatus.APPROVED;
    return this.contentEditRepository.save(edit);
  }

  /**
   * Reject an edit
   */
  async rejectEdit(id: string): Promise<ContentEdit> {
    const edit = await this.getEditById(id);
    edit.status = ContentEditStatus.REJECTED;
    return this.contentEditRepository.save(edit);
  }

  /**
   * Remove/Delete an approved edit (Admin only)
   * This will revert the changes applied to content item
   */
  async removeEdit(id: string): Promise<{ message: string }> {
    const edit = await this.getEditById(id);

    if (edit.status === ContentEditStatus.APPROVED) {
      // Revert changes from content item
      const contentItem = await this.contentItemRepository.findOne({
        where: { id: edit.contentItemId },
      });

      if (contentItem) {
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

    // Delete the edit
    await this.contentEditRepository.remove(edit);
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
}

