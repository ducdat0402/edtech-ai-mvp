import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SubjectsService } from './subjects.service';
import { SubjectsController } from './subjects.controller';
import { Subject } from './entities/subject.entity';
import { UserProgressModule } from '../user-progress/user-progress.module';
import { LearningNodesModule } from '../learning-nodes/learning-nodes.module';
import { UserCurrencyModule } from '../user-currency/user-currency.module';
import { SubjectLearningGoalsService } from './subject-learning-goals.service';
import { AiModule } from '../ai/ai.module';
import { DomainsModule } from '../domains/domains.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Subject]),
    forwardRef(() => UserProgressModule),
    forwardRef(() => LearningNodesModule),
    UserCurrencyModule,
    AiModule,
    forwardRef(() => DomainsModule),
  ],
  controllers: [SubjectsController],
  providers: [SubjectsService, SubjectLearningGoalsService],
  exports: [SubjectsService, SubjectLearningGoalsService],
})
export class SubjectsModule {}

