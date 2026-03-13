import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { NotificationsService } from './notifications.service';
import { NotificationsController } from './notifications.controller';
import { QuoteService } from './quote.service';
import { User } from '../users/entities/user.entity';
import { UserCurrency } from '../user-currency/entities/user-currency.entity';
import { AiModule } from '../ai/ai.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, UserCurrency]),
    AiModule,
  ],
  controllers: [NotificationsController],
  providers: [NotificationsService, QuoteService],
  exports: [NotificationsService, QuoteService],
})
export class NotificationsModule {}
