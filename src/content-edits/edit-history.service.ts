import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EditHistory, EditHistoryAction } from './entities/edit-history.entity';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { ContentEdit } from './entities/content-edit.entity';
import { In } from 'typeorm';

@Injectable()
export class EditHistoryService {
  private readonly logger = new Logger(EditHistoryService.name);

  constructor(
    @InjectRepository(EditHistory)
    private editHistoryRepository: Repository<EditHistory>,
    @InjectRepository(ContentEdit)
    private contentEditRepository: Repository<ContentEdit>,
  ) { }

  /**
   * Log a history entry
   */
  async logHistory(
    action: EditHistoryAction,
    userId: string,
    options: {
      contentItemId?: string;
      description?: string;
      changes?: Record<string, any>;
      previousState?: Record<string, any>;
      newState?: Record<string, any>;
      relatedEditId?: string;
    },
  ): Promise<EditHistory> {
    try {
      const history = this.editHistoryRepository.create({
        action,
        userId,
        contentItemId: options.contentItemId || null,
        description: options.description || this._generateDescription(action, options),
        changes: options.changes || null,
        previousState: options.previousState || null,
        newState: options.newState || null,
        relatedEditId: options.relatedEditId || null,
      });

      const saved = await this.editHistoryRepository.save(history);
      this.logger.log(`📝 Logged history: ${action} by user ${userId}`);
      return saved;
    } catch (error) {
      this.logger.error(`Failed to log history: ${error.message}`);
      // Don't throw - history logging should not break main flow
      // Return a dummy object to prevent breaking the calling code
      return null as any;
    }
  }

  /**
   * Generate human-readable description
   */
  private _generateDescription(
    action: EditHistoryAction,
    options: {
      contentItemId?: string;
      changes?: Record<string, any>;
      relatedEditId?: string;
    },
  ): string {
    switch (action) {
      case EditHistoryAction.SUBMIT:
        return `Đã gửi đóng góp mới cho bài học`;
      case EditHistoryAction.APPROVE:
        return `Đã duyệt đóng góp`;
      case EditHistoryAction.REJECT:
        return `Đã từ chối đóng góp`;
      case EditHistoryAction.REMOVE:
        return `Đã gỡ đóng góp`;
      case EditHistoryAction.CREATE:
        return `Đã tạo bài học mới`;
      case EditHistoryAction.UPDATE:
        return `Đã cập nhật bài học`;
      default:
        return `Thực hiện hành động: ${action}`;
    }
  }

  /**
   * Get history for a content item
   */
  async getHistoryForContentItem(contentItemId: string): Promise<EditHistory[]> {
    return this.editHistoryRepository.find({
      where: { contentItemId },
      relations: ['user'],
      order: { createdAt: 'DESC' },
    });
  }

  /**
   * Get history for a user
   * Only returns entries where the user is the actor (userId matches)
   */
  async getHistoryForUser(userId: string): Promise<EditHistory[]> {
    this.logger.log(`🔍 Getting history for user: ${userId}`);
    
    // Only get history entries where this user is the actor
    // Since we now log separate entries for admin and user when removing edits,
    // we only need to get entries where userId matches
    const history = await this.editHistoryRepository.find({
      where: { userId },
      relations: ['contentItem', 'user'],
      order: { createdAt: 'DESC' },
    });

    this.logger.log(`📚 Returning ${history.length} history entries for user ${userId}`);
    
    // Log details for debugging
    history.forEach((item, index) => {
      this.logger.log(`📝 Entry ${index}: action=${item.action}, userId=${item.userId}, relatedEditId=${item.relatedEditId}, description=${item.description}`);
    });
    
    return history;
  }

  /**
   * Get all history (for admin)
   * Filters out user-specific entries (entries with descriptions containing "của bạn")
   * to avoid duplicates when admin actions also create entries for users
   */
  async getAllHistory(limit: number = 100): Promise<EditHistory[]> {
    const allHistory = await this.editHistoryRepository.find({
      relations: ['user', 'contentItem'],
      order: { createdAt: 'DESC' },
      take: limit * 2, // Get more to account for filtering
    });

    // Filter out user-specific entries (entries with descriptions containing "của bạn")
    // These are entries created specifically for users, not for admin view
    const filteredHistory = allHistory.filter(
      (entry) => !entry.description?.includes('của bạn'),
    );

    // Return only the requested limit
    return filteredHistory.slice(0, limit);
  }

  /**
   * Get history for a specific edit
   */
  async getHistoryForEdit(editId: string): Promise<EditHistory[]> {
    return this.editHistoryRepository.find({
      where: { relatedEditId: editId },
      relations: ['user', 'contentItem'],
      order: { createdAt: 'DESC' },
    });
  }
}

