import { Controller, Get, UseGuards, Request, Query } from '@nestjs/common';
import { UserCurrencyService } from './user-currency.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RewardSource } from './entities/reward-transaction.entity';

@Controller('currency')
@UseGuards(JwtAuthGuard)
export class UserCurrencyController {
  constructor(private readonly currencyService: UserCurrencyService) {}

  @Get()
  async getCurrency(@Request() req) {
    const currency = await this.currencyService.getCurrency(req.user.id);
    const levelInfo = this.currencyService.getLevelInfo(currency.xp, currency.level || 1);
    
    return {
      coins: currency.coins,
      xp: currency.xp,
      level: currency.level || 1,
      levelInfo: {
        currentXP: levelInfo.currentXP,
        xpForNextLevel: levelInfo.xpForNextLevel,
        progress: levelInfo.progress,
      },
      currentStreak: currency.currentStreak,
      shards: currency.shards,
      lastActiveDate: currency.lastActiveDate,
    };
  }

  @Get('history')
  async getRewardsHistory(
    @Request() req,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
    @Query('source') source?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    const options: any = {};

    if (limit) {
      options.limit = parseInt(limit, 10);
    }
    if (offset) {
      options.offset = parseInt(offset, 10);
    }
    if (source && Object.values(RewardSource).includes(source as RewardSource)) {
      options.source = source as RewardSource;
    }
    if (startDate) {
      options.startDate = new Date(startDate);
    }
    if (endDate) {
      options.endDate = new Date(endDate);
    }

    return this.currencyService.getRewardsHistory(req.user.id, options);
  }
}

