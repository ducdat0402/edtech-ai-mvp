import { Controller, Get, Post, Delete, Body, Query, Param, UseGuards, Request } from '@nestjs/common';
import { WorldChatService } from './world-chat.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('world-chat')
@UseGuards(JwtAuthGuard)
export class WorldChatController {
  constructor(private readonly chatService: WorldChatService) {}

  @Get('messages')
  async getMessages(
    @Query('limit') limit?: string,
    @Query('before') before?: string,
    @Query('after') after?: string,
  ) {
    const messages = await this.chatService.getMessages({
      limit: limit ? parseInt(limit, 10) : 30,
      before,
      after,
    });
    const onlineCount = await this.chatService.getOnlineCount();

    return { messages, onlineCount };
  }

  @Post('send')
  async sendMessage(
    @Request() req,
    @Body() body: { message: string; replyToId?: string },
  ) {
    const username = req.user.fullName || req.user.email?.split('@')[0] || 'Anonymous';
    const msg = await this.chatService.sendMessage(
      req.user.id,
      username,
      body.message,
      body.replyToId,
    );
    return msg;
  }

  @Delete('messages/:id')
  async deleteMessage(@Request() req, @Param('id') messageId: string) {
    await this.chatService.deleteMessage(messageId, req.user.id);
    return { success: true };
  }
}
