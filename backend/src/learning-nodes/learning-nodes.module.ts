import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LearningNodesService } from './learning-nodes.service';
import { LessonContentService } from './lesson-content.service';
import { LearningNodesController } from './learning-nodes.controller';
import { LearningNode } from './entities/learning-node.entity';
import { UserPremium } from '../payment/entities/user-premium.entity';
import { AiModule } from '../ai/ai.module';
import { DomainsModule } from '../domains/domains.module';
import { GenerationProgressService } from './generation-progress.service';
import { LessonTypeContentsModule } from '../lesson-type-contents/lesson-type-contents.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([LearningNode, UserPremium]),
    AiModule,
    forwardRef(() => DomainsModule),
    LessonTypeContentsModule,
  ],
  controllers: [LearningNodesController],
  providers: [LearningNodesService, LessonContentService, GenerationProgressService],
  exports: [LearningNodesService, LessonContentService, GenerationProgressService],
})
export class LearningNodesModule {}

