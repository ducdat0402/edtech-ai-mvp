import { Injectable } from '@nestjs/common';
import { AiService } from '../ai/ai.service';
import { UsersService } from '../users/users.service';
import { ChatMessageDto } from './dto/chat-message.dto';

interface ConversationSession {
  userId: string;
  messages: Array<{ role: string; content: string }>;
  extractedData: {
    // New fields
    nickname?: string;
    age?: number;
    currentLevel?: string;
    subject?: string; // Ngành học/chủ đề chính
    targetGoal?: string;
    dailyTime?: number;
    // Legacy fields
    fullName?: string;
    phone?: string;
    interests?: string[];
    learningGoals?: string;
    experienceLevel?: string;
  };
  completed: boolean;
  turnCount: number;
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
        turnCount: 0,
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
      
      // ✅ Save onboarding data ngay khi có targetGoal (không cần đợi completed)
      if (extracted.targetGoal) {
        console.log(`💾 Saving targetGoal to user profile: "${extracted.targetGoal}"`);
        await this.usersService.updateOnboardingData(
          userId,
          session.extractedData,
        );
      }
    }

    // Calculate slots filled
    const slotsFilled = {
      nickname: !!session.extractedData.nickname,
      age: !!session.extractedData.age,
      currentLevel: !!session.extractedData.currentLevel,
      targetGoal: !!session.extractedData.targetGoal,
      dailyTime: !!session.extractedData.dailyTime,
    };

    // Increment turn count
    session.turnCount++;

    // Generate AI response
    const aiResponse = await this.aiService.generateOnboardingResponse(
      chatDto.message,
      session.messages.slice(0, -1), // All messages except the last one
      session.extractedData,
      session.turnCount,
      slotsFilled,
    );

    // Add AI response to history
    session.messages.push({
      role: 'assistant',
      content: aiResponse.response,
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
      response: aiResponse.response,
      sessionId: chatDto.sessionId || userId,
      extractedData: session.extractedData,
      completed: session.completed || aiResponse.shouldTerminate,
      conversationHistory: session.messages,
      shouldTerminate: aiResponse.shouldTerminate,
      canProceed: aiResponse.canProceed,
      missingSlots: aiResponse.missingSlots,
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

  /**
   * Stream chat response - returns chunks as they are generated
   */
  async *streamChat(
    userId: string,
    chatDto: ChatMessageDto,
  ): AsyncGenerator<string, void, unknown> {
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
      
      // ✅ Save onboarding data ngay khi có targetGoal (không cần đợi completed)
      if (extracted.targetGoal) {
        console.log(`💾 Saving targetGoal to user profile: "${extracted.targetGoal}"`);
        await this.usersService.updateOnboardingData(
          userId,
          session.extractedData,
        );
      }
    }

    // Calculate slots filled
    const slotsFilled = {
      nickname: !!session.extractedData.nickname,
      age: !!session.extractedData.age,
      currentLevel: !!session.extractedData.currentLevel,
      targetGoal: !!session.extractedData.targetGoal,
      dailyTime: !!session.extractedData.dailyTime,
    };

    // Increment turn count
    session.turnCount++;

    // Stream AI response
    let fullResponse = '';
    const stream = this.aiService.streamOnboardingResponse(
      chatDto.message,
      session.messages.slice(0, -1), // All messages except the last one
      session.extractedData,
      session.turnCount,
      slotsFilled,
    );

    let metadata: any = null;
    for await (const chunk of stream) {
      if (typeof chunk === 'string') {
        fullResponse += chunk;
        yield chunk;
      } else if (chunk && typeof chunk === 'object' && (chunk as any).__metadata) {
        // This is the metadata object
        metadata = chunk;
      }
    }

    // After streaming completes, process metadata
    if (metadata) {
      // Add AI response to history
      session.messages.push({
        role: 'assistant',
        content: fullResponse,
      });

      // Check if onboarding is complete
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
    }
  }

  /**
   * Get chat result after streaming completes
   */
  async getChatResult(userId: string, sessionId?: string) {
    const key = sessionId || userId;
    const session = this.sessions.get(key);

    if (!session) {
      return {
        response: '',
        sessionId: sessionId || userId,
        extractedData: {},
        completed: false,
        shouldTerminate: false,
        canProceed: false,
        missingSlots: [],
      };
    }

    const slotsFilled = {
      nickname: !!session.extractedData.nickname,
      age: !!session.extractedData.age,
      currentLevel: !!session.extractedData.currentLevel,
      targetGoal: !!session.extractedData.targetGoal,
      dailyTime: !!session.extractedData.dailyTime,
    };

    const requiredSlots = ['targetGoal', 'nickname', 'age', 'currentLevel', 'dailyTime'];
    const missingSlots = requiredSlots.filter(slot => !slotsFilled[slot]);

    const lastMessage = session.messages[session.messages.length - 1];
    const response = lastMessage?.role === 'assistant' ? lastMessage.content : '';

    return {
      response,
      sessionId: sessionId || userId,
      extractedData: session.extractedData,
      completed: session.completed,
      shouldTerminate: session.turnCount >= 7 || missingSlots.length === 0,
      canProceed: missingSlots.length <= 2,
      missingSlots,
      conversationHistory: session.messages,
    };
  }
}

