import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ContentItemsService } from './content-items.service';
import { ContentItemsController } from './content-items.controller';
import { ContentItem } from './entities/content-item.entity';
import { LearningNodesModule } from '../learning-nodes/learning-nodes.module';
import { AiModule } from '../ai/ai.module';
import { ContentImportService } from './content-import.service';
import { FileParserService } from './file-parser.service';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([ContentItem, LearningNode]),
    LearningNodesModule,
    AiModule,
  ],
  controllers: [ContentItemsController],
  providers: [ContentItemsService, ContentImportService, FileParserService],
  exports: [ContentItemsService, ContentImportService, FileParserService],
})
export class ContentItemsModule {}

