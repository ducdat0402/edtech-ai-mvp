import {
  Controller,
  Get,
  Query,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { LeaderboardService } from './leaderboard.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('leaderboard')
export class LeaderboardController {
  constructor(private readonly leaderboardService: LeaderboardService) {}

  @Get('global')
  async getGlobalLeaderboard(
    @Query('limit') limit?: string,
    @Query('page') page?: string,
    @Request() req: any = {},
  ) {
    const limitNum = limit ? parseInt(limit, 10) : 100;
    const pageNum = page ? parseInt(page, 10) : 1;
    const userId = req?.user?.id;

    return this.leaderboardService.getGlobalLeaderboard(
      limitNum,
      pageNum,
      userId,
    );
  }

  @Get('weekly')
  @UseGuards(JwtAuthGuard)
  async getWeeklyLeaderboard(
    @Request() req,
    @Query('limit') limit?: string,
    @Query('page') page?: string,
  ) {
    const limitNum = limit ? parseInt(limit, 10) : 100;
    const pageNum = page ? parseInt(page, 10) : 1;

    return this.leaderboardService.getWeeklyLeaderboard(
      limitNum,
      pageNum,
      req.user.id,
    );
  }

  @Get('subject/:subjectId')
  @UseGuards(JwtAuthGuard)
  async getSubjectLeaderboard(
    @Request() req,
    @Param('subjectId') subjectId: string,
    @Query('limit') limit?: string,
    @Query('page') page?: string,
  ) {
    const limitNum = limit ? parseInt(limit, 10) : 100;
    const pageNum = page ? parseInt(page, 10) : 1;

    return this.leaderboardService.getSubjectLeaderboard(
      subjectId,
      limitNum,
      pageNum,
      req.user.id,
    );
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getMyRank(@Request() req) {
    return this.leaderboardService.getUserRank(req.user.id);
  }
}

