import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { RoadmapService } from './roadmap.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('roadmap')
@UseGuards(JwtAuthGuard)
export class RoadmapController {
  constructor(private readonly roadmapService: RoadmapService) {}

  @Post('generate')
  async generateRoadmap(
    @Request() req,
    @Body() body: { subjectId: string },
  ) {
    return this.roadmapService.generateRoadmap(req.user.id, body.subjectId);
  }

  @Get()
  async getRoadmap(@Request() req, @Body() body?: { subjectId?: string }) {
    return this.roadmapService.getRoadmap(req.user.id, body?.subjectId);
  }

  @Get(':roadmapId/today')
  async getTodayLesson(
    @Request() req,
    @Param('roadmapId') roadmapId: string,
  ) {
    return this.roadmapService.getTodayLesson(req.user.id, roadmapId);
  }

  @Post(':roadmapId/complete-day')
  async completeDay(
    @Request() req,
    @Param('roadmapId') roadmapId: string,
    @Body() body: { dayNumber: number },
  ) {
    return this.roadmapService.completeDay(
      req.user.id,
      roadmapId,
      body.dayNumber,
    );
  }
}

