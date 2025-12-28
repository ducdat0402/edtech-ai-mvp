import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SkillTreeService } from './skill-tree.service';
import { SkillTreeController } from './skill-tree.controller';
import { SkillTree } from './entities/skill-tree.entity';
import { SkillNode } from './entities/skill-node.entity';
import { UserSkillProgress } from './entities/user-skill-progress.entity';
import { UsersModule } from '../users/users.module';
import { SubjectsModule } from '../subjects/subjects.module';
import { LearningNodesModule } from '../learning-nodes/learning-nodes.module';
import { UserCurrencyModule } from '../user-currency/user-currency.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([SkillTree, SkillNode, UserSkillProgress]),
    UsersModule,
    forwardRef(() => SubjectsModule),
    LearningNodesModule,
    UserCurrencyModule,
  ],
  controllers: [SkillTreeController],
  providers: [SkillTreeService],
  exports: [SkillTreeService],
})
export class SkillTreeModule {}

