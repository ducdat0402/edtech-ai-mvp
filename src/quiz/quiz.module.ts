import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { QuizController } from './quiz.controller';
import { QuizService } from './quiz.service';
import { Quiz } from './entities/quiz.entity';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { UserProgress } from '../user-progress/entities/user-progress.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { AiModule } from '../ai/ai.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Quiz, ContentItem, UserProgress, LearningNode]),
    AiModule,
  ],
  controllers: [QuizController],
  providers: [QuizService],
  exports: [QuizService],
})
export class QuizModule {}
