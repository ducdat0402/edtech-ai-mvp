import { Controller, Get, Post, Delete, Param, Query, Request, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { DmService } from './dm.service';
import { DmGateway } from './dm.gateway';

@Controller('dm')
@UseGuards(JwtAuthGuard)
export class DmController {
  constructor(
    private readonly dmService: DmService,
    private readonly dmGateway: DmGateway,
  ) {}

  @Get('conversations')
  async getConversations(@Request() req: any) {
    return this.dmService.getConversations(req.user.id);
  }

  @Get('conversation/:peerId')
  async getConversation(
    @Request() req: any,
    @Param('peerId') peerId: string,
    @Query('limit') limit?: string,
    @Query('before') before?: string,
  ) {
    return this.dmService.getConversation(req.user.id, peerId, {
      limit: limit ? parseInt(limit, 10) : 50,
      before,
    });
  }

  @Post('conversation/:peerId/read')
  async markAsRead(@Request() req: any, @Param('peerId') peerId: string) {
    await this.dmService.markAsRead(req.user.id, peerId);
    return { success: true };
  }

  @Delete('message/:id')
  async deleteMessage(@Request() req: any, @Param('id') messageId: string) {
    const { receiverId } = await this.dmService.deleteMessage(messageId, req.user.id);
    this.dmGateway.emitMessageDeleted(messageId, req.user.id, receiverId);
    return { success: true };
  }
}
