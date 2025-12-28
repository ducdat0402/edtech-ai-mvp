import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';

@Injectable()
export class AiService {
  private openai: OpenAI;
  private model: string = 'gpt-4o-mini'; // Hoặc 'gpt-3.5-turbo' (rẻ hơn)

  constructor(private configService: ConfigService) {
    const apiKey = this.configService.get<string>('OPENAI_API_KEY');
    if (!apiKey) {
      console.warn('⚠️  OPENAI_API_KEY not found in environment variables');
    } else {
      this.openai = new OpenAI({ apiKey });
      console.log(`✅ Initialized OpenAI model: ${this.model}`);
    }
  }

  async chat(messages: Array<{ role: string; content: string }>): Promise<string> {
    if (!this.openai) {
      throw new Error('OpenAI API not configured. Please set OPENAI_API_KEY in .env');
    }

    try {
      // Convert messages to OpenAI format with proper typing
      const openaiMessages: Array<{ role: 'user' | 'assistant'; content: string }> = messages.map((msg) => ({
        role: (msg.role === 'user' ? 'user' : 'assistant') as 'user' | 'assistant',
        content: msg.content,
      }));

      const completion = await this.openai.chat.completions.create({
        model: this.model,
        messages: openaiMessages,
      });

      return completion.choices[0]?.message?.content || '';
    } catch (error) {
      console.error('OpenAI API error:', error);
      throw new Error('Failed to get AI response');
    }
  }

  /**
   * Stream chat response from OpenAI
   * Returns an async generator that yields chunks of text
   */
  async *streamChat(
    messages: Array<{ role: string; content: string }>,
  ): AsyncGenerator<string, void, unknown> {
    if (!this.openai) {
      throw new Error('OpenAI API not configured. Please set OPENAI_API_KEY in .env');
    }

    try {
      // Convert messages to OpenAI format
      const openaiMessages: Array<{ role: 'user' | 'assistant'; content: string }> = messages.map((msg) => ({
        role: (msg.role === 'user' ? 'user' : 'assistant') as 'user' | 'assistant',
        content: msg.content,
      }));

      const stream = await this.openai.chat.completions.create({
        model: this.model,
        messages: openaiMessages,
        stream: true,
      });

      for await (const chunk of stream) {
        const content = chunk.choices[0]?.delta?.content;
        if (content) {
          yield content;
        }
      }
    } catch (error) {
      console.error('OpenAI streaming error:', error);
      throw new Error('Failed to stream AI response');
    }
  }

