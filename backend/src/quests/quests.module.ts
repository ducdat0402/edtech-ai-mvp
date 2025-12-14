import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { QuestsService } from './quests.service';
import { QuestsController } from './quests.controller';
import { Quest } from './entities/quest.entity';
import { UserQuest } from './entities/user-quest.entity';
import { UserCurrencyModule } from '../user-currency/user-currency.module';
import { UserProgressModule } from '../user-progress/user-progress.module';
import { RoadmapModule } from '../roadmap/roadmap.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Quest, UserQuest]),
    UserCurrencyModule,
    forwardRef(() => UserProgressModule),
    RoadmapModule,
  ],
  controllers: [QuestsController],
  providers: [QuestsService],
  exports: [QuestsService],
})
export class QuestsModule {}

