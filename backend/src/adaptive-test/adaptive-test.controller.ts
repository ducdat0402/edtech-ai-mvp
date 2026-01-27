import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdaptiveTestService } from './adaptive-test.service';

@Controller('adaptive-test')
@UseGuards(JwtAuthGuard)
export class AdaptiveTestController {
  constructor(private readonly testService: AdaptiveTestService) {}

  /**
   * Start a new adaptive placement test for a subject
   * POST /adaptive-test/start/:subjectId
   */
  @Post('start/:subjectId')
  async startTest(@Request() req, @Param('subjectId') subjectId: string) {
    return this.testService.startTest(req.user.id, subjectId);
  }

  /**
   * Submit answer for current question
   * POST /adaptive-test/:testId/submit
   */
  @Post(':testId/submit')
  async submitAnswer(
    @Request() req,
    @Param('testId') testId: string,
    @Body() body: { answer: number },
  ) {
    return this.testService.submitAnswer(testId, req.user.id, body.answer);
  }

  /**
   * Get test result
   * GET /adaptive-test/:testId/result
   */
  @Get(':testId/result')
  async getTestResult(@Request() req, @Param('testId') testId: string) {
    return this.testService.getTestResult(testId, req.user.id);
  }
}