  /**
   * Stream onboarding response from OpenAI
   * Returns an async generator that yields chunks of text, then metadata
   */
  async *streamOnboardingResponse(
    userMessage: string,
    conversationHistory: Array<{ role: string; content: string }>,
    extractedData: any,
    turnCount: number,
    slotsFilled: {
      nickname: boolean;
      age: boolean;
      currentLevel: boolean;
      targetGoal: boolean;
      dailyTime: boolean;
    },
  ): AsyncGenerator<string | { __metadata: true; shouldTerminate: boolean; missingSlots: string[]; canProceed: boolean }, void, unknown> {
    if (!this.openai) {
      throw new Error('OpenAI API not configured');
    }

    const MAX_TURNS = 7;
    const requiredSlots = ['targetGoal', 'nickname', 'age', 'currentLevel', 'dailyTime'];
    const missingSlots = requiredSlots.filter(slot => !slotsFilled[slot]);

    // Build system prompt (same logic as generateOnboardingResponse)
    let systemPrompt = '';
    
    if (turnCount >= MAX_TURNS) {
      systemPrompt = `
Bạn đã hỏi ${turnCount} câu. Đây là câu hỏi cuối cùng.

Hãy tóm tắt lại thông tin đã thu thập được và kết thúc cuộc trò chuyện một cách tự nhiên.
Gợi ý người dùng bấm nút "Xong / Test thôi" để tiếp tục.

Thông tin đã có:
${JSON.stringify(extractedData, null, 2)}

Thông tin còn thiếu:
${missingSlots.join(', ')}

Hãy tóm tắt và kết thúc một cách thân thiện.
`;
    } else if (missingSlots.length === 0) {
      systemPrompt = `
Bạn đã thu thập đủ thông tin! Hãy tóm tắt lại và gợi ý người dùng bấm nút "Xong / Test thôi" để tiếp tục.

Thông tin đã thu thập:
- Biệt danh: ${extractedData.nickname}
- Tuổi: ${extractedData.age}
- Trình độ: ${extractedData.currentLevel}
- Mục tiêu: ${extractedData.targetGoal}
- Thời gian học: ${extractedData.dailyTime} phút/ngày

Hãy kết thúc một cách tự nhiên và khuyến khích người dùng tiếp tục.
`;
    } else {
      const priorityOrder = ['targetGoal', 'nickname', 'age', 'currentLevel', 'dailyTime'];
      const nextSlotToAsk = priorityOrder.find(slot => missingSlots.includes(slot)) || missingSlots[0];
      
      systemPrompt = `
Bạn là AI tutor thân thiện. Nhiệm vụ: Thu thập 5 thông tin QUAN TRỌNG theo thứ tự ưu tiên:
1. targetGoal (Mục tiêu học tập) - QUAN TRỌNG NHẤT, hỏi đầu tiên
2. nickname (Biệt danh)
3. age (Tuổi)
4. currentLevel (beginner/intermediate/advanced)
5. dailyTime (Thời gian học/ngày - phút)

Thông tin ĐÃ CÓ:
${JSON.stringify(extractedData, null, 2)}

Thông tin CÒN THIẾU:
${missingSlots.join(', ')}

Thông tin CẦN HỎI TIẾP THEO (ưu tiên): ${nextSlotToAsk || 'không có'}

Bạn đã hỏi ${turnCount}/${MAX_TURNS} câu. Hãy hỏi về thông tin còn thiếu theo thứ tự ưu tiên, một cách tự nhiên, ngắn gọn (1-2 câu).
Đặc biệt: Nếu chưa có targetGoal, hãy hỏi về mục tiêu học tập trước tiên.

Nếu đã có đủ 3/5 thông tin, có thể gợi ý người dùng bấm "Xong / Test thôi" nếu họ muốn.
`;
    }

    try {
      // Build conversation history for OpenAI
      const openaiMessages: Array<{ role: 'user' | 'assistant' | 'system'; content: string }> = [
        { role: 'system', content: systemPrompt },
      ];

      // Add conversation history
      for (const msg of conversationHistory) {
        if (msg.role === 'user' || msg.role === 'assistant') {
          openaiMessages.push({
            role: msg.role === 'user' ? 'user' : 'assistant',
            content: msg.content,
          });
        }
      }

      // Add current user message
      openaiMessages.push({ role: 'user', content: userMessage });

      const stream = await this.openai.chat.completions.create({
        model: this.model,
        messages: openaiMessages,
        stream: true,
      });

      let fullResponse = '';
      for await (const chunk of stream) {
        const content = chunk.choices[0]?.delta?.content;
        if (content) {
          fullResponse += content;
          yield content;
        }
      }

      // Yield metadata after streaming completes (as a special object)
      yield {
        __metadata: true,
        shouldTerminate: turnCount >= MAX_TURNS || missingSlots.length === 0,
        missingSlots,
        canProceed: missingSlots.length <= 2,
      };
    } catch (error) {
      console.error('Error streaming onboarding response:', error);
      throw new Error('Failed to stream AI response');
    }
  }

