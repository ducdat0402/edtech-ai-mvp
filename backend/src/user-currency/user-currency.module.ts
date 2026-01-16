import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserCurrencyService } from './user-currency.service';
import { UserCurrencyController } from './user-currency.controller';
import { UserCurrency } from './entities/user-currency.entity';
import { RewardTransaction } from './entities/reward-transaction.entity';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([UserCurrency, RewardTransaction]),
    forwardRef(() => UsersModule),
  ],
  controllers: [UserCurrencyController],
  providers: [UserCurrencyService],
  exports: [UserCurrencyService],
})
export class UserCurrencyModule {}

