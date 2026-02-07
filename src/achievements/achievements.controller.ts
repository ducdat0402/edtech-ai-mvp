import {
  Controller,
  Get,
  Post,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { AchievementsService } from './achievements.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('achievements')
@UseGuards(JwtAuthGuard)
export class AchievementsController {
  constructor(private readonly achievementsService: AchievementsService) {}

  @Get()
  async getAllAchievements(@Request() req) {
    return this.achievementsService.getAchievementsWithStatus(req.user.id);
  }

  @Get('user')
  async getUserAchievements(@Request() req) {
    return this.achievementsService.getUserAchievements(req.user.id);
  }

  @Post('check')
  async checkAchievements(@Request() req) {
    const unlockedIds = await this.achievementsService.checkAndUnlockAchievements(
      req.user.id,
    );
    return {
      unlocked: unlockedIds.length,
      achievementIds: unlockedIds,
    };
  }

  @Post(':id/claim-rewards')
  async claimRewards(@Request() req, @Param('id') userAchievementId: string) {
    return this.achievementsService.claimRewards(req.user.id, userAchievementId);
  }
}