  async extractOnboardingData(
    conversationHistory: Array<{ role: string; content: string }>,
  ): Promise<{
    // ✅ 6 fields quan trọng mới
    nickname?: string;
    age?: number;
    currentLevel?: string;
    subject?: string; // Ngành học/chủ đề chính
    targetGoal?: string;
    dailyTime?: number;
    // Legacy fields (backward compatible)
    fullName?: string;
    phone?: string;
    interests?: string[];
    learningGoals?: string;
    experienceLevel?: string;
  }> {
    if (!this.openai) {
      throw new Error('OpenAI API not configured');
    }

    const prompt = `
Bạn là một AI assistant giúp extract thông tin từ cuộc trò chuyện onboarding với người dùng.

Cần extract 6 thông tin QUAN TRỌNG:
1. nickname: Biệt danh/tên gọi của người dùng (ví dụ: "Đạt", "Anh", "Em")
2. age: Tuổi (số nguyên, ví dụ: 25)
3. currentLevel: Trình độ hiện tại - CHỈ NHẬN: "beginner", "intermediate", "advanced"
4. subject: Ngành học/chủ đề chính (ví dụ: "piano", "excel", "python", "guitar", "vẽ") - CHỈ tên ngành học, không phải mục tiêu
5. targetGoal: Mục tiêu học tập cụ thể (ví dụ: "chơi bài tori no uta", "làm việc với Excel", "xây dựng website")
6. dailyTime: Thời gian học hằng ngày (phút, ví dụ: 30)

Ngoài ra, cũng extract các thông tin bổ sung (nếu có):
- fullName: Tên đầy đủ
- phone: Số điện thoại
- interests: Mảng các chủ đề quan tâm
- learningGoals: Mục tiêu học tập (legacy)
- experienceLevel: Trình độ (legacy)

Trả về JSON format:
{
  "nickname": "string hoặc null",
  "age": number hoặc null,
  "currentLevel": "beginner" | "intermediate" | "advanced" | null,
  "subject": "string hoặc null",
  "targetGoal": "string hoặc null",
  "dailyTime": number hoặc null,
  "fullName": "string hoặc null",
  "phone": "string hoặc null",
  "interests": ["string"] hoặc null,
  "learningGoals": "string hoặc null",
  "experienceLevel": "string hoặc null"
}

LƯU Ý QUAN TRỌNG:
- "subject": Chỉ tên ngành học/chủ đề (ví dụ: "piano", "excel", "python")
- "targetGoal": Mục tiêu cụ thể (ví dụ: "chơi bài tori no uta", "làm báo cáo Excel")
- Nếu người dùng nói "học piano để chơi bài tori no uta" → subject: "piano", targetGoal: "chơi bài tori no uta"

Cuộc trò chuyện:
${JSON.stringify(conversationHistory, null, 2)}
`;

    try {
      const completion = await this.openai.chat.completions.create({
        model: this.model,
        messages: [{ role: 'user', content: prompt }],
        response_format: { type: 'json_object' }, // Force JSON response
      });

      const text = completion.choices[0]?.message?.content || '{}';
      const parsed = JSON.parse(text);

      // ✅ Normalize currentLevel
      if (parsed.currentLevel) {
        const level = parsed.currentLevel.toLowerCase();
        if (level.includes('beginner') || level.includes('mới bắt đầu')) {
          parsed.currentLevel = 'beginner';
        } else if (level.includes('intermediate') || level.includes('trung bình') || level.includes('biết chút')) {
          parsed.currentLevel = 'intermediate';
        } else if (level.includes('advanced') || level.includes('nâng cao')) {
          parsed.currentLevel = 'advanced';
        }
      }

      return parsed;
    } catch (error) {
      console.error('Error extracting onboarding data:', error);
      return {};
    }
  }

