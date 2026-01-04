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
import { Roadmap } from '../roadmap/entities/roadmap.entity';
import { RoadmapDay } from '../roadmap/entities/roadmap-day.entity';
import { Quest } from '../quests/entities/quest.entity';
import { UserQuest } from '../quests/entities/user-quest.entity';
import { SkillTree } from '../skill-tree/entities/skill-tree.entity';
import { SkillNode } from '../skill-tree/entities/skill-node.entity';
import { UserSkillProgress } from '../skill-tree/entities/user-skill-progress.entity';
import { ContentEdit } from '../content-edits/entities/content-edit.entity';

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
        Roadmap,
        RoadmapDay,
        Quest,
        UserQuest,
        SkillTree,
        SkillNode,
        UserSkillProgress,
        ContentEdit,
      ],
      synchronize: this.configService.get<string>('NODE_ENV') === 'development',
      logging: this.configService.get<string>('NODE_ENV') === 'development',
    };
  }
}

