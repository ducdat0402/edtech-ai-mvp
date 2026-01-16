import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserBehavior } from './entities/user-behavior.entity';
import { UserBehaviorService } from './user-behavior.service';
import { DrlService } from './drl.service';
import { ItsService } from './its.service';
import { LangChainService } from './langchain.service';
import { AiAgentsController } from './ai-agents.controller';
import { KnowledgeGraphModule } from '../knowledge-graph/knowledge-graph.module';
import { UserProgressModule } from '../user-progress/user-progress.module';
import { AiModule } from '../ai/ai.module';
import { LearningNodesModule } from '../learning-nodes/learning-nodes.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([UserBehavior]),
    KnowledgeGraphModule,
    UserProgressModule,
    AiModule,
    LearningNodesModule,
  ],
  controllers: [AiAgentsController],
  providers: [UserBehaviorService, DrlService, ItsService, LangChainService],
  exports: [UserBehaviorService, DrlService, ItsService, LangChainService],
})
export class AiAgentsModule {}

