import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WeeklyRewardsService } from './weekly-rewards.service';
import { WeeklyRewardsController } from './weekly-rewards.controller';
import { UserBadge } from './entities/user-badge.entity';
import { WeeklyRewardHistory } from './entities/weekly-reward-history.entity';
import { UserCurrency } from '../user-currency/entities/user-currency.entity';
import { User } from '../users/entities/user.entity';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      UserBadge,
      WeeklyRewardHistory,
      UserCurrency,
      User,
    ]),
    UsersModule,
  ],
  controllers: [WeeklyRewardsController],
  providers: [WeeklyRewardsService],
  exports: [WeeklyRewardsService],
})
export class WeeklyRewardsModule {}
