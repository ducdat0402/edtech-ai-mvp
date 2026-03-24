import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AnalyticsController } from './analytics.controller';
import { AnalyticsService } from './analytics.service';
import { User } from '../users/entities/user.entity';
import { UserCurrency } from '../user-currency/entities/user-currency.entity';
import { UserProgress } from '../user-progress/entities/user-progress.entity';
import { Payment } from '../payment/entities/payment.entity';
import { RewardTransaction } from '../user-currency/entities/reward-transaction.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { Subject } from '../subjects/entities/subject.entity';
import { PendingContribution } from '../pending-contributions/entities/pending-contribution.entity';
import { UsersModule } from '../users/users.module';
@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      UserCurrency,
      UserProgress,
      Payment,
      RewardTransaction,
      LearningNode,
      Subject,
      PendingContribution,
    ]),
    UsersModule,
  ],
  controllers: [AnalyticsController],
  providers: [AnalyticsService],
})
export class AnalyticsModule {}
