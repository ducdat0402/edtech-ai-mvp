import {
  Controller,
  Get,
  Post,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { WeeklyRewardsService } from './weekly-rewards.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';

@Controller('weekly-rewards')
export class WeeklyRewardsController {
  constructor(private readonly service: WeeklyRewardsService) {}

  @Get('rankings')
  @UseGuards(JwtAuthGuard)
  async getRankings(@Request() req, @Query('limit') limit?: string) {
    return this.service.getWeeklyRankings(
      limit ? parseInt(limit, 10) : 50,
      req.user.id,
    );
  }

  @Get('history')
  @UseGuards(JwtAuthGuard)
  async getHistory(
    @Request() req,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.service.getRewardHistory(
      req.user.id,
      limit ? parseInt(limit, 10) : 20,
      offset ? parseInt(offset, 10) : 0,
    );
  }

  @Get('badges')
  @UseGuards(JwtAuthGuard)
  async getBadges(@Request() req) {
    return this.service.getUserBadges(req.user.id);
  }

  @Get('badges/:userId')
  async getUserBadges(@Request() req) {
    return this.service.getUserBadges(req.params.userId);
  }

  @Get('unnotified')
  @UseGuards(JwtAuthGuard)
  async getUnnotified(@Request() req) {
    return this.service.getUnnotifiedRewards(req.user.id);
  }

  @Post('distribute')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async manualDistribute(@Query('weekCode') weekCode?: string) {
    return this.service.distributeWeeklyRewards(weekCode);
  }
}
