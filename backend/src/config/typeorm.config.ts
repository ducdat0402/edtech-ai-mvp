import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { TypeOrmModuleOptions, TypeOrmOptionsFactory } from '@nestjs/typeorm';
import { User } from '../users/entities/user.entity';
import { Subject } from '../subjects/entities/subject.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { UserProgress } from '../user-progress/entities/user-progress.entity';
import { UserCurrency } from '../user-currency/entities/user-currency.entity';
import { UnlockTransaction } from '../unlock-transactions/entities/unlock-transaction.entity';
import { PlacementTest } from '../placement-test/entities/placement-test.entity';
import { Question } from '../placement-test/entities/question.entity';
import { Quest } from '../quests/entities/quest.entity';
import { UserQuest } from '../quests/entities/user-quest.entity';
import { SkillTree } from '../skill-tree/entities/skill-tree.entity';
import { SkillNode } from '../skill-tree/entities/skill-node.entity';
import { UserSkillProgress } from '../skill-tree/entities/user-skill-progress.entity';
import { ContentEdit } from '../content-edits/entities/content-edit.entity';
import { EditHistory } from '../content-edits/entities/edit-history.entity';
import { ContentVersion } from '../content-edits/entities/content-version.entity';
import { Domain } from '../domains/entities/domain.entity';
import { KnowledgeNode } from '../knowledge-graph/entities/knowledge-node.entity';
import { KnowledgeEdge } from '../knowledge-graph/entities/knowledge-edge.entity';
import { UserBehavior } from '../ai-agents/entities/user-behavior.entity';
import { RewardTransaction } from '../user-currency/entities/reward-transaction.entity';
import { Achievement } from '../achievements/entities/achievement.entity';
import { UserAchievement } from '../achievements/entities/user-achievement.entity';
import { PersonalMindMap } from '../personal-mind-map/entities/personal-mind-map.entity';
import { Quiz } from '../quiz/entities/quiz.entity';
import { Payment } from '../payment/entities/payment.entity';
import { UserPremium } from '../payment/entities/user-premium.entity';
import { AdaptiveTest } from '../adaptive-test/entities/adaptive-test.entity';

@Injectable()
export class TypeOrmConfigService implements TypeOrmOptionsFactory {
  constructor(private configService: ConfigService) {}

  createTypeOrmOptions(): TypeOrmModuleOptions {
    return {
      type: 'postgres',
      url: this.configService.get<string>('DATABASE_URL'),
      entities: [
        User,
        Subject,
        LearningNode,
        ContentItem,
        UserProgress,
        UserCurrency,
        UnlockTransaction,
        PlacementTest,
        Question,
        Quest,
        UserQuest,
        SkillTree,
        SkillNode,
        UserSkillProgress,
        ContentEdit,
        EditHistory,
        ContentVersion,
        Domain,
        KnowledgeNode,
        KnowledgeEdge,
        UserBehavior,
        RewardTransaction,
        Achievement,
        UserAchievement,
        PersonalMindMap,
        Quiz,
        Payment,
        UserPremium,
        AdaptiveTest,
      ],
      synchronize: this.configService.get<string>('NODE_ENV') === 'development',
      logging: this.configService.get<string>('NODE_ENV') === 'development',
    };
  }
}

