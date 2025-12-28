import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PlacementTestService } from './placement-test.service';
import { PlacementTestController } from './placement-test.controller';
import { PlacementTest } from './entities/placement-test.entity';
import { Question } from './entities/question.entity';
import { UsersModule } from '../users/users.module';
import { SubjectsModule } from '../subjects/subjects.module';
import { AiModule } from '../ai/ai.module';
import { SkillTreeModule } from '../skill-tree/skill-tree.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([PlacementTest, Question]),
    UsersModule,
    SubjectsModule,
    AiModule,
    forwardRef(() => SkillTreeModule),
  ],
  controllers: [PlacementTestController],
  providers: [PlacementTestService],
  exports: [PlacementTestService],
})
export class PlacementTestModule {}

