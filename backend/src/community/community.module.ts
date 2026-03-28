import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CommunityStatus } from './entities/community-status.entity';
import { CommunityStatusReaction } from './entities/community-status-reaction.entity';
import { CommunityStatusComment } from './entities/community-status-comment.entity';
import { CommunityService } from './community.service';
import { CommunityController } from './community.controller';
import { FriendsModule } from '../friends/friends.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      CommunityStatus,
      CommunityStatusReaction,
      CommunityStatusComment,
    ]),
    FriendsModule,
  ],
  controllers: [CommunityController],
  providers: [CommunityService],
})
export class CommunityModule {}
