import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LearningNodesService } from './learning-nodes.service';
import { LearningNodesController } from './learning-nodes.controller';
import { LearningNode } from './entities/learning-node.entity';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { AiModule } from '../ai/ai.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([LearningNode, ContentItem]),
    AiModule,
  ],
  controllers: [LearningNodesController],
  providers: [LearningNodesService],
  exports: [LearningNodesService],
})
export class LearningNodesModule {}

