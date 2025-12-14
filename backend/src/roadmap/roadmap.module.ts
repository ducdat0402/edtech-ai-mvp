import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RoadmapService } from './roadmap.service';
import { RoadmapController } from './roadmap.controller';
import { Roadmap } from './entities/roadmap.entity';
import { RoadmapDay } from './entities/roadmap-day.entity';
import { UsersModule } from '../users/users.module';
import { SubjectsModule } from '../subjects/subjects.module';
import { LearningNodesModule } from '../learning-nodes/learning-nodes.module';
import { PlacementTestModule } from '../placement-test/placement-test.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Roadmap, RoadmapDay]),
    UsersModule,
    forwardRef(() => SubjectsModule),
    LearningNodesModule,
    PlacementTestModule,
  ],
  controllers: [RoadmapController],
  providers: [RoadmapService],
  exports: [RoadmapService],
})
export class RoadmapModule {}

