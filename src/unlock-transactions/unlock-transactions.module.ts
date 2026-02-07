import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UnlockTransactionsService } from './unlock-transactions.service';
import { UnlockTransactionsController } from './unlock-transactions.controller';
import { UnlockTransaction } from './entities/unlock-transaction.entity';
import { UserCurrencyModule } from '../user-currency/user-currency.module';
import { SubjectsModule } from '../subjects/subjects.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([UnlockTransaction]),
    UserCurrencyModule,
    forwardRef(() => SubjectsModule),
  ],
  controllers: [UnlockTransactionsController],
  providers: [UnlockTransactionsService],
  exports: [UnlockTransactionsService],
})
export class UnlockTransactionsModule {}

