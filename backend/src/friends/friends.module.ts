import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { FriendsService } from './friends.service';
import { FriendsController } from './friends.controller';
import { Friendship } from './entities/friendship.entity';
import { UserBlock } from './entities/user-block.entity';
import { FriendActivity } from './entities/friend-activity.entity';
import { User } from '../users/entities/user.entity';
import { UserCurrency } from '../user-currency/entities/user-currency.entity';
import { UserProgress } from '../user-progress/entities/user-progress.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Friendship,
      UserBlock,
      FriendActivity,
      User,
      UserCurrency,
      UserProgress,
    ]),
  ],
  controllers: [FriendsController],
  providers: [FriendsService],
  exports: [FriendsService],
})
export class FriendsModule {}
