import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserWeeklyPlan } from './entities/user-weekly-plan.entity';
import { SelfLeadershipCheckin } from './entities/self-leadership-checkin.entity';
import { UserProgress } from '../user-progress/entities/user-progress.entity';
import { SelfLeadershipController } from './self-leadership.controller';
import { SelfLeadershipService } from './self-leadership.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      UserWeeklyPlan,
      SelfLeadershipCheckin,
      UserProgress,
    ]),
  ],
  controllers: [SelfLeadershipController],
  providers: [SelfLeadershipService],
  exports: [SelfLeadershipService],
})
export class SelfLeadershipModule {}

