import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PendingContribution } from './entities/pending-contribution.entity';
import { PendingContributionsService } from './pending-contributions.service';
import { PendingContributionsController } from './pending-contributions.controller';
import { UsersModule } from '../users/users.module';
import { SubjectsModule } from '../subjects/subjects.module';
import { DomainsModule } from '../domains/domains.module';
import { TopicsModule } from '../topics/topics.module';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { LessonTypeContentsModule } from '../lesson-type-contents/lesson-type-contents.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([PendingContribution, LearningNode]),
    UsersModule,
    SubjectsModule,
    forwardRef(() => DomainsModule),
    forwardRef(() => TopicsModule),
    LessonTypeContentsModule,
  ],
  controllers: [PendingContributionsController],
  providers: [PendingContributionsService],
  exports: [PendingContributionsService],
})
export class PendingContributionsModule {}
