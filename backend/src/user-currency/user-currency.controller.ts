import { Controller, Get, UseGuards, Request } from '@nestjs/common';
import { UserCurrencyService } from './user-currency.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('currency')
@UseGuards(JwtAuthGuard)
export class UserCurrencyController {
  constructor(private readonly currencyService: UserCurrencyService) {}

  @Get()
  async getCurrency(@Request() req) {
    const currency = await this.currencyService.getCurrency(req.user.id);
    return {
      coins: currency.coins,
      xp: currency.xp,
      currentStreak: currency.currentStreak,
      shards: currency.shards,
      lastActiveDate: currency.lastActiveDate,
    };
  }
}

