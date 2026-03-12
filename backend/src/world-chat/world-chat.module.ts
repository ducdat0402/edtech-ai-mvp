import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WorldChatService } from './world-chat.service';
import { WorldChatController } from './world-chat.controller';
import { ChatMessage } from './entities/chat-message.entity';
import { UserCurrencyModule } from '../user-currency/user-currency.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([ChatMessage]),
    UserCurrencyModule,
  ],
  controllers: [WorldChatController],
  providers: [WorldChatService],
  exports: [WorldChatService],
})
export class WorldChatModule {}
