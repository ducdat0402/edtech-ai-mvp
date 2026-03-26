import { Body, Controller, Get, Post, Request, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { SelfLeadershipService } from './self-leadership.service';

@Controller('self-leadership')
@UseGuards(JwtAuthGuard)
export class SelfLeadershipController {
  constructor(private readonly selfLeadershipService: SelfLeadershipService) {}

  @Post('weekly-plan')
  async upsertWeeklyPlan(
    @Request() req,
    @Body()
    body: {
      targetSessions?: number;
      targetLessons?: number;
      plannedDays?: number[];
    },
  ) {
    return this.selfLeadershipService.upsertWeeklyPlan({
      userId: req.user.id,
      targetSessions: body.targetSessions,
      targetLessons: body.targetLessons,
      plannedDays: body.plannedDays,
    });
  }

  @Get('weekly-plan/current')
  async getCurrentWeeklyPlan(@Request() req) {
    return this.selfLeadershipService.getCurrentWeeklyPlan(req.user.id);
  }

  @Post('checkin')
  async submitCheckin(
    @Request() req,
    @Body()
    body: {
      nodeId?: string;
      lessonType?: string;
      followedPlan: boolean;
      deviationReason?: string;
      nextAction?: string;
    },
  ) {
    return this.selfLeadershipService.submitCheckin({
      userId: req.user.id,
      nodeId: body.nodeId,
      lessonType: body.lessonType,
      followedPlan: body.followedPlan,
      deviationReason: body.deviationReason,
      nextAction: body.nextAction,
    });
  }

  @Get('weekly-review/current')
  async getCurrentWeeklyReview(@Request() req) {
    return this.selfLeadershipService.getCurrentWeeklyReview(req.user.id);
  }
}

