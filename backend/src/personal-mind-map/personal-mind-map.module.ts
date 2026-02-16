import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PersonalMindMapController } from './personal-mind-map.controller';
import { PersonalMindMapService } from './personal-mind-map.service';
import { PersonalMindMap } from './entities/personal-mind-map.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { AiModule } from '../ai/ai.module';
import { DomainsModule } from '../domains/domains.module';
import { UnlockTransactionsModule } from '../unlock-transactions/unlock-transactions.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([PersonalMindMap, LearningNode]),
    AiModule,
    DomainsModule,
    forwardRef(() => UnlockTransactionsModule),
  ],
  controllers: [PersonalMindMapController],
  providers: [PersonalMindMapService],
  exports: [PersonalMindMapService],
})
export class PersonalMindMapModule {}
