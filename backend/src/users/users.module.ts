import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { User } from './entities/user.entity';
import { UserCurrency } from '../user-currency/entities/user-currency.entity';
import { UserProgress } from '../user-progress/entities/user-progress.entity';
import { LearningQuizAttempt } from '../learning-nodes/entities/learning-quiz-attempt.entity';
import { LearningCommunicationAttempt } from '../learning-nodes/entities/learning-communication-attempt.entity';
import { UserWeeklyPlan } from '../self-leadership/entities/user-weekly-plan.entity';
import { SelfLeadershipCheckin } from '../self-leadership/entities/self-leadership-checkin.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      UserCurrency,
      UserProgress,
      LearningQuizAttempt,
      LearningCommunicationAttempt,
      UserWeeklyPlan,
      SelfLeadershipCheckin,
    ]),
  ],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}

