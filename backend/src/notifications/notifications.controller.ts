import { Controller, Get, Post, UseGuards, Request } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
export class NotificationsController {
  constructor(private notificationsService: NotificationsService) {}

  @UseGuards(JwtAuthGuard)
  @Get('daily-motivation')
  async getDailyMotivation(@Request() req) {
    const motivation = await this.notificationsService.getDailyMotivation(
      req.user.id,
    );
    return motivation ?? { message: 'Notifications disabled' };
  }

  @UseGuards(JwtAuthGuard)
  @Get('quote-stats')
  async getQuoteStats() {
    return this.notificationsService.getQuoteStats();
  }

  @UseGuards(JwtAuthGuard)
  @Post('trigger-evaluation')
  async triggerEvaluation(@Request() req) {
    if (req.user.role !== 'admin') {
      return { error: 'Admin only' };
    }
    await this.notificationsService.evaluateAllUsers();
    return { success: true };
  }

  @UseGuards(JwtAuthGuard)
  @Post('generate-quotes')
  async generateQuotes(@Request() req) {
    if (req.user.role !== 'admin') {
      return { error: 'Admin only' };
    }
    const quotes =
      await this.notificationsService['quoteService'].generateQuotesWithAI(10);
    return { generated: quotes.length, quotes };
  }
}
