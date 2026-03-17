import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { DirectMessage } from './entities/direct-message.entity';
import { DmService } from './dm.service';
import { DmController } from './dm.controller';
import { DmGateway } from './dm.gateway';
import { FriendsModule } from '../friends/friends.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([DirectMessage]),
    FriendsModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_SECRET'),
        signOptions: {
          expiresIn: configService.get<string>('JWT_EXPIRES_IN') || '7d',
        },
      }),
      inject: [ConfigService],
    }),
  ],
  controllers: [DmController],
  providers: [DmService, DmGateway],
  exports: [DmService],
})
export class DmModule {}
