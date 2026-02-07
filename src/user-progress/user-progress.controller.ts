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

  @Post('complete-item')
  async completeItem(
    @Request() req,
    @Body()
    body: {
      nodeId: string;
      contentItemId: string;
      itemType: 'concept' | 'example' | 'hidden_reward' | 'boss_quiz';
    },
  ) {
    const result = await this.progressService.completeContentItem(
      req.user.id,
      body.nodeId,
      body.contentItemId,
      body.itemType,
    );
    return {
      progress: result.progress,
      rewards: result.rewards,
      message: 'Content item completed successfully!',
    };
  }
}