  async generateOnboardingResponse(
    userMessage: string,
    conversationHistory: Array<{ role: string; content: string }>,
    extractedData: any,
    turnCount: number,
    slotsFilled: {
      nickname: boolean;
      age: boolean;
      currentLevel: boolean;
      targetGoal: boolean;
      dailyTime: boolean;
    },
  ): Promise<{
    response: string;
    shouldTerminate: boolean;
    missingSlots: string[];
    canProceed: boolean;
  }> {
    if (!this.openai) {
      throw new Error('OpenAI API not configured');
    }

    const MAX_TURNS = 7;
    // Ưu tiên: targetGoal trước, sau đó mới nickname, age, currentLevel, dailyTime
    const requiredSlots = ['targetGoal', 'nickname', 'age', 'currentLevel', 'dailyTime'];
    const missingSlots = requiredSlots.filter(slot => !slotsFilled[slot]);

    // ✅ Termination Condition 1: Turn Count Limit
    if (turnCount >= MAX_TURNS) {
      const systemPrompt = `
Bạn đã hỏi ${turnCount} câu. Đây là câu hỏi cuối cùng.

Hãy tóm tắt lại thông tin đã thu thập được và kết thúc cuộc trò chuyện một cách tự nhiên.
Gợi ý người dùng bấm nút "Xong / Test thôi" để tiếp tục.

Thông tin đã có:
${JSON.stringify(extractedData, null, 2)}

Thông tin còn thiếu:
${missingSlots.join(', ')}

Hãy tóm tắt và kết thúc một cách thân thiện.
`;

      try {
        const completion = await this.openai.chat.completions.create({
          model: this.model,
          messages: [{ role: 'user', content: systemPrompt }],
        });

        return {
          response: completion.choices[0]?.message?.content || 'Cảm ơn bạn đã chia sẻ! Bạn có thể bấm "Xong / Test thôi" để tiếp tục nhé! 😊',
          shouldTerminate: true,
          missingSlots,
          canProceed: missingSlots.length <= 2,
        };
      } catch (error) {
        console.error('Error generating termination response:', error);
        return {
          response: 'Cảm ơn bạn đã chia sẻ! Bạn có thể bấm "Xong / Test thôi" để tiếp tục nhé! 😊',
          shouldTerminate: true,
          missingSlots,
          canProceed: missingSlots.length <= 2,
        };
      }
    }

    // ✅ Termination Condition 2: Slot Filling - Đủ thông tin
    if (missingSlots.length === 0) {
      const systemPrompt = `
Bạn đã thu thập đủ thông tin! Hãy tóm tắt lại và gợi ý người dùng bấm nút "Xong / Test thôi" để tiếp tục.

Thông tin đã thu thập:
- Biệt danh: ${extractedData.nickname}
- Tuổi: ${extractedData.age}
- Trình độ: ${extractedData.currentLevel}
- Mục tiêu: ${extractedData.targetGoal}
- Thời gian học: ${extractedData.dailyTime} phút/ngày

Hãy kết thúc một cách tự nhiên và khuyến khích người dùng tiếp tục.
`;

      try {
        const completion = await this.openai.chat.completions.create({
          model: this.model,
          messages: [{ role: 'user', content: systemPrompt }],
        });

        return {
          response: completion.choices[0]?.message?.content || 'Tuyệt vời! Bạn đã cung cấp đủ thông tin. Hãy bấm "Xong / Test thôi" để bắt đầu bài kiểm tra nhé! 🎯',
          shouldTerminate: true,
          missingSlots: [],
          canProceed: true,
        };
      } catch (error) {
        console.error('Error generating completion response:', error);
        return {
          response: 'Tuyệt vời! Bạn đã cung cấp đủ thông tin. Hãy bấm "Xong / Test thôi" để bắt đầu bài kiểm tra nhé! 🎯',
          shouldTerminate: true,
          missingSlots: [],
          canProceed: true,
        };
      }
    }

    // ✅ Normal conversation - Focus on missing slots
    // Ưu tiên hỏi targetGoal trước (mục tiêu học tập)
    const priorityOrder = ['targetGoal', 'nickname', 'age', 'currentLevel', 'dailyTime'];
    const nextSlotToAsk = priorityOrder.find(slot => missingSlots.includes(slot)) || missingSlots[0];
    
    const systemPrompt = `
Bạn là AI tutor thân thiện. Nhiệm vụ: Thu thập 5 thông tin QUAN TRỌNG theo thứ tự ưu tiên:
1. targetGoal (Mục tiêu học tập) - QUAN TRỌNG NHẤT, hỏi đầu tiên
2. nickname (Biệt danh)
3. age (Tuổi)
4. currentLevel (beginner/intermediate/advanced)
5. dailyTime (Thời gian học/ngày - phút)

Thông tin ĐÃ CÓ:
${JSON.stringify(extractedData, null, 2)}

Thông tin CÒN THIẾU:
${missingSlots.join(', ')}

Thông tin CẦN HỎI TIẾP THEO (ưu tiên): ${nextSlotToAsk || 'không có'}

Bạn đã hỏi ${turnCount}/${MAX_TURNS} câu. Hãy hỏi về thông tin còn thiếu theo thứ tự ưu tiên, một cách tự nhiên, ngắn gọn (1-2 câu).
Đặc biệt: Nếu chưa có targetGoal, hãy hỏi về mục tiêu học tập trước tiên.

Nếu đã có đủ 3/5 thông tin, có thể gợi ý người dùng bấm "Xong / Test thôi" nếu họ muốn.
`;

    try {
      // Build conversation history for OpenAI
      const openaiMessages: Array<{ role: 'user' | 'assistant' | 'system'; content: string }> = [
        { role: 'system', content: systemPrompt },
      ];

      // Add conversation history
      for (const msg of conversationHistory) {
        if (msg.role === 'user' || msg.role === 'assistant') {
          openaiMessages.push({
            role: msg.role === 'user' ? 'user' : 'assistant',
            content: msg.content,
          });
        }
      }

      // Add current user message
      openaiMessages.push({ role: 'user', content: userMessage });

      const completion = await this.openai.chat.completions.create({
        model: this.model,
        messages: openaiMessages,
      });

      return {
        response: completion.choices[0]?.message?.content || 'Xin lỗi, tôi gặp một chút vấn đề kỹ thuật. Bạn có thể thử lại được không? 😊',
        shouldTerminate: false,
        missingSlots,
        canProceed: missingSlots.length <= 2,
      };
    } catch (error) {
      console.error('❌ Error generating onboarding response:', error);
      return {
        response: 'Xin lỗi, tôi gặp một chút vấn đề kỹ thuật. Bạn có thể thử lại được không? 😊',
        shouldTerminate: false,
        missingSlots,
        canProceed: false,
      };
    }
  }

