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
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ContentItemsService } from './content-items.service';
import { ContentImportService } from './content-import.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('content')
export class ContentItemsController {
  constructor(
    private readonly contentService: ContentItemsService,
    private readonly importService: ContentImportService,
  ) {}

  @Get('node/:nodeId')
  async getContentByNode(@Param('nodeId') nodeId: string) {
    return this.contentService.findByNode(nodeId);
  }

  @Get(':id')
  async getContentById(@Param('id') id: string) {
    return this.contentService.findById(id);
  }

  /**
   * Import raw text and generate multiple concepts using AI
   */
  @Post('node/:nodeId/import-concepts')
  @UseGuards(JwtAuthGuard)
  async importConcepts(
    @Param('nodeId') nodeId: string,
    @Body() body: { rawText: string; topic: string; count?: number },
  ) {
    return this.importService.importRawTextToConcepts(
      nodeId,
      body.rawText,
      body.topic,
      body.count || 5,
    );
  }

  /**
   * Generate a single concept from raw text
   */
  @Post('node/:nodeId/generate-concept')
  @UseGuards(JwtAuthGuard)
  async generateConcept(
    @Param('nodeId') nodeId: string,
    @Body()
    body: {
      rawText: string;
      topic: string;
      difficulty?: 'beginner' | 'intermediate' | 'advanced';
    },
  ) {
    return this.importService.generateSingleConcept(
      nodeId,
      body.rawText,
      body.topic,
      body.difficulty || 'beginner',
    );
  }

  /**
   * Generate examples from raw text
   */
  @Post('node/:nodeId/generate-examples')
  @UseGuards(JwtAuthGuard)
  async generateExamples(
    @Param('nodeId') nodeId: string,
    @Body() body: { rawText: string; topic: string; count?: number },
  ) {
    return this.importService.generateExamples(
      nodeId,
      body.rawText,
      body.topic,
      body.count || 3,
    );
  }

  /**
   * Upload file (PDF, DOCX, TXT) and import as concepts
   */
  @Post('node/:nodeId/import-file')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('file'))
  async importFromFile(
    @Param('nodeId') nodeId: string,
    @UploadedFile() file: Express.Multer.File,
    @Body() body: { topic: string; count?: number },
  ) {
    return this.importService.importFromFile(
      nodeId,
      file,
      body.topic,
      body.count || 5,
    );
  }

  /**
   * Upload file and generate single concept
   */
  @Post('node/:nodeId/generate-concept-from-file')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('file'))
  async generateConceptFromFile(
    @Param('nodeId') nodeId: string,
    @UploadedFile() file: Express.Multer.File,
    @Body()
    body: {
      topic: string;
      difficulty?: 'beginner' | 'intermediate' | 'advanced';
    },
  ) {
    return this.importService.generateConceptFromFile(
      nodeId,
      file,
      body.topic,
      body.difficulty || 'beginner',
    );
  }

  /**
   * Upload file and generate examples
   */
  @Post('node/:nodeId/generate-examples-from-file')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('file'))
  async generateExamplesFromFile(
    @Param('nodeId') nodeId: string,
    @UploadedFile() file: Express.Multer.File,
    @Body() body: { topic: string; count?: number },
  ) {
    return this.importService.generateExamplesFromFile(
      nodeId,
      file,
      body.topic,
      body.count || 3,
    );
  }

  /**
   * Preview file content (parse file but don't generate concepts)
   */
  @Post('preview-file')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('file'))
  async previewFile(@UploadedFile() file: Express.Multer.File) {
    return this.importService.previewFile(file);
  }

  /**
   * Preview raw text (estimate concepts without generating)
   */
  @Post('preview-text')
  @UseGuards(JwtAuthGuard)
  async previewText(@Body() body: { rawText: string; topic: string }) {
    return this.importService.previewText(body.rawText, body.topic);
  }

  /**
   * Update content item
   */
  @Put(':id')
  @UseGuards(JwtAuthGuard)
  async update(
    @Param('id') id: string,
    @Body()
    body: {
      title?: string;
      content?: string;
      order?: number;
      rewards?: { xp?: number; coin?: number; shard?: string; shardAmount?: number };
      media?: { videoUrl?: string; imageUrl?: string; interactiveUrl?: string };
      quizData?: {
        question?: string;
        options?: string[];
        correctAnswer?: number;
        explanation?: string;
      };
    },
  ) {
    return this.contentService.update(id, body);
  }

  /**
   * Delete content item
   */
  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  async delete(@Param('id') id: string) {
    await this.contentService.delete(id);
    return { message: 'Content item deleted successfully' };
  }

  /**
   * Reorder content items in a node
   */
  @Post('node/:nodeId/reorder')
  @UseGuards(JwtAuthGuard)
  async reorder(
    @Param('nodeId') nodeId: string,
    @Body() body: { itemIds: string[] },
  ) {
    return this.contentService.reorder(nodeId, body.itemIds);
  }
}

