import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserProgressService } from './user-progress.service';
import { UserProgressController } from './user-progress.controller';
import { UserProgress } from './entities/user-progress.entity';
import { UserCurrencyModule } from '../user-currency/user-currency.module';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { ContentItemsModule } from '../content-items/content-items.module';
import { QuestsModule } from '../quests/quests.module';
import { SkillTreeModule } from '../skill-tree/skill-tree.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([UserProgress, LearningNode]),
    UserCurrencyModule,
    ContentItemsModule,
    forwardRef(() => QuestsModule),
    forwardRef(() => SkillTreeModule),
  ],
  controllers: [UserProgressController],
  providers: [UserProgressService],
  exports: [UserProgressService],
})
export class UserProgressModule {}

