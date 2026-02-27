import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { UserProgressService } from './user-progress.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('progress')
@UseGuards(JwtAuthGuard)
export class UserProgressController {
  constructor(private readonly progressService: UserProgressService) {}

  @Get('node/:nodeId')
  async getNodeProgress(@Request() req, @Param('nodeId') nodeId: string) {
    return this.progressService.getUserNodeProgress(req.user.id, nodeId);
  }

  /**
   * Complete a specific lesson type and trigger cascade (lesson -> topic -> domain)
   */
  @Post('complete-lesson-type')
  async completeLessonType(
    @Request() req,
    @Body() body: { nodeId: string; lessonType: string },
  ) {
    const result = await this.progressService.completeLessonType(
      req.user.id,
      body.nodeId,
      body.lessonType,
    );

    // Summarize total rewards from all levels
    const totalXp = result.rewards.reduce((sum, r) => sum + r.xp, 0);
    const totalCoins = result.rewards.reduce((sum, r) => sum + r.coins, 0);

    return {
      progress: result.progress,
      rewards: result.rewards,
      totalRewards: { xp: totalXp, coins: totalCoins },
      lessonCompleted: result.lessonCompleted,
      topicCompleted: result.topicCompleted,
      domainCompleted: result.domainCompleted,
      message: result.lessonCompleted
        ? 'Hoàn thành bài học! Nhận thưởng thành công.'
        : 'Hoàn thành dạng bài học.',
    };
  }

  /**
   * Get lesson type progress for a node (which types completed)
   */
  @Get('lesson/:nodeId/types')
  async getLessonTypeProgress(
    @Request() req,
    @Param('nodeId') nodeId: string,
  ) {
    return this.progressService.getLessonTypeProgress(req.user.id, nodeId);
  }

  /**
   * Get topic progress for a user
   */
  @Get('topic/:topicId')
  async getTopicProgress(
    @Request() req,
    @Param('topicId') topicId: string,
  ) {
    return this.progressService.getTopicProgress(req.user.id, topicId);
  }

  /**
   * Get domain progress for a user
   */
  @Get('domain/:domainId')
  async getDomainProgress(
    @Request() req,
    @Param('domainId') domainId: string,
  ) {
    return this.progressService.getDomainProgress(req.user.id, domainId);
  }

  /**
   * Legacy: Mark a node as completed (kept for backward compatibility)
   */
  @Post('complete-node')
  async completeNode(
    @Request() req,
    @Body() body: { nodeId: string },
  ) {
    const result = await this.progressService.completeNode(
      req.user.id,
      body.nodeId,
    );
    return {
      progress: result.progress,
      rewards: result.rewards,
      message: 'Node completed successfully!',
    };
  }
}
