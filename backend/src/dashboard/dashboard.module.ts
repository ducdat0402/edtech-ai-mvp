import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DashboardService } from './dashboard.service';
import { DashboardController } from './dashboard.controller';
import { UsersModule } from '../users/users.module';
import { UserCurrencyModule } from '../user-currency/user-currency.module';
import { UserProgressModule } from '../user-progress/user-progress.module';
import { SubjectsModule } from '../subjects/subjects.module';
import { LearningNodesModule } from '../learning-nodes/learning-nodes.module';
import { QuestsModule } from '../quests/quests.module';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { UserProgress } from '../user-progress/entities/user-progress.entity';
import { UnlockTransactionsModule } from '../unlock-transactions/unlock-transactions.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([LearningNode, UserProgress]),
    UsersModule,
    UserCurrencyModule,
    UserProgressModule,
    SubjectsModule,
    LearningNodesModule,
    QuestsModule,
    UnlockTransactionsModule,
  ],
  controllers: [DashboardController],
  providers: [DashboardService],
  exports: [DashboardService],
})
export class DashboardModule {}

