import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserProgressService } from './user-progress.service';
import { UserProgressController } from './user-progress.controller';
import { UserProgress } from './entities/user-progress.entity';
import { UserTopicProgress } from './entities/user-topic-progress.entity';
import { UserDomainProgress } from './entities/user-domain-progress.entity';
import { UserCurrencyModule } from '../user-currency/user-currency.module';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { QuestsModule } from '../quests/quests.module';
import { LessonTypeContentsModule } from '../lesson-type-contents/lesson-type-contents.module';
import { Topic } from '../topics/entities/topic.entity';
import { Domain } from '../domains/entities/domain.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      UserProgress,
      UserTopicProgress,
      UserDomainProgress,
      LearningNode,
      Topic,
      Domain,
    ]),
    UserCurrencyModule,
    forwardRef(() => QuestsModule),
    LessonTypeContentsModule,
  ],
  controllers: [UserProgressController],
  providers: [UserProgressService],
  exports: [UserProgressService],
})
export class UserProgressModule {}