  async generatePlacementQuestion(
    subject: string,
    difficulty: string = 'beginner',
  ): Promise<{
    question: string;
    options: string[];
    correctAnswer: number;
    explanation?: string;
  }> {
    if (!this.openai) {
      throw new Error('OpenAI API not configured');
    }

    const prompt = `Tạo một câu hỏi trắc nghiệm về chủ đề "${subject}" ở mức độ ${difficulty} (beginner/intermediate/advanced).

Yêu cầu:
- Câu hỏi rõ ràng, liên quan trực tiếp đến ${subject}
- 4 lựa chọn (A, B, C, D) - chỉ có 1 đáp án đúng
- Độ khó phù hợp với mức ${difficulty}
- Giải thích ngắn gọn (1-2 câu) tại sao đáp án đúng

Trả về JSON format (chỉ JSON, không có text khác):
{
  "question": "Câu hỏi về ${subject}...",
  "options": ["A. Lựa chọn 1", "B. Lựa chọn 2", "C. Lựa chọn 3", "D. Lựa chọn 4"],
  "correctAnswer": 0,
  "explanation": "Giải thích ngắn gọn..."
}

Lưu ý: correctAnswer là index (0-3) của đáp án đúng trong mảng options.`;

    try {
      const completion = await this.openai.chat.completions.create({
        model: this.model,
        messages: [
          {
            role: 'user',
            content: prompt,
          },
        ],
        response_format: { type: 'json_object' },
        temperature: 0.7,
      });

      const content = completion.choices[0]?.message?.content;
      if (!content) {
        throw new Error('No response from AI');
      }

      const result = JSON.parse(content);

      // Validate result
      if (!result.question || !result.options || result.correctAnswer === undefined) {
        throw new Error('Invalid AI response format');
      }

      // Ensure correctAnswer is within bounds
      if (result.correctAnswer < 0 || result.correctAnswer >= result.options.length) {
        result.correctAnswer = 0; // Default to first option
      }

      return {
        question: result.question,
        options: result.options,
        correctAnswer: result.correctAnswer,
        explanation: result.explanation || '',
      };
    } catch (error) {
      console.error('Error generating placement question:', error);
      throw new Error(`Failed to generate question: ${error.message}`);
    }
  }

