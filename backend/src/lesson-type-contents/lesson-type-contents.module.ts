import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LessonTypeContent } from './entities/lesson-type-content.entity';
import { LessonTypeContentVersion } from './entities/lesson-type-content-version.entity';
import { LessonTypeContentsService } from './lesson-type-contents.service';
import { LessonTypeContentsController } from './lesson-type-contents.controller';
import { UnlockTransactionsModule } from '../unlock-transactions/unlock-transactions.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([LessonTypeContent, LessonTypeContentVersion]),
    forwardRef(() => UnlockTransactionsModule),
  ],
  controllers: [LessonTypeContentsController],
  providers: [LessonTypeContentsService],
  exports: [LessonTypeContentsService],
})
export class LessonTypeContentsModule {}
