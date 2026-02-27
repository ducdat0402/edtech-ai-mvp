import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UnlockTransactionsService } from './unlock-transactions.service';
import { UnlockTransactionsController } from './unlock-transactions.controller';
import { UnlockTransaction } from './entities/unlock-transaction.entity';
import { UserUnlock } from './entities/user-unlock.entity';
import { UserCurrencyModule } from '../user-currency/user-currency.module';
import { SubjectsModule } from '../subjects/subjects.module';
import { DomainsModule } from '../domains/domains.module';
import { TopicsModule } from '../topics/topics.module';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([UnlockTransaction, UserUnlock, LearningNode]),
    UserCurrencyModule,
    forwardRef(() => SubjectsModule),
    forwardRef(() => DomainsModule),
    forwardRef(() => TopicsModule),
  ],
  controllers: [UnlockTransactionsController],
  providers: [UnlockTransactionsService],
  exports: [UnlockTransactionsService],
})
export class UnlockTransactionsModule {}

