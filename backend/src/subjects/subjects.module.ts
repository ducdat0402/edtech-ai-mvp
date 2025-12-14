import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SubjectsService } from './subjects.service';
import { SubjectsController } from './subjects.controller';
import { Subject } from './entities/subject.entity';
import { UserProgressModule } from '../user-progress/user-progress.module';
import { LearningNodesModule } from '../learning-nodes/learning-nodes.module';
import { UserCurrencyModule } from '../user-currency/user-currency.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Subject]),
    forwardRef(() => UserProgressModule),
    LearningNodesModule,
    UserCurrencyModule,
  ],
  controllers: [SubjectsController],
  providers: [SubjectsService],
  exports: [SubjectsService],
})
export class SubjectsModule {}

