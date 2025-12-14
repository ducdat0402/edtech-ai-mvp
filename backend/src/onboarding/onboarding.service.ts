import { Injectable } from '@nestjs/common';
import { AiService } from '../ai/ai.service';
import { UsersService } from '../users/users.service';
import { ChatMessageDto } from './dto/chat-message.dto';

interface ConversationSession {
  userId: string;
  messages: Array<{ role: string; content: string }>;
  extractedData: {
    fullName?: string;
    phone?: string;
    interests?: string[];
    learningGoals?: string;
    experienceLevel?: string;
  };
  completed: boolean;
}

@Injectable()
export class OnboardingService {
  private sessions: Map<string, ConversationSession> = new Map();

  constructor(
    private aiService: AiService,
    private usersService: UsersService,
  ) {}

  private getOrCreateSession(userId: string, sessionId?: string): ConversationSession {
    const key = sessionId || userId;
    
    if (!this.sessions.has(key)) {
      this.sessions.set(key, {
        userId,
        messages: [
          {
            role: 'assistant',
            content: 'Xin chào! 👋 Mình là AI tutor của bạn. Mình sẽ giúp bạn bắt đầu hành trình học tập thú vị!\n\nBạn có thể cho mình biết tên của bạn không? 😊',
          },
        ],
        extractedData: {},
        completed: false,
      });
    }

    return this.sessions.get(key)!;
  }

  async chat(userId: string, chatDto: ChatMessageDto) {
    const session = this.getOrCreateSession(userId, chatDto.sessionId);

    // Add user message to history
    session.messages.push({
      role: 'user',
      content: chatDto.message,
    });

    // Extract data from conversation periodically
    if (session.messages.length % 3 === 0) {
      // Every 3 messages, try to extract data
      const extracted = await this.aiService.extractOnboardingData(
        session.messages,
      );
      session.extractedData = { ...session.extractedData, ...extracted };
    }

    // Generate AI response
    const aiResponse = await this.aiService.generateOnboardingResponse(
      chatDto.message,
      session.messages.slice(0, -1), // All messages except the last one
      session.extractedData,
    );

    // Add AI response to history
    session.messages.push({
      role: 'assistant',
      content: aiResponse,
    });

    // Check if onboarding is complete (has name and at least one interest)
    if (
      session.extractedData.fullName &&
      session.extractedData.interests &&
      session.extractedData.interests.length > 0 &&
      !session.completed
    ) {
      session.completed = true;

      // Save onboarding data to user
      await this.usersService.updateOnboardingData(
        userId,
        session.extractedData,
      );

      // Update user profile if needed
      if (session.extractedData.fullName || session.extractedData.phone) {
        await this.usersService.updateProfile(userId, {
          fullName: session.extractedData.fullName,
          phone: session.extractedData.phone,
        });
      }
    }

    return {
      response: aiResponse,
      sessionId: chatDto.sessionId || userId,
      extractedData: session.extractedData,
      completed: session.completed,
      conversationHistory: session.messages,
    };
  }

  async getOnboardingStatus(userId: string, sessionId?: string) {
    const key = sessionId || userId;
    const session = this.sessions.get(key);

    if (!session) {
      return {
        completed: false,
        extractedData: {},
        conversationHistory: [],
      };
    }

    return {
      completed: session.completed,
      extractedData: session.extractedData,
      conversationHistory: session.messages,
    };
  }

  async resetOnboarding(userId: string, sessionId?: string) {
    const key = sessionId || userId;
    this.sessions.delete(key);
    return { message: 'Onboarding session reset' };
  }
}

