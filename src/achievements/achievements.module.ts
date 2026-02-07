import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AchievementsService } from './achievements.service';
import { AchievementsController } from './achievements.controller';
import { Achievement } from './entities/achievement.entity';
import { UserAchievement } from './entities/user-achievement.entity';
import { UserCurrencyModule } from '../user-currency/user-currency.module';
import { UserProgressModule } from '../user-progress/user-progress.module';
import { QuestsModule } from '../quests/quests.module';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Achievement, UserAchievement]),
    UserCurrencyModule,
    forwardRef(() => UserProgressModule),
    forwardRef(() => QuestsModule),
    forwardRef(() => UsersModule),
  ],
  controllers: [AchievementsController],
  providers: [AchievementsService],
  exports: [AchievementsService],
})
export class AchievementsModule {}

