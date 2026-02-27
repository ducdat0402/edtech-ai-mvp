import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { PaymentController } from './payment.controller';
import { PaymentService } from './payment.service';
import { Payment } from './entities/payment.entity';
import { UserPremium } from './entities/user-premium.entity';
import { UserCurrencyModule } from '../user-currency/user-currency.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Payment, UserPremium]),
    ConfigModule,
    UserCurrencyModule,
  ],
  controllers: [PaymentController],
  providers: [PaymentService],
  exports: [PaymentService],
})
export class PaymentModule {}
