import {
  Controller,
  Get,
  Param,
  UseGuards,
} from '@nestjs/common';
import { LessonTypeContentsService } from './lesson-type-contents.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('lesson-type-contents')
@UseGuards(JwtAuthGuard)
export class LessonTypeContentsController {
  constructor(
    private readonly lessonTypeContentsService: LessonTypeContentsService,
  ) {}

  /**
   * Get all lesson type contents for a learning node
   */
  @Get('node/:nodeId')
  async getByNodeId(@Param('nodeId') nodeId: string) {
    const contents = await this.lessonTypeContentsService.getByNodeId(nodeId);
    const availableTypes = contents.map((c) => c.lessonType);
    return {
      nodeId,
      totalTypes: contents.length,
      availableTypes,
      contents,
    };
  }

  /**
   * Get a specific lesson type content for a node
   */
  @Get('node/:nodeId/:lessonType')
  async getByNodeIdAndType(
    @Param('nodeId') nodeId: string,
    @Param('lessonType') lessonType: string,
  ) {
    const content = await this.lessonTypeContentsService.getByNodeIdAndType(
      nodeId,
      lessonType,
    );
    if (!content) {
      return { found: false, nodeId, lessonType };
    }
    return { found: true, content };
  }

  /**
   * Get version history for a specific lesson type of a node
   */
  @Get('node/:nodeId/:lessonType/history')
  async getHistory(
    @Param('nodeId') nodeId: string,
    @Param('lessonType') lessonType: string,
  ) {
    const versions = await this.lessonTypeContentsService.getHistory(
      nodeId,
      lessonType,
    );
    return {
      nodeId,
      lessonType,
      totalVersions: versions.length,
      versions,
    };
  }

  /**
   * Get a specific version by ID
   */
  @Get('history/:id')
  async getVersionById(@Param('id') id: string) {
    return this.lessonTypeContentsService.getVersionById(id);
  }
}
