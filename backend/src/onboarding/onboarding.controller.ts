import { Controller, Post, Get, Body, UseGuards, Request } from '@nestjs/common';
import { OnboardingService } from './onboarding.service';
import { ChatMessageDto } from './dto/chat-message.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('onboarding')
@UseGuards(JwtAuthGuard)
export class OnboardingController {
  constructor(private readonly onboardingService: OnboardingService) {}

  @Post('chat')
  async chat(@Request() req, @Body() chatDto: ChatMessageDto) {
    return this.onboardingService.chat(req.user.id, chatDto);
  }

  @Get('status')
  async getStatus(@Request() req, @Body() body?: { sessionId?: string }) {
    return this.onboardingService.getOnboardingStatus(
      req.user.id,
      body?.sessionId,
    );
  }

  @Post('reset')
  async reset(@Request() req, @Body() body?: { sessionId?: string }) {
    return this.onboardingService.resetOnboarding(
      req.user.id,
      body?.sessionId,
    );
  }
}