  /**
   * Generate a single concept from raw text
   */
  async generateConceptFromRawData(
    rawText: string,
    topic: string,
    difficulty: 'beginner' | 'intermediate' | 'advanced' = 'beginner',
  ): Promise<{
    title: string;
    content: string;
    rewards: { xp: number; coin: number };
  }> {
    if (!this.openai) {
      throw new Error('OpenAI API not configured');
    }

    const prompt = `Bạn là một giáo viên chuyên nghiệp. Nhiệm vụ: Chuyển đổi nội dung thô thành một khái niệm học tập có cấu trúc.

Nội dung thô:
"""
${rawText}
"""

Chủ đề: ${topic}
Độ khó: ${difficulty}

Yêu cầu:
1. Tạo title ngắn gọn, dễ hiểu (tối đa 50 ký tự)
2. Viết lại content theo cách dễ hiểu, có cấu trúc:
   - Giải thích khái niệm
   - Ví dụ minh họa (nếu có)
   - Lưu ý quan trọng
3. Content phải phù hợp với độ khó ${difficulty}
4. Sử dụng tiếng Việt, ngôn ngữ thân thiện

Trả về JSON format:
{
  "title": "Tên khái niệm",
  "content": "Nội dung chi tiết...",
  "rewards": {
    "xp": 10,
    "coin": 1
  }
}`;

    try {
      const completion = await this.openai.chat.completions.create({
        model: this.model,
        messages: [{ role: 'user', content: prompt }],
        response_format: { type: 'json_object' },
        temperature: 0.7,
      });

      const content = completion.choices[0]?.message?.content;
      if (!content) {
        throw new Error('No response from AI');
      }

      const result = JSON.parse(content);

      return {
        title: result.title || 'Khái niệm mới',
        content: result.content || rawText,
        rewards: result.rewards || { xp: 10, coin: 1 },
      };
    } catch (error) {
      console.error('Error generating concept:', error);
      throw new Error(`Failed to generate concept: ${error.message}`);
    }
  }

  /**
   * Generate multiple concepts from a document
   */
  async generateMultipleConceptsFromDocument(
    rawDocument: string,
    topic: string,
    count: number = 5,
  ): Promise<Array<{
    title: string;
    content: string;
    rewards: { xp: number; coin: number };
  }>> {
    if (!this.openai) {
      throw new Error('OpenAI API not configured');
    }

    const prompt = `Bạn là một giáo viên chuyên nghiệp. Nhiệm vụ: Phân tích tài liệu và tạo ra ${count} khái niệm học tập.

Tài liệu:
"""
${rawDocument}
"""

Chủ đề: ${topic}

Yêu cầu:
1. Phân tích tài liệu và chia thành ${count} khái niệm độc lập
2. Mỗi khái niệm có:
   - title: Ngắn gọn, dễ hiểu (tối đa 50 ký tự)
   - content: Giải thích chi tiết, dễ hiểu, có ví dụ minh họa
   - rewards: { xp: 10, coin: 1 }
3. Sắp xếp từ cơ bản đến nâng cao
4. Sử dụng tiếng Việt, ngôn ngữ thân thiện
5. Mỗi khái niệm phải độc lập, có thể học riêng lẻ

Trả về JSON format:
{
  "concepts": [
    {
      "title": "Khái niệm 1",
      "content": "Nội dung chi tiết...",
      "rewards": { "xp": 10, "coin": 1 }
    },
    ...
  ]
}`;

    try {
      const completion = await this.openai.chat.completions.create({
        model: this.model,
        messages: [{ role: 'user', content: prompt }],
        response_format: { type: 'json_object' },
        temperature: 0.7,
      });

      const content = completion.choices[0]?.message?.content;
      if (!content) {
        throw new Error('No response from AI');
      }

      const result = JSON.parse(content);
      const concepts = result.concepts || [];

      // Validate và normalize
      return concepts.map((concept: any) => ({
        title: concept.title || 'Khái niệm mới',
        content: concept.content || '',
        rewards: concept.rewards || { xp: 10, coin: 1 },
      }));
    } catch (error) {
      console.error('Error generating concepts:', error);
      throw new Error(`Failed to generate concepts: ${error.message}`);
    }
  }

