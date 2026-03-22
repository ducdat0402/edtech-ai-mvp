import {
  Controller,
  Get,
  Query,
  UseGuards,
  BadRequestException,
} from '@nestjs/common';
import { AnalyticsService } from './analytics.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { UserBehaviorService } from '../ai-agents/user-behavior.service';

@Controller('analytics')
@UseGuards(JwtAuthGuard, AdminGuard)
export class AnalyticsController {
  constructor(
    private readonly analyticsService: AnalyticsService,
    private readonly userBehaviorService: UserBehaviorService,
  ) {}

  @Get('overview')
  async getOverview(@Query('period') period?: string) {
    return this.analyticsService.getOverview(period || '30d');
  }

  /**
   * Admin: inspect raw AI behavior rows for any user + learning node.
   * GET /analytics/user-behaviors?userId=&nodeId=&limit=
   */
  @Get('user-behaviors')
  async getUserBehaviorsForAdmin(
    @Query('userId') userId: string,
    @Query('nodeId') nodeId: string,
    @Query('limit') limit?: string,
  ) {
    const uid = userId?.trim();
    const nid = nodeId?.trim();
    if (!uid || !nid) {
      throw new BadRequestException('userId and nodeId are required');
    }
    const lim = limit ? parseInt(limit, 10) : 50;
    return this.userBehaviorService.getNodeBehavior(
      uid,
      nid,
      Number.isFinite(lim) && lim > 0 ? lim : 50,
    );
  }
}
