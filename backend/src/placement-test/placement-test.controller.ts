import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { PlacementTestService } from './placement-test.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('test')
@UseGuards(JwtAuthGuard)
export class PlacementTestController {
  constructor(private readonly testService: PlacementTestService) {}

  @Post('start')
  async startTest(
    @Request() req,
    @Body() body?: { subjectId?: string },
  ) {
    return this.testService.startTest(req.user.id, body?.subjectId);
  }

  @Get('current')
  async getCurrentTest(@Request() req) {
    const test = await this.testService.getCurrentTest(req.user.id);
    if (!test) {
      return { message: 'No active test' };
    }
    return this.testService.getCurrentQuestion(req.user.id);
  }

  @Post('submit')
  async submitAnswer(@Request() req, @Body() body: { answer: number }) {
    return this.testService.submitAnswer(req.user.id, body.answer);
  }

  @Get('result/:testId')
  async getResult(@Request() req, @Param('testId') testId: string) {
    return this.testService.getTestResult(req.user.id, testId);
  }
}