  /**
   * Generate example content from raw text
   */
  async generateExampleFromRawData(
    rawText: string,
    topic: string,
  ): Promise<{
    title: string;
    content: string;
    rewards: { xp: number; coin: number };
  }> {
    if (!this.openai) {
      throw new Error('OpenAI API not configured');
    }

    const prompt = `Bạn là một giáo viên chuyên nghiệp. Nhiệm vụ: Tạo một ví dụ thực tế từ nội dung thô.

Nội dung thô:
"""
${rawText}
"""

Chủ đề: ${topic}

Yêu cầu:
1. Tạo title ngắn gọn cho ví dụ (tối đa 50 ký tự)
2. Viết một ví dụ thực tế, cụ thể, dễ hiểu
3. Ví dụ phải:
   - Có tình huống cụ thể
   - Có giải pháp/áp dụng
   - Dễ liên hệ với thực tế
4. Sử dụng tiếng Việt

Trả về JSON format:
{
  "title": "Tên ví dụ",
  "content": "Nội dung ví dụ chi tiết...",
  "rewards": { "xp": 5, "coin": 1 }
}`;

    try {
      const completion = await this.openai.chat.completions.create({
        model: this.model,
        messages: [{ role: 'user', content: prompt }],
        response_format: { type: 'json_object' },
        temperature: 0.8,
      });

      const content = completion.choices[0]?.message?.content;
      if (!content) {
        throw new Error('No response from AI');
      }

      const result = JSON.parse(content);

      return {
        title: result.title || 'Ví dụ mới',
        content: result.content || rawText,
        rewards: result.rewards || { xp: 5, coin: 1 },
      };
    } catch (error) {
      console.error('Error generating example:', error);
      throw new Error(`Failed to generate example: ${error.message}`);
    }
  }

