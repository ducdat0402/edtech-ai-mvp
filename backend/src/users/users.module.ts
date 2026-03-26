import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { User } from './entities/user.entity';
import { UserCurrency } from '../user-currency/entities/user-currency.entity';
import { UserProgress } from '../user-progress/entities/user-progress.entity';
import { LearningQuizAttempt } from '../learning-nodes/entities/learning-quiz-attempt.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, UserCurrency, UserProgress, LearningQuizAttempt]),
  ],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}

