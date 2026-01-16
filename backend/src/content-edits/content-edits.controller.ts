import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  Request,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ContentEditsService } from './content-edits.service';
import { EditHistoryService } from './edit-history.service';
import { ContentVersionService } from './content-version.service';
import { FileStorageService } from './file-storage.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { ContentEditType } from './entities/content-edit.entity';

@Controller('content-edits')
export class ContentEditsController {
  constructor(
    private readonly contentEditsService: ContentEditsService,
    private readonly editHistoryService: EditHistoryService,
    private readonly contentVersionService: ContentVersionService,
    private readonly fileStorageService: FileStorageService,
  ) { }

  /**
   * Submit a new content edit
   */
  @Post('content/:contentItemId/submit')
  @UseGuards(JwtAuthGuard)
  async submitEdit(
    @Param('contentItemId') contentItemId: string,
    @Request() req: any,
    @Body()
    body: {
      type: ContentEditType;
      videoUrl?: string;
      imageUrl?: string;
      textContent?: string;
      description?: string;
      caption?: string;
    },
  ) {
    return this.contentEditsService.submitEdit(
      contentItemId,
      req.user.id,
      body.type,
      {
        videoUrl: body.videoUrl,
        imageUrl: body.imageUrl,
        textContent: body.textContent,
        description: body.description,
        caption: body.caption,
      },
    );
  }