  /**
   * Tự động generate Learning Nodes structure từ dữ liệu thô
   * Chỉ cần cung cấp: subject name, description, hoặc danh sách topics
   */
  async generateLearningNodesStructure(
    subjectName: string,
    subjectDescription?: string,
    topicsOrChapters?: string[], // Danh sách topics/chapters nếu có
    numberOfNodes: number = 10,
  ): Promise<Array<{
    title: string;
    description: string;
    order: number;
    prerequisites: string[]; // Sẽ được cập nhật sau khi tạo nodes
    icon: string;
    concepts: Array<{ title: string; content: string }>;
    examples: Array<{ title: string; content: string }>;
    hiddenRewards: Array<{ title: string; content: string }>;
    bossQuiz: {
      question: string;
      options: string[];
      correctAnswer: number;
      explanation: string;
    };
  }>> {
    if (!this.openai) {
      throw new Error('OpenAI API not configured');
    }

    const topicsText = topicsOrChapters && topicsOrChapters.length > 0
      ? `\n\nDanh sách chương/topic có sẵn:\n${topicsOrChapters.map((t, i) => `${i + 1}. ${t}`).join('\n')}`
      : '';

    const prompt = `Bạn là một chuyên gia giáo dục. Nhiệm vụ: Tạo cấu trúc Learning Nodes (bài học) cho môn học "${subjectName}".

${subjectDescription ? `Mô tả môn học: ${subjectDescription}` : ''}${topicsText}

Yêu cầu:
1. Tạo ${numberOfNodes} Learning Nodes (bài học) theo thứ tự từ cơ bản đến nâng cao
2. Mỗi node phải có:
   - title: Tên bài học ngắn gọn, hấp dẫn (ví dụ: "Python Cơ Bản", "Biến và Kiểu Dữ Liệu")
   - description: Mô tả ngắn gọn về bài học (1-2 câu)
   - order: Thứ tự (1, 2, 3, ...)
   - prerequisites: [] (để trống, sẽ tự động cập nhật sau)
   - icon: Emoji phù hợp (ví dụ: 🐍, 📊, ➕)
   - concepts: Mảng 4-6 khái niệm cơ bản trong bài học này
     - Mỗi concept có: title (ngắn gọn, tối đa 50 ký tự) và content (giải thích chi tiết 3-5 câu, dễ hiểu)
   - examples: Mảng 5-8 ví dụ thực tế, mỗi example có:
     - title: Tên ví dụ ngắn gọn, hấp dẫn
     - content: Mô tả chi tiết ví dụ, có tình huống cụ thể và giải pháp
   - hiddenRewards: Mảng 3-5 phần thưởng ẩn, mỗi reward có:
     - title: Tên phần thưởng (ví dụ: "Rương Coin", "Vật Phẩm Đặc Biệt")
     - content: Mô tả cách nhận phần thưởng
   - bossQuiz: 1 bài quiz cuối với:
     - question: Câu hỏi về nội dung bài học
     - options: 4 lựa chọn (A, B, C, D)
     - correctAnswer: Index đáp án đúng (0-3)
     - explanation: Giải thích tại sao đáp án đúng

3. Sắp xếp logic: Bài học sau phải dựa trên kiến thức bài học trước
4. Sử dụng tiếng Việt
5. Phù hợp với người mới bắt đầu học "${subjectName}"

Trả về JSON format (chỉ JSON, không có text khác):
{
  "nodes": [
    {
      "title": "Tên bài học 1",
      "description": "Mô tả ngắn gọn",
      "order": 1,
      "prerequisites": [],
      "icon": "📚",
      "concepts": [
        {
          "title": "Khái niệm 1",
          "content": "Giải thích chi tiết về khái niệm này..."
        }
      ],
      "examples": [
        {
          "title": "Ví dụ 1",
          "content": "Mô tả ví dụ thực tế chi tiết..."
        }
      ],
      "hiddenRewards": [
        {
          "title": "Rương Coin",
          "content": "Phát hiện rương coin khi hoàn thành ví dụ này!"
        }
      ],
      "bossQuiz": {
        "question": "Câu hỏi về nội dung bài học?",
        "options": ["A. Đáp án 1", "B. Đáp án 2", "C. Đáp án 3", "D. Đáp án 4"],
        "correctAnswer": 0,
        "explanation": "Giải thích tại sao đáp án đúng..."
      }
    }
  ]
}`;

    try {
      const completion = await this.openai.chat.completions.create({
        model: this.model,
        messages: [
          {
            role: 'user',
            content: prompt,
          },
        ],
        response_format: { type: 'json_object' },
        temperature: 0.7,
      });

      const content = completion.choices[0]?.message?.content;
      if (!content) {
        throw new Error('No response from AI');
      }

      const result = JSON.parse(content);

      if (!result.nodes || !Array.isArray(result.nodes)) {
        throw new Error('Invalid AI response: missing nodes array');
      }

      // Validate và format nodes
      const nodes = result.nodes.map((node: any, index: number) => ({
        title: node.title || `Bài học ${index + 1}`,
        description: node.description || '',
        order: node.order || index + 1,
        prerequisites: [], // Sẽ được cập nhật sau
        icon: node.icon || '📚',
        concepts: node.concepts || [],
        examples: node.examples || [],
        hiddenRewards: node.hiddenRewards || [],
        bossQuiz: node.bossQuiz || {
          question: `Câu hỏi về ${node.title || `bài học ${index + 1}`}?`,
          options: ['A. Đáp án 1', 'B. Đáp án 2', 'C. Đáp án 3', 'D. Đáp án 4'],
          correctAnswer: 0,
          explanation: 'Giải thích đáp án đúng',
        },
      }));

      console.log(`✅ Generated ${nodes.length} Learning Nodes structure for "${subjectName}"`);
      return nodes;
    } catch (error) {
      console.error('Error generating learning nodes structure:', error);
      throw new Error(`Failed to generate learning nodes: ${error.message}`);
    }
  }
}
