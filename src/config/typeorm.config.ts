import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { TypeOrmModuleOptions, TypeOrmOptionsFactory } from '@nestjs/typeorm';
import { User } from '../users/entities/user.entity';
import { Subject } from '../subjects/entities/subject.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { UserProgress } from '../user-progress/entities/user-progress.entity';
import { UserCurrency } from '../user-currency/entities/user-currency.entity';
import { UnlockTransaction } from '../unlock-transactions/entities/unlock-transaction.entity';
import { UserUnlock } from '../unlock-transactions/entities/user-unlock.entity';
import { PlacementTest } from '../placement-test/entities/placement-test.entity';
import { Question } from '../placement-test/entities/question.entity';
import { Quest } from '../quests/entities/quest.entity';
import { UserQuest } from '../quests/entities/user-quest.entity';
import { Domain } from '../domains/entities/domain.entity';
import { Topic } from '../topics/entities/topic.entity';
import { UserBehavior } from '../ai-agents/entities/user-behavior.entity';
import { RewardTransaction } from '../user-currency/entities/reward-transaction.entity';
import { Achievement } from '../achievements/entities/achievement.entity';
import { UserAchievement } from '../achievements/entities/user-achievement.entity';
import { PersonalMindMap } from '../personal-mind-map/entities/personal-mind-map.entity';
import { Payment } from '../payment/entities/payment.entity';
import { UserPremium } from '../payment/entities/user-premium.entity';
import { AdaptiveTest } from '../adaptive-test/entities/adaptive-test.entity';
import { PendingContribution } from '../pending-contributions/entities/pending-contribution.entity';
import { LessonTypeContent } from '../lesson-type-contents/entities/lesson-type-content.entity';
import { LessonTypeContentVersion } from '../lesson-type-contents/entities/lesson-type-content-version.entity';
import { UserTopicProgress } from '../user-progress/entities/user-topic-progress.entity';
import { UserDomainProgress } from '../user-progress/entities/user-domain-progress.entity';

@Injectable()
export class TypeOrmConfigService implements TypeOrmOptionsFactory {
  constructor(private configService: ConfigService) {}

  createTypeOrmOptions(): TypeOrmModuleOptions {
    return {
      type: 'postgres',
      url: this.configService.get<string>('DATABASE_URL'),
      ssl: {
        rejectUnauthorized: false, // thêm cái này
        requestCert: false,        // thêm cái này
      },
      extra: {
        ssl: {
          rejectUnauthorized: false, // thêm cái này nữa
        },
      },
      entities: [
        User,
        Subject,
        LearningNode,
        UserProgress,
        UserCurrency,
        UnlockTransaction,
        UserUnlock,
        PlacementTest,
        Question,
        Quest,
        UserQuest,
        Domain,
        Topic,
        UserBehavior,
        RewardTransaction,
        Achievement,
        UserAchievement,
        PersonalMindMap,
        Payment,
        UserPremium,
        AdaptiveTest,
        PendingContribution,
        LessonTypeContent,
        LessonTypeContentVersion,
        UserTopicProgress,
        UserDomainProgress,
      ],
      synchronize: this.configService.get<string>('NODE_ENV') === 'development',
      logging: this.configService.get<string>('NODE_ENV') === 'development',
    };
  }
}
