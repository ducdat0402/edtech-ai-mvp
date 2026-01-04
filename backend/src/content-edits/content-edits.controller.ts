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
import { FileStorageService } from './file-storage.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { ContentEditType } from './entities/content-edit.entity';

@Controller('content-edits')
export class ContentEditsController {
  constructor(
    private readonly contentEditsService: ContentEditsService,
    private readonly fileStorageService: FileStorageService,
  ) {}

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
   * Approve an edit (Admin only)
   */
  @Put(':id/approve')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async approveEdit(@Param('id') id: string) {
    return this.contentEditsService.approveEdit(id);
  }

  /**
   * Reject an edit (Admin only)
   */
  @Put(':id/reject')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async rejectEdit(@Param('id') id: string) {
    return this.contentEditsService.rejectEdit(id);
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
  async removeEdit(@Param('id') id: string) {
    return this.contentEditsService.removeEdit(id);
  }

  /**
   * Get all content items with their edits (Admin only)
   */
  @Get('admin/all-content-with-edits')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async getAllContentItemsWithEdits() {
    return this.contentEditsService.getAllContentItemsWithEdits();
  }
}

