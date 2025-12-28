import { Controller, Post, Get, Body, UseGuards, Request, Res } from '@nestjs/common';
import { OnboardingService } from './onboarding.service';
import { ChatMessageDto } from './dto/chat-message.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { Response } from 'express';

@Controller('onboarding')
@UseGuards(JwtAuthGuard)
export class OnboardingController {
  constructor(private readonly onboardingService: OnboardingService) {}

  @Post('chat')
  async chat(@Request() req, @Body() chatDto: ChatMessageDto) {
    return this.onboardingService.chat(req.user.id, chatDto);
  }

  @Post('chat/stream')
  async streamChat(@Request() req, @Body() chatDto: ChatMessageDto, @Res() res: Response) {
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.setHeader('X-Accel-Buffering', 'no'); // Disable buffering for nginx

    try {
      const stream = await this.onboardingService.streamChat(req.user.id, chatDto);
      
      for await (const chunk of stream) {
        // Send chunk as SSE format
        res.write(`data: ${JSON.stringify({ type: 'chunk', content: chunk })}\n\n`);
      }

      // Send completion metadata
      const result = await this.onboardingService.getChatResult(req.user.id, chatDto.sessionId);
      res.write(`data: ${JSON.stringify({ type: 'done', ...result })}\n\n`);
      res.end();
    } catch (error) {
      console.error('Streaming error:', error);
      res.write(`data: ${JSON.stringify({ type: 'error', message: error.message })}\n\n`);
      res.end();
    }
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

