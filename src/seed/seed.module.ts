import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SeedService } from './seed.service';
import { Subject } from '../subjects/entities/subject.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { Question } from '../placement-test/entities/question.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Subject, LearningNode, ContentItem, Question]),
  ],
  providers: [SeedService],
  exports: [SeedService],
})
export class SeedModule {}

