import { Controller, Get, Post, Param, UseGuards, Request } from '@nestjs/common';
import { QuestsService } from './quests.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('quests')
@UseGuards(JwtAuthGuard)
export class QuestsController {
  constructor(private readonly questsService: QuestsService) {}

  @Get('daily')
  async getDailyQuests(@Request() req) {
    return this.questsService.getDailyQuests(req.user.id);
  }

  @Post('claim/:userQuestId')
  async claimReward(@Request() req, @Param('userQuestId') userQuestId: string) {
    return this.questsService.claimQuestReward(req.user.id, userQuestId);
  }

  @Get('history')
  async getHistory(@Request() req) {
    return this.questsService.getQuestHistory(req.user.id);
  }
}

