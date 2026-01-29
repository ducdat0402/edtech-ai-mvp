import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
import { UnlockTransactionsService } from './unlock-transactions.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('unlock')
@UseGuards(JwtAuthGuard)
export class UnlockTransactionsController {
  constructor(
    private readonly unlockService: UnlockTransactionsService,
  ) {}

  @Post('scholar')
  async unlockScholar(
    @Request() req,
    @Body() body: { subjectId: string; paymentAmount?: number },
  ) {
    return this.unlockService.unlockScholar(
      req.user.id,
      body.subjectId,
      body.paymentAmount,
    );
  }

  @Get('transactions')
  async getMyTransactions(@Request() req) {
    return this.unlockService.getUserTransactions(req.user.id);
  }
}

