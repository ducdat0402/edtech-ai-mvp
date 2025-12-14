import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI } from '@google/generative-ai';

@Injectable()
export class AiService {
  private genAI: GoogleGenerativeAI;
  private model: any;

  constructor(private configService: ConfigService) {
    const apiKey = this.configService.get<string>('GEMINI_API_KEY');
    if (!apiKey) {
      console.warn('⚠️  GEMINI_API_KEY not found in environment variables');
    } else {
      this.genAI = new GoogleGenerativeAI(apiKey);
      this.model = this.genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
    }
  }

  async chat(messages: Array<{ role: string; content: string }>): Promise<string> {
    if (!this.model) {
      throw new Error('Gemini API not configured. Please set GEMINI_API_KEY in .env');
    }

    try {
      // Convert messages to Gemini format
      const chat = this.model.startChat({
        history: messages.slice(0, -1).map((msg) => ({
          role: msg.role === 'user' ? 'user' : 'model',
          parts: [{ text: msg.content }],
        })),
      });

      const lastMessage = messages[messages.length - 1];
      const result = await chat.sendMessage(lastMessage.content);
      const response = await result.response;
      return response.text();
    } catch (error) {
      console.error('Gemini API error:', error);
      throw new Error('Failed to get AI response');
    }
  }

  async extractOnboardingData(
    conversationHistory: Array<{ role: string; content: string }>,
  ): Promise<{
    fullName?: string;
    phone?: string;
    interests?: string[];
    learningGoals?: string;
    experienceLevel?: string;
  }> {
    if (!this.model) {
      throw new Error('Gemini API not configured');
    }

    const prompt = `
Bạn là một AI assistant giúp extract thông tin từ cuộc trò chuyện onboarding với người dùng.

Từ cuộc trò chuyện dưới đây, hãy extract các thông tin sau (nếu có):
- fullName: Tên đầy đủ của người dùng
- phone: Số điện thoại
- interests: Mảng các chủ đề quan tâm (ví dụ: ["Excel", "Word", "Bóng Rổ"])
- learningGoals: Mục tiêu học tập
- experienceLevel: Trình độ (beginner, intermediate, advanced)

Trả về JSON format:
{
  "fullName": "string hoặc null",
  "phone": "string hoặc null",
  "interests": ["string"] hoặc null,
  "learningGoals": "string hoặc null",
  "experienceLevel": "string hoặc null"
}

Cuộc trò chuyện:
${JSON.stringify(conversationHistory, null, 2)}
`;

    try {
      const result = await this.model.generateContent(prompt);
      const response = await result.response;
      const text = response.text();

      // Extract JSON from response (might have markdown code blocks)
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }

      return {};
    } catch (error) {
      console.error('Error extracting onboarding data:', error);
      return {};
    }
  }

  async generateOnboardingResponse(
    userMessage: string,
    conversationHistory: Array<{ role: string; content: string }>,
    extractedData: any,
  ): Promise<string> {
    if (!this.model) {
      throw new Error('Gemini API not configured');
    }

    const systemPrompt = `
Bạn là một AI tutor thân thiện giúp người dùng onboarding vào nền tảng học tập EdTech.

Nhiệm vụ của bạn:
1. Chào hỏi thân thiện và tạo không khí vui vẻ
2. Hỏi về tên, sở thích học tập, mục tiêu
3. Gợi ý các chủ đề phù hợp (Excel, Word, Bóng Rổ, Lifestyle, etc.)
4. Giữ cuộc trò chuyện ngắn gọn, tự nhiên như chat với bạn bè

Thông tin đã biết về người dùng:
${JSON.stringify(extractedData, null, 2)}

Hãy trả lời một cách tự nhiên, ngắn gọn (1-2 câu), không quá formal.
`;

    const messages = [
      { role: 'system', content: systemPrompt },
      ...conversationHistory,
      { role: 'user', content: userMessage },
    ];

    return this.chat(messages);
  }
}

