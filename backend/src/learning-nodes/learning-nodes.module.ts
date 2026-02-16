import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LearningNodesService } from './learning-nodes.service';
import { LessonContentService } from './lesson-content.service';
import { LearningNodesController } from './learning-nodes.controller';
import { LearningNode } from './entities/learning-node.entity';
import { AiModule } from '../ai/ai.module';
import { DomainsModule } from '../domains/domains.module';
import { GenerationProgressService } from './generation-progress.service';
import { LessonTypeContentsModule } from '../lesson-type-contents/lesson-type-contents.module';
import { UserCurrencyModule } from '../user-currency/user-currency.module';
import { UnlockTransactionsModule } from '../unlock-transactions/unlock-transactions.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([LearningNode]),
    AiModule,
    forwardRef(() => DomainsModule),
    LessonTypeContentsModule,
    UserCurrencyModule,
    forwardRef(() => UnlockTransactionsModule),
  ],
  controllers: [LearningNodesController],
  providers: [LearningNodesService, LessonContentService, GenerationProgressService],
  exports: [LearningNodesService, LessonContentService, GenerationProgressService],
})
export class LearningNodesModule {}

