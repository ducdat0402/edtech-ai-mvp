import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { UnlockTransactionsService } from './unlock-transactions.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../auth/guards/optional-jwt-auth.guard';

@Controller('unlock')
export class UnlockTransactionsController {
  constructor(
    private readonly unlockService: UnlockTransactionsService,
  ) {}

  /**
   * GET /unlock/pricing/:subjectId
   * Get full pricing info for a subject (all tiers)
   */
  @Get('pricing/:subjectId')
  @UseGuards(OptionalJwtAuthGuard)
  async getPricing(
    @Param('subjectId') subjectId: string,
    @Request() req,
  ) {
    return this.unlockService.getUnlockPricing(subjectId, req.user?.id);
  }

  /**
   * POST /unlock/subject
   * Unlock entire subject (30% discount)
   */
  @Post('subject')
  @UseGuards(JwtAuthGuard)
  async unlockSubject(
    @Request() req,
    @Body() body: { subjectId: string },
  ) {
    return this.unlockService.unlockSubject(req.user.id, body.subjectId);
  }

  /**
   * POST /unlock/domain
   * Unlock a domain/chapter (15% discount)
   */
  @Post('domain')
  @UseGuards(JwtAuthGuard)
  async unlockDomain(
    @Request() req,
    @Body() body: { domainId: string },
  ) {
    return this.unlockService.unlockDomain(req.user.id, body.domainId);
  }

  /**
   * POST /unlock/topic
   * Unlock a topic (no discount)
   */
  @Post('topic')
  @UseGuards(JwtAuthGuard)
  async unlockTopic(
    @Request() req,
    @Body() body: { topicId: string },
  ) {
    return this.unlockService.unlockTopic(req.user.id, body.topicId);
  }

  /**
   * GET /unlock/check-access/:nodeId
   * Check if user can access a specific learning node
   */
  @Get('check-access/:nodeId')
  @UseGuards(JwtAuthGuard)
  async checkAccess(
    @Param('nodeId') nodeId: string,
    @Request() req,
  ) {
    return this.unlockService.canAccessNode(req.user.id, nodeId);
  }

  /**
   * GET /unlock/my-unlocks
   * Get user's all unlocks
   */
  @Get('my-unlocks')
  @UseGuards(JwtAuthGuard)
  async getMyUnlocks(@Request() req) {
    return this.unlockService.getUserUnlocks(req.user.id);
  }

  /**
   * GET /unlock/transactions
   * Legacy: Get user's old transactions
   */
  @Get('transactions')
  @UseGuards(JwtAuthGuard)
  async getMyTransactions(@Request() req) {
    return this.unlockService.getUserTransactions(req.user.id);
  }
}
