import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { UserCurrencyModule } from './user-currency/user-currency.module';
import { UserProgressModule } from './user-progress/user-progress.module';
import { LearningNodesModule } from './learning-nodes/learning-nodes.module';
import { SubjectsModule } from './subjects/subjects.module';
import { UnlockTransactionsModule } from './unlock-transactions/unlock-transactions.module';
import { SeedModule } from './seed/seed.module';
import { DashboardModule } from './dashboard/dashboard.module';
import { AiModule } from './ai/ai.module';
import { OnboardingModule } from './onboarding/onboarding.module';
import { PlacementTestModule } from './placement-test/placement-test.module';
import { QuestsModule } from './quests/quests.module';
import { LeaderboardModule } from './leaderboard/leaderboard.module';
import { HealthModule } from './health/health.module';
import { DomainsModule } from './domains/domains.module';
import { TopicsModule } from './topics/topics.module';
import { AiAgentsModule } from './ai-agents/ai-agents.module';
import { AchievementsModule } from './achievements/achievements.module';
import { PersonalMindMapModule } from './personal-mind-map/personal-mind-map.module';
import { PaymentModule } from './payment/payment.module';
import { AdaptiveTestModule } from './adaptive-test/adaptive-test.module';
import { PendingContributionsModule } from './pending-contributions/pending-contributions.module';
import { UploadsModule } from './uploads/uploads.module';
import { LessonTypeContentsModule } from './lesson-type-contents/lesson-type-contents.module';
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
    SubjectsModule,
    UnlockTransactionsModule,
    SeedModule,
    DashboardModule,
    AiModule,
    OnboardingModule,
    PlacementTestModule,
    QuestsModule,
    LeaderboardModule,
    HealthModule,
    DomainsModule,
    TopicsModule,
    AiAgentsModule,
    AchievementsModule,
    PersonalMindMapModule,
    PaymentModule,
    AdaptiveTestModule,
    PendingContributionsModule,
    UploadsModule,
    LessonTypeContentsModule,
  ],
})
export class AppModule {}
