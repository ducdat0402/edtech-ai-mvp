import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { UserCurrencyModule } from './user-currency/user-currency.module';
import { UserProgressModule } from './user-progress/user-progress.module';
import { LearningNodesModule } from './learning-nodes/learning-nodes.module';
import { ContentItemsModule } from './content-items/content-items.module';
import { SubjectsModule } from './subjects/subjects.module';
import { UnlockTransactionsModule } from './unlock-transactions/unlock-transactions.module';
import { SeedModule } from './seed/seed.module';
import { DashboardModule } from './dashboard/dashboard.module';
import { AiModule } from './ai/ai.module';
import { OnboardingModule } from './onboarding/onboarding.module';
import { PlacementTestModule } from './placement-test/placement-test.module';
import { RoadmapModule } from './roadmap/roadmap.module';
import { SkillTreeModule } from './skill-tree/skill-tree.module';
import { QuestsModule } from './quests/quests.module';
import { LeaderboardModule } from './leaderboard/leaderboard.module';
import { HealthModule } from './health/health.module';
import { TypeOrmConfigService } from './config/typeorm.config';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    TypeOrmModule.forRootAsync({
      useClass: TypeOrmConfigService,
    }),
    AuthModule,
    UsersModule,
    UserCurrencyModule,
    UserProgressModule,
    LearningNodesModule,
    ContentItemsModule,
    SubjectsModule,
    UnlockTransactionsModule,
    SeedModule,
    DashboardModule,
    AiModule,
    OnboardingModule,
    PlacementTestModule,
    RoadmapModule,
    SkillTreeModule,
    QuestsModule,
    LeaderboardModule,
    HealthModule,
  ],
})
export class AppModule {}

