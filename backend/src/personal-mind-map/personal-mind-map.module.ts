import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PersonalMindMapController } from './personal-mind-map.controller';
import { PersonalMindMapService } from './personal-mind-map.service';
import { PersonalMindMap } from './entities/personal-mind-map.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { AiModule } from '../ai/ai.module';
import { KnowledgeGraphModule } from '../knowledge-graph/knowledge-graph.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([PersonalMindMap, LearningNode]),
    AiModule,
    KnowledgeGraphModule,
  ],
  controllers: [PersonalMindMapController],
  providers: [PersonalMindMapService],
  exports: [PersonalMindMapService],
})
export class PersonalMindMapModule {}
