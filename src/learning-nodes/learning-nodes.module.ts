import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LearningNodesService } from './learning-nodes.service';
import { LearningNodesController } from './learning-nodes.controller';
import { LearningNode } from './entities/learning-node.entity';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { UserPremium } from '../payment/entities/user-premium.entity';
import { AiModule } from '../ai/ai.module';
import { DomainsModule } from '../domains/domains.module';
import { GenerationProgressService } from './generation-progress.service';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([LearningNode, ContentItem, UserPremium]),
    AiModule,
    forwardRef(() => DomainsModule),
    UsersModule, // Required for AdminGuard
  ],
  controllers: [LearningNodesController],
  providers: [LearningNodesService, GenerationProgressService],
  exports: [LearningNodesService, GenerationProgressService],
})
export class LearningNodesModule {}

