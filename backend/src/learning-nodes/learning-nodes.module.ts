import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LearningNodesService } from './learning-nodes.service';
import { LearningNodesController } from './learning-nodes.controller';
import { LearningNode } from './entities/learning-node.entity';

@Module({
  imports: [TypeOrmModule.forFeature([LearningNode])],
  controllers: [LearningNodesController],
  providers: [LearningNodesService],
  exports: [LearningNodesService],
})
export class LearningNodesModule {}

