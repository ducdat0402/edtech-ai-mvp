import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from '../users/entities/user.entity';
import { UserOwnedAvatarFrame } from './entities/user-owned-avatar-frame.entity';
import { UserCurrencyModule } from '../user-currency/user-currency.module';
import { AvatarFramesService } from './avatar-frames.service';
import { AvatarFramesController } from './avatar-frames.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([UserOwnedAvatarFrame, User]),
    UserCurrencyModule,
  ],
  controllers: [AvatarFramesController],
  providers: [AvatarFramesService],
  exports: [AvatarFramesService],
})
export class AvatarFramesModule {}
