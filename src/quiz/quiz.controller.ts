import {
  Controller,
  Post,
  Body,
  UseGuards,
  Request,
  Get,
} from '@nestjs/common';
import { QuizService } from './quiz.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('quiz')
@UseGuards(JwtAuthGuard)
export class QuizController {
  constructor(private readonly quizService: QuizService) {}

  /**
   * Get quiz for a content item (concept or example)
   * Returns pre-generated quiz from DB, or generates if not exists
   */
  @Post('generate')
  async getQuiz(
    @Request() req,
    @Body() body: { contentItemId: string },
  ) {
    const quiz = await this.quizService.getQuizForContent(
      body.contentItemId,
      req.user.id,
    );
    return {
      success: true,
      data: quiz,
    };
  }

  /**
   * Get boss quiz for a learning node
   * Returns pre-generated quiz from DB, or generates if not exists
   */
  @Post('boss/generate')
  async getBossQuiz(
    @Request() req,
    @Body() body: { nodeId: string },
  ) {
    const quiz = await this.quizService.getBossQuiz(
      body.nodeId,
      req.user.id,
    );
    return {
      success: true,
      data: quiz,
    };
  }

  /**
   * Submit quiz answers
   */
  @Post('submit')
  async submitQuiz(
    @Request() req,
    @Body() body: {
      sessionId: string;
      answers: Record<string, 'A' | 'B' | 'C' | 'D'>;
    },
  ) {
    const result = await this.quizService.submitQuiz(
      body.sessionId,
      body.answers,
      req.user.id,
    );
    return {
      success: true,
      data: result,
    };
  }

  /**
   * Get quiz statistics
   */
  @Get('stats')
  async getStats() {
    const stats = await this.quizService.getQuizStats();
    return {
      success: true,
      data: stats,
    };
  }
}
