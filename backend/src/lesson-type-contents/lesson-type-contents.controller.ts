import {
  Controller,
  ForbiddenException,
  Get,
  Param,
  Request,
  UseGuards,
} from '@nestjs/common';
import { LessonTypeContentsService } from './lesson-type-contents.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UnlockTransactionsService } from '../unlock-transactions/unlock-transactions.service';

@Controller('lesson-type-contents')
@UseGuards(JwtAuthGuard)
export class LessonTypeContentsController {
  constructor(
    private readonly lessonTypeContentsService: LessonTypeContentsService,
    private readonly unlockService: UnlockTransactionsService,
  ) {}

  /**
   * Get all lesson type contents for a learning node
   */
  @Get('node/:nodeId')
  async getByNodeId(@Param('nodeId') nodeId: string, @Request() req) {
    const userId = req.user?.id;
    const access = await this.unlockService.canAccessNode(userId, nodeId);
    if (!access.canAccess) {
      throw new ForbiddenException({
        message: 'Bài học đang bị khóa. Vui lòng mở khóa để xem nội dung.',
        ...access,
      });
    }
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
    @Request() req,
  ) {
    const userId = req.user?.id;
    const access = await this.unlockService.canAccessNode(userId, nodeId);
    if (!access.canAccess) {
      throw new ForbiddenException({
        message: 'Bài học đang bị khóa. Vui lòng mở khóa để xem nội dung.',
        ...access,
      });
    }
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
