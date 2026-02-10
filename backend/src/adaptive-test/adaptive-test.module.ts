import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdaptiveTest } from './entities/adaptive-test.entity';
import { AdaptiveTestService } from './adaptive-test.service';
import { AdaptiveTestController } from './adaptive-test.controller';
import { SubjectsModule } from '../subjects/subjects.module';
import { DomainsModule } from '../domains/domains.module';
import { LearningNodesModule } from '../learning-nodes/learning-nodes.module';
import { AiModule } from '../ai/ai.module';
import { UsersModule } from '../users/users.module';
import { PersonalMindMapModule } from '../personal-mind-map/personal-mind-map.module';
import { LessonTypeContentsModule } from '../lesson-type-contents/lesson-type-contents.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([AdaptiveTest]),
    forwardRef(() => SubjectsModule),
    forwardRef(() => DomainsModule),
    forwardRef(() => LearningNodesModule),
    AiModule,
    UsersModule,
    forwardRef(() => PersonalMindMapModule),
    LessonTypeContentsModule,
  ],
  controllers: [AdaptiveTestController],
  providers: [AdaptiveTestService],
  exports: [AdaptiveTestService],
})
export class AdaptiveTestModule {}