  /**
   * Upload image for content edit
   */
  @Post('upload-image')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('image'))
  async uploadImage(@UploadedFile() file: Express.Multer.File) {
    const imageUrl = await this.fileStorageService.saveImage(file);
    return {
      imageUrl,
      message: 'Image uploaded successfully',
    };
  }

  /**
   * Upload video for content edit
   */
  @Post('upload-video')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('video'))
  async uploadVideo(@UploadedFile() file: Express.Multer.File) {
    const videoUrl = await this.fileStorageService.saveVideo(file);
    return {
      videoUrl,
      message: 'Video uploaded successfully',
    };
  }

  /**
   * Submit a community edit for a lesson (full lesson edit)
   */
  @Post('content/:contentItemId/lesson-edit')
  @UseGuards(JwtAuthGuard)
  async submitLessonEdit(
    @Param('contentItemId') contentItemId: string,
    @Request() req: any,
    @Body()
    body: {
      title: string;
      richContent?: any; // JSON from flutter_quill (optional for quiz)
      imageUrls?: string[];
      videoUrl?: string;
      description?: string;
      quizData?: {
        question?: string;
        options?: string[];
        correctAnswer?: number;
        explanation?: string;
      };
    },
  ) {
    return this.contentEditsService.submitLessonEdit(
      contentItemId,
      req.user.id,
      body,
    );
  }

  /**
   * Get all edits for a content item
   */
  @Get('content/:contentItemId')
  async getEditsForContent(
    @Param('contentItemId') contentItemId: string,
    @Body() body?: { includePending?: boolean },
  ) {
    return this.contentEditsService.getEditsForContent(
      contentItemId,
      body?.includePending || false,
    );
  }

  /**
   * Get edit by ID
   */
  @Get(':id')
  async getEditById(@Param('id') id: string) {
    return this.contentEditsService.getEditById(id);
  }

  /**
   * Get comparison data for an edit (before/after)
   */
  @Get(':id/comparison')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async getEditComparison(@Param('id') id: string) {
    return this.contentEditsService.getEditComparison(id);
  }

  /**
   * Approve an edit (Admin only)
   */
  @Put(':id/approve')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async approveEdit(@Param('id') id: string, @Request() req: any) {
    return this.contentEditsService.approveEdit(id, req.user.id);
  }

  /**
   * Reject an edit (Admin only)
   */
  @Put(':id/reject')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async rejectEdit(@Param('id') id: string, @Request() req: any) {
    return this.contentEditsService.rejectEdit(id, req.user.id);
  }

  /**
   * Vote on an edit
   */
  @Post(':id/vote')
  @UseGuards(JwtAuthGuard)
  async voteOnEdit(
    @Param('id') id: string,
    @Request() req: any,
    @Body() body: { isUpvote: boolean },
  ) {
    return this.contentEditsService.voteOnEdit(id, req.user.id, body.isUpvote);
  }

  /**
   * Get pending edits (Admin only)
   */
  @Get('pending/list')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async getPendingEdits() {
    return this.contentEditsService.getPendingEdits();
  }

  /**
   * Remove/Delete an approved edit (Admin only)
   * This will revert changes applied to content item
   */
  @Delete(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async removeEdit(@Param('id') id: string, @Request() req: any) {
    return this.contentEditsService.removeEdit(id, req.user.id);
  }

  /**
   * Get all content items with their edits (Admin only)
   */
  @Get('admin/all-content-with-edits')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async getAllContentItemsWithEdits() {
    return this.contentEditsService.getAllContentItemsWithEdits();
  }

  /**
   * Get edit history for a content item
   */
  @Get('history/content/:contentItemId')
  @UseGuards(JwtAuthGuard)
  async getHistoryForContent(@Param('contentItemId') contentItemId: string) {
    return this.editHistoryService.getHistoryForContentItem(contentItemId);
  }

  /**
   * Get edit history for current user
   */
  @Get('history/user')
  @UseGuards(JwtAuthGuard)
  async getHistoryForUser(@Request() req: any) {
    return this.editHistoryService.getHistoryForUser(req.user.id);
  }

  /**
   * Get edits submitted by the current user
   */
  @Get('user/my-edits')
  @UseGuards(JwtAuthGuard)
  async getMyEdits(@Request() req: any) {
    return this.contentEditsService.getEditsByUser(req.user.id);
  }

  /**
   * Get all edit history (Admin only)
   */
  @Get('history/all')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async getAllHistory() {
    return this.editHistoryService.getAllHistory();
  }

  /**
   * Get edit history for a specific edit
   */
  @Get('history/edit/:editId')
  @UseGuards(JwtAuthGuard)
  async getHistoryForEdit(@Param('editId') editId: string) {
    return this.editHistoryService.getHistoryForEdit(editId);
  }

  /**
   * Debug endpoint - Get all edit history for debugging
   */
  @Get('debug/history')
  @UseGuards(JwtAuthGuard)
  async debugHistory(@Request() req: any) {
    const userId = req.user.id;
    
    // Get all history for this user
    const userHistory = await this.editHistoryService.getHistoryForUser(userId);
    
    // Get all history entries (for comparison)
    const allHistory = await this.editHistoryService.getAllHistory(50);
    
    // Filter all history to find entries related to this user
    const relatedToUser = allHistory.filter(entry => 
      entry.userId === userId || 
      (entry.relatedEditId && userHistory.some(uh => uh.relatedEditId === entry.relatedEditId))
    );
    
    return {
      userId,
      userHistoryCount: userHistory.length,
      allHistoryCount: allHistory.length,
      relatedToUserCount: relatedToUser.length,
      userHistory,
      relatedToUser,
      allHistory: allHistory.slice(0, 10) // First 10 for comparison
    };
  }

  /**
   * Get all versions for a content item (Admin only)
   */
  @Get('content/:contentItemId/versions')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async getVersionsForContent(@Param('contentItemId') contentItemId: string) {
    return this.contentVersionService.getVersionsForContent(contentItemId);
  }

  /**
   * Get versions created by current user
   */
  @Get('versions/my-versions')
  @UseGuards(JwtAuthGuard)
  async getMyVersions(
    @Request() req: any,
    @Body() body?: { contentItemId?: string },
  ) {
    return this.contentVersionService.getVersionsByUser(
      req.user.id,
      body?.contentItemId,
    );
  }

  /**
   * Get versions for a specific content item (User)
   */
  @Get('content/:contentItemId/my-versions')
  @UseGuards(JwtAuthGuard)
  async getMyVersionsForContent(
    @Param('contentItemId') contentItemId: string,
    @Request() req: any,
  ) {
    return this.contentVersionService.getVersionsByUser(
      req.user.id,
      contentItemId,
    );
  }

  /**
   * Revert to a specific version (Admin only)
   */
  @Post('versions/:versionId/revert')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async revertToVersion(
    @Param('versionId') versionId: string,
    @Request() req: any,
  ) {
    return this.contentVersionService.revertToVersion(versionId, req.user.id);
  }
}

