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
   * Chat with JSON mode enabled - guarantees valid JSON response
   * Use this for structured data generation
   */
  async chatWithJsonMode(messages: Array<{ role: string; content: string }>): Promise<string> {
    if (!this.openai) {
      throw new Error('OpenAI API not configured. Please set OPENAI_API_KEY in .env');
    }

    try {
      const openaiMessages: Array<{ role: 'user' | 'assistant' | 'system'; content: string }> = [
        {
          role: 'system',
          content: 'You are a helpful assistant that responds in valid JSON format only. Always use double quotes for strings, escape special characters properly, and ensure the JSON is parseable.',
        },
        ...messages.map((msg) => ({
          role: (msg.role === 'user' ? 'user' : 'assistant') as 'user' | 'assistant',
          content: msg.content,
        })),
      ];

      const completion = await this.openai.chat.completions.create({
        model: this.model,
        messages: openaiMessages,
        response_format: { type: 'json_object' },
        temperature: 0.7,
        max_tokens: 16384,
      });

      return completion.choices[0]?.message?.content || '{}';
    } catch (error) {
      console.error('OpenAI API error (JSON mode):', error);
      throw new Error('Failed to get AI JSON response');
    }
  }

  /**
   * Generate an example for a lesson based on title, content, and example type.
   * Returns { title, content } for the example.
   */
  async generateExample(
    sectionTitle: string,
    sectionContent: string,
    exampleType: string,
  ): Promise<{ title: string; content: string }> {
    const exampleTypeDescriptions: Record<string, string> = {
      real_world_scenario: 'Tình huống thực tế đã tồn tại (VD: BitTorrent, Bitcoin, Google Docs)',
      everyday_analogy: 'So sánh với việc đời thường, dễ hiểu cho người mới (VD: Nhóm bạn ghi sổ chi tiêu)',
      hypothetical_situation: 'Tình huống giả định có thể xảy ra để minh họa khái niệm',
      technical_implementation: 'Ví dụ kỹ thuật cụ thể, có thể có code hoặc cấu hình',
      step_by_step: 'Mô tả từng bước diễn ra của một quy trình (VD: Transaction flow)',
      comparison: 'So sánh 2 cách tiếp cận hoặc 2 khái niệm (VD: Centralized vs Distributed)',
      story_narrative: 'Kể chuyện có nhân vật để minh họa (VD: Alice muốn gửi tiền cho Bob...)',
    };

    const typeDesc = exampleTypeDescriptions[exampleType] || exampleType;

    const prompt = `Bạn là một giáo viên giỏi. Hãy tạo MỘT ví dụ minh họa cho bài học sau:

TIÊU ĐỀ BÀI HỌC: ${sectionTitle}

NỘI DUNG BÀI HỌC:
${sectionContent}

LOẠI VÍ DỤ CẦN TẠO: ${typeDesc}

YÊU CẦU:
1. Ví dụ phải liên quan trực tiếp đến nội dung bài học
2. Viết bằng tiếng Việt, dễ hiểu, sinh động
3. Ví dụ phải đúng loại "${exampleType}" đã yêu cầu
4. Nội dung ví dụ chi tiết, ít nhất 3-5 câu

Trả về JSON:
{
  "title": "Tiêu đề ngắn gọn cho ví dụ",
  "content": "Nội dung chi tiết của ví dụ"
}

CHỈ TRẢ VỀ JSON, KHÔNG CÓ GÌ KHÁC.`;

    const response = await this.chatWithJsonMode([
      { role: 'user', content: prompt },
    ]);

    try {
      const parsed = JSON.parse(response);
      return {
        title: parsed.title || 'Ví dụ',
        content: parsed.content || '',
      };
    } catch {
      // If JSON parsing fails, use raw response
      return {
        title: 'Ví dụ minh họa',
        content: response,
      };
    }
  }

  async simplifyTextLesson(params: {
    title: string;
    content: string;
  }): Promise<string> {
    const { title, content } = params;
    const prompt = `Bạn là một gia sư giỏi. Hãy "đơn giản hóa" bài học sau để người mới học hiểu nhanh hơn.

TIÊU ĐỀ: ${title}

NỘI DUNG:
${content}

YÊU CẦU:
- Viết tiếng Việt, dễ hiểu, rõ ràng.
- Giữ đúng ý nghĩa; không bịa thêm kiến thức mới.
- Ưu tiên câu ngắn, ví dụ minh hoạ nhỏ nếu cần.
- Nếu có thuật ngữ, giải thích ngắn gọn trong ngoặc.
- Trả về CHỈ NỘI DUNG ĐÃ ĐƠN GIẢN HÓA (không thêm tiêu đề, không markdown, không bullet nếu không cần).`;

    const resp = await this.chat([{ role: 'user', content: prompt }]);
    return (resp || '').trim();
  }

  /**
   * Validate, verify, and generate explanations for quiz answers.
   * - Validates question quality and options
   * - Verifies the correct answer
   * - Generates educational explanations for each option
   */
  async generateQuizExplanations(
    question: string,
    options: Array<{ text: string }>,
    correctAnswer: number,
    context?: string,
  ): Promise<{
    validationIssues: string[];
    suggestedCorrectAnswer: number | null;
    suggestedCorrectReason: string | null;
    explanations: Array<{ explanation: string }>;
  }> {
    const labels = ['A', 'B', 'C', 'D'];
    const optionsList = options
      .map((o, i) => `${labels[i]}. ${o.text}`)
      .join('\n');

    const prompt = `Bạn là một giáo viên giỏi. Nhiệm vụ: Kiểm tra và tạo lời giải thích cho câu hỏi quiz.

CÂU HỎI:
${question}

ĐÁP ÁN:
${optionsList}

ĐÁP ÁN ĐÚNG HIỆN TẠI: ${labels[correctAnswer]}${context ? `\n\nNGỮ CẢNH BÀI HỌC: ${context}` : ''}

NHIỆM VỤ:
1. VALIDATE: Kiểm tra câu hỏi và đáp án:
   - Câu hỏi có rõ ràng không?
   - Các đáp án có bị trùng lặp không?
   - Có đủ 4 đáp án khác biệt không?
   - Đáp án có phù hợp với câu hỏi không?
   → Liệt kê vấn đề nếu có (mảng rỗng nếu không có vấn đề)

2. VERIFY: Kiểm tra đáp án đúng:
   - Đáp án ${labels[correctAnswer]} có THỰC SỰ đúng không?
   - Nếu có đáp án khác đúng hơn, đề xuất thay đổi
   → suggestedCorrectAnswer: null nếu đồng ý, hoặc 0-3 nếu đề xuất khác
   → suggestedCorrectReason: lý do đề xuất (null nếu đồng ý)

3. GENERATE: Tạo lời giải thích cho TỪNG đáp án (A, B, C, D):
   - Đáp án ĐÚNG: Bắt đầu bằng "Chính xác!" hoặc "Đúng rồi!" → giải thích TẠI SAO đúng (2-3 câu) → insight sâu hơn
   - Đáp án SAI: Bắt đầu bằng "Chưa đúng lắm!" hoặc "Chưa chính xác!" → giải thích TẠI SAO sai (1-2 câu) → gợi ý hướng đúng
   - Tone: friendly, educational, encouraging
   - Độ dài: 50-150 từ mỗi explanation
   - Viết bằng tiếng Việt

Trả về JSON:
{
  "validationIssues": ["vấn đề 1", "vấn đề 2"],
  "suggestedCorrectAnswer": null,
  "suggestedCorrectReason": null,
  "explanations": [
    { "explanation": "Lời giải thích cho A..." },
    { "explanation": "Lời giải thích cho B..." },
    { "explanation": "Lời giải thích cho C..." },
    { "explanation": "Lời giải thích cho D..." }
  ]
}

CHỈ TRẢ VỀ JSON HỢP LỆ, KHÔNG CÓ GÌ KHÁC.`;

    const response = await this.chatWithJsonMode([
      { role: 'user', content: prompt },
    ]);

    try {
      const parsed = JSON.parse(response);
      return {
        validationIssues: Array.isArray(parsed.validationIssues)
          ? parsed.validationIssues
          : [],
        suggestedCorrectAnswer:
          typeof parsed.suggestedCorrectAnswer === 'number' &&
          parsed.suggestedCorrectAnswer >= 0 &&
          parsed.suggestedCorrectAnswer <= 3
            ? parsed.suggestedCorrectAnswer
            : null,
        suggestedCorrectReason: parsed.suggestedCorrectReason || null,
        explanations: Array.isArray(parsed.explanations)
          ? parsed.explanations.map((e: any) => ({
              explanation: e?.explanation || '',
            }))
          : options.map(() => ({ explanation: '' })),
      };
    } catch {
      return {
        validationIssues: ['Không thể phân tích phản hồi từ AI'],
        suggestedCorrectAnswer: null,
        suggestedCorrectReason: null,
        explanations: options.map(() => ({ explanation: '' })),
      };
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
    domain: string; // Tên chương/domain mà bài học này thuộc về
    type: 'theory' | 'video' | 'image'; // Phân loại: lý thuyết, video, hoặc hình ảnh
    difficulty: 'easy' | 'medium' | 'hard'; // Độ khó: dễ, trung bình, khó
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
   - hiddenRewards: CHỈ 1 phần thưởng ẩn (mảng với 1 phần tử duy nhất), mỗi reward có:
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

  /**
   * Generate a single learning node with detailed content
   * This method generates one node at a time with a focused prompt for better quality
   */
  async generateSingleLearningNode(
    topicName: string,
    topicDescription: string,
    subjectName: string,
    subjectDescription?: string,
    domainName?: string,
    order: number = 1,
  ): Promise<{
    title: string;
    description: string;
    order: number;
    prerequisites: string[];
    icon: string;
    domain: string;
    type: 'theory' | 'video' | 'image';
    difficulty: 'easy' | 'medium' | 'hard';
    concepts: Array<{ title: string; content: string }>;
    examples: Array<{ title: string; content: string }>;
    hiddenRewards: Array<{ title: string; content: string }>;
    bossQuiz: {
      question: string;
      options: string[];
      correctAnswer: number;
      explanation: string;
    };
  }> {
    if (!this.openai) {
      throw new Error('OpenAI API not configured');
    }

    const domainText = domainName ? `\n\nChương/Domain: ${domainName}` : '';
    const subjectContext = subjectDescription 
      ? `\n\nMôn học: ${subjectName}\nMô tả: ${subjectDescription}`
      : `\n\nMôn học: ${subjectName}`;

    const prompt = `Bạn là một chuyên gia giáo dục. Nhiệm vụ: Tạo MỘT bài học CHI TIẾT và TOÀN DIỆN về chủ đề "${topicName}".

Chủ đề: ${topicName}
Mô tả: ${topicDescription}${domainText}${subjectContext}

YÊU CẦU NGHIÊM NGẶT:

1. PHÂN LOẠI BÀI HỌC (type):
   - "theory": Bài học lý thuyết, chủ yếu là văn bản, khái niệm, định nghĩa
   - "video": Bài học cần video để minh họa, hướng dẫn thực hành, demo
   - "image": Bài học cần hình ảnh để minh họa, diagram, infographic

2. ĐÁNH NHÃN ĐỘ KHÓ (difficulty):
   - "easy": Bài học cơ bản, dễ hiểu, phù hợp người mới bắt đầu
   - "medium": Bài học trung bình, cần kiến thức nền tảng
   - "hard": Bài học khó, nâng cao, yêu cầu kiến thức sâu

3. NỘI DUNG BÀI HỌC PHẢI RẤT CHI TIẾT:
   - title: Tên bài học ngắn gọn, hấp dẫn
   - description: Mô tả ngắn gọn về bài học (1-2 câu)
   - order: ${order}
   - prerequisites: [] (để trống)
   - icon: Emoji phù hợp
   - domain: ${domainName || 'Chương chung'}
   - type: "theory" | "video" | "image" (PHÂN LOẠI phù hợp)
   - difficulty: "easy" | "medium" | "hard" (ĐÁNH NHÃN độ khó phù hợp)
   
   - concepts: Mảng 5-8 khái niệm CƠ BẢN và QUAN TRỌNG NHẤT về "${topicName}"
     * Mỗi concept có: 
       - title: Ngắn gọn, tối đa 50 ký tự
       - content: Giải thích CỰC KỲ CHI TIẾT và ĐẦY ĐỦ (tối thiểu 1200-2000 từ), bao gồm:
         + Giới thiệu khái niệm (100-200 từ)
         + Giải thích chi tiết với các bước/điểm chính (400-800 từ)
         + Nhiều ví dụ minh họa cụ thể và chi tiết (300-600 từ)
         + Lưu ý quan trọng và tips (100-200 từ)
         + Ứng dụng thực tế và case studies (200-400 từ)
         + Tóm tắt và bài tập tự luyện (100-200 từ)
         + Sử dụng markdown để format (headers, lists, code blocks, tables)
   
   - examples: Mảng 6-10 ví dụ THỰC TẾ và CHI TIẾT về "${topicName}"
     * Mỗi example có:
       - title: Tên ví dụ ngắn gọn, hấp dẫn
       - content: Mô tả CỰC KỲ CHI TIẾT và ĐẦY ĐỦ (tối thiểu 800-1600 từ), bao gồm:
         + Tình huống/thực tế cụ thể và chi tiết (200-400 từ)
         + Vấn đề cần giải quyết và phân tích (150-300 từ)
         + Giải pháp từng bước chi tiết với hướng dẫn cụ thể (300-600 từ)
         + Kết quả và phân tích kết quả (100-200 từ)
         + Bài học rút ra và ứng dụng (50-100 từ)
         + Sử dụng markdown để format
   
   - hiddenRewards: CHỈ 1 phần thưởng ẩn thú vị và hấp dẫn (mảng với 1 phần tử duy nhất)
     * Reward có:
       - title: Tên phần thưởng ngắn gọn, hấp dẫn
       - content: Mô tả phần thưởng và cách nhận được
   
   - bossQuiz: Câu hỏi kiểm tra kiến thức về "${topicName}"
     * question: Câu hỏi rõ ràng, liên quan trực tiếp đến nội dung bài học
     * options: 4 lựa chọn (A, B, C, D) - chỉ có 1 đáp án đúng
     * correctAnswer: Index của đáp án đúng (0-3)
     * explanation: Giải thích CHI TIẾT tại sao đáp án đúng (100-200 từ)

**QUAN TRỌNG:**
- Nội dung phải CỰC KỲ CHI TIẾT, không được sơ sài
- Mỗi concept và example phải có đủ số từ yêu cầu
- Sử dụng markdown để format đẹp (headers, lists, code blocks, tables)
- Nội dung phải thực tế, dễ hiểu, phù hợp với level của bài học

Trả về JSON format (chỉ JSON, không có text khác):
{
  "title": "Tên bài học",
  "description": "Mô tả ngắn gọn",
  "order": ${order},
  "prerequisites": [],
  "icon": "📚",
  "domain": "${domainName || 'Chương chung'}",
  "type": "theory" | "video" | "image",
  "difficulty": "easy" | "medium" | "hard",
  "concepts": [
    {
      "title": "Khái niệm 1",
      "content": "Nội dung CỰC KỲ CHI TIẾT (tối thiểu 1200-2000 từ) với markdown..."
    }
  ],
  "examples": [
    {
      "title": "Ví dụ 1",
      "content": "Mô tả CỰC KỲ CHI TIẾT (tối thiểu 800-1600 từ) với markdown..."
    }
  ],
  "hiddenRewards": [
    {
      "title": "Rương Coin",
      "content": "Phát hiện rương coin khi hoàn thành bài học này!"
    }
  ],
  "bossQuiz": {
    "question": "Câu hỏi về ${topicName}?",
    "options": ["A. Đáp án 1", "B. Đáp án 2", "C. Đáp án 3", "D. Đáp án 4"],
    "correctAnswer": 0,
    "explanation": "Giải thích CHI TIẾT tại sao đáp án đúng..."
  }
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
        max_tokens: 16384,
      });

      const content = completion.choices[0]?.message?.content;
      if (!content) {
        throw new Error('No response from AI');
      }

      const result = JSON.parse(content);

      // Validate and format
      const node = {
        title: result.title || `Bài học về ${topicName}`,
        description: result.description || topicDescription,
        order: result.order || order,
        prerequisites: [],
        icon: result.icon || '📚',
        domain: result.domain || domainName || 'Chương chung',
        type: result.type || 'theory',
        difficulty: result.difficulty || 'medium',
        concepts: result.concepts || [],
        examples: result.examples || [],
        hiddenRewards: result.hiddenRewards || [],
        bossQuiz: result.bossQuiz || {
          question: `Câu hỏi về ${topicName}?`,
          options: ['A. Đáp án 1', 'B. Đáp án 2', 'C. Đáp án 3', 'D. Đáp án 4'],
          correctAnswer: 0,
          explanation: 'Giải thích đáp án đúng',
        },
      };

      console.log(`✅ Generated single Learning Node: "${node.title}" for topic "${topicName}"`);
      return node;
    } catch (error) {
      console.error('Error generating single learning node:', error);
      throw new Error(`Failed to generate learning node: ${error.message}`);
    }
  }

  /**
   * Generate content for a specific difficulty level
   * Used to create easy/medium/hard versions of concepts and examples
   */
  async generateContentByDifficulty(
    nodeTitle: string,
    nodeDescription: string,
    subjectName: string,
    difficulty: 'easy' | 'medium' | 'hard',
    existingConceptTitles?: string[],
    existingExampleTitles?: string[],
  ): Promise<{
    concepts: Array<{ title: string; content: string }>;
    examples: Array<{ title: string; content: string }>;
  }> {
    if (!this.openai) {
      throw new Error('OpenAI API not configured');
    }

    const difficultyConfig = {
      easy: {
        label: 'ĐƠN GIẢN',
        description: 'Nội dung cơ bản, ngắn gọn, dễ hiểu, phù hợp người mới bắt đầu',
        wordCount: '300-500 từ mỗi phần',
        style: `
- Sử dụng ngôn ngữ ĐƠN GIẢN, tránh thuật ngữ chuyên môn
- Giải thích từng bước một, rõ ràng
- Dùng nhiều ví von (analogies) từ đời thường
- Tập trung vào ý chính, không đi sâu chi tiết
- Có hình ảnh minh họa đơn giản (mô tả bằng text)`,
        conceptCount: '2-3 khái niệm cơ bản',
        exampleCount: '2-3 ví dụ đơn giản, thực tế',
      },
      medium: {
        label: 'CHI TIẾT',
        description: 'Nội dung cân bằng, đầy đủ thông tin, phù hợp đa số người học',
        wordCount: '600-1000 từ mỗi phần',
        style: `
- Giải thích đầy đủ với thuật ngữ kèm giải nghĩa
- Bao gồm các bước thực hiện chi tiết
- Ví dụ thực tế đa dạng
- Có tips và lưu ý quan trọng
- Cân bằng giữa lý thuyết và thực hành`,
        conceptCount: '3-4 khái niệm chi tiết',
        exampleCount: '3-4 ví dụ thực tế, đa dạng',
      },
      hard: {
        label: 'CHUYÊN SÂU',
        description: 'Nội dung nâng cao, chuyên sâu, phù hợp người đã có nền tảng',
        wordCount: '1000-2000 từ mỗi phần',
        style: `
- Đi sâu vào lý thuyết nền tảng và nguyên lý
- Sử dụng thuật ngữ chuyên ngành (có giải thích ngắn)
- Phân tích các edge cases, exceptions, anti-patterns
- Liên hệ đến các khái niệm nâng cao
- Bao gồm best practices, performance considerations
- Case studies phức tạp từ thực tế`,
        conceptCount: '3-5 khái niệm chuyên sâu',
        exampleCount: '3-5 case studies và ví dụ nâng cao',
      },
    };

    const config = difficultyConfig[difficulty];

    const prompt = `Bạn là chuyên gia giáo dục. Nhiệm vụ: Tạo nội dung học tập ở mức độ ${config.label} cho bài học.

THÔNG TIN BÀI HỌC:
- Tiêu đề: ${nodeTitle}
- Mô tả: ${nodeDescription}
- Môn học: ${subjectName}

${existingConceptTitles?.length ? `CÁC KHÁI NIỆM ĐÃ CÓ (tham khảo, tạo nội dung khác):\n${existingConceptTitles.join(', ')}` : ''}

${existingExampleTitles?.length ? `CÁC VÍ DỤ ĐÃ CÓ (tham khảo, tạo ví dụ khác):\n${existingExampleTitles.join(', ')}` : ''}

YÊU CẦU MỨC ĐỘ ${config.label}:
${config.description}

PHONG CÁCH VIẾT:
${config.style}

SỐ LƯỢNG:
- Concepts: ${config.conceptCount}
- Examples: ${config.exampleCount}

ĐỘ DÀI: ${config.wordCount}

FORMAT:
- Sử dụng markdown (headers, lists, code blocks nếu cần)
- Nội dung phải HOÀN TOÀN KHÁC với các khái niệm/ví dụ đã có
- Đảm bảo phù hợp với mức độ ${config.label}

Trả về JSON:
{
  "concepts": [
    {
      "title": "Tên khái niệm ngắn gọn",
      "content": "Nội dung markdown chi tiết..."
    }
  ],
  "examples": [
    {
      "title": "Tên ví dụ ngắn gọn",
      "content": "Nội dung markdown chi tiết..."
    }
  ]
}`;

    try {
      const completion = await this.openai.chat.completions.create({
        model: this.model,
        messages: [{ role: 'user', content: prompt }],
        response_format: { type: 'json_object' },
        temperature: 0.7,
        max_tokens: 8192,
      });

      const content = completion.choices[0]?.message?.content;
      if (!content) {
        throw new Error('No response from AI');
      }

      const result = JSON.parse(content);

      console.log(`✅ Generated ${difficulty} content: ${result.concepts?.length || 0} concepts, ${result.examples?.length || 0} examples`);

      return {
        concepts: result.concepts || [],
        examples: result.examples || [],
      };
    } catch (error) {
      console.error(`Error generating ${difficulty} content:`, error);
      throw new Error(`Failed to generate ${difficulty} content: ${error.message}`);
    }
  }

  /**
   * Generate 3 text variants (simple, detailed, comprehensive) for a lesson content
   * Used when user views a lesson - they can choose their preferred complexity level
   */
  async generateTextVariants(
    title: string,
    originalContent: string,
    subjectName: string,
    lessonContext?: string,
  ): Promise<{
    simple: string;
    detailed: string;
    comprehensive: string;
  }> {
    if (!this.openai) {
      throw new Error('OpenAI API not configured');
    }

    const prompt = `Bạn là chuyên gia giáo dục. Nhiệm vụ: Tạo 3 phiên bản nội dung học tập từ nội dung gốc.

THÔNG TIN BÀI HỌC:
- Tiêu đề: ${title}
- Môn học: ${subjectName}
${lessonContext ? `- Ngữ cảnh: ${lessonContext}` : ''}

NỘI DUNG GỐC:
${originalContent}

TẠO 3 PHIÊN BẢN:

1. **SIMPLE (Đơn giản)** - 150-300 từ:
   - Tóm tắt ngắn gọn, dễ hiểu
   - Chỉ giữ ý chính quan trọng nhất
   - Ngôn ngữ đơn giản, tránh thuật ngữ
   - Dùng ví von từ đời thường
   - Phù hợp người mới bắt đầu hoặc muốn ôn nhanh

2. **DETAILED (Chi tiết)** - 400-800 từ:
   - Giữ nguyên hoặc cải thiện nội dung gốc
   - Giải thích đầy đủ các khái niệm
   - Có ví dụ minh họa
   - Có tips và lưu ý quan trọng
   - Phù hợp đa số người học

3. **COMPREHENSIVE (Chuyên sâu)** - 800-1500 từ:
   - Mở rộng từ nội dung gốc
   - Đi sâu vào nguyên lý, lý thuyết nền
   - Liên hệ với các khái niệm liên quan
   - Bao gồm edge cases, best practices
   - Ví dụ thực tế phức tạp, case studies
   - Phù hợp người muốn hiểu sâu

FORMAT: Sử dụng markdown (headers ##, lists -, code blocks nếu cần)

Trả về JSON:
{
  "simple": "Nội dung markdown phiên bản đơn giản...",
  "detailed": "Nội dung markdown phiên bản chi tiết...",
  "comprehensive": "Nội dung markdown phiên bản chuyên sâu..."
}`;

    try {
      const completion = await this.openai.chat.completions.create({
        model: this.model,
        messages: [{ role: 'user', content: prompt }],
        response_format: { type: 'json_object' },
        temperature: 0.7,
        max_tokens: 8192,
      });

      const content = completion.choices[0]?.message?.content;
      if (!content) {
        throw new Error('No response from AI');
      }

      const result = JSON.parse(content);

      console.log(`✅ Generated 3 text variants for: ${title}`);

      return {
        simple: result.simple || originalContent,
        detailed: result.detailed || originalContent,
        comprehensive: result.comprehensive || originalContent,
      };
    } catch (error) {
      console.error('Error generating text variants:', error);
      // Fallback: return original content for all variants
      return {
        simple: originalContent,
        detailed: originalContent,
        comprehensive: originalContent,
      };
    }
  }

  /**
   * Generate video/image placeholders for community contribution
   * Creates detailed descriptions of what media content would be helpful
   */
  async generateMediaPlaceholders(
    nodeTitle: string,
    nodeDescription: string,
    subjectName: string,
    existingConcepts?: string[],
  ): Promise<{
    videoPlaceholders: Array<{
      title: string;
      description: string;
      suggestedContent: string;
      requirements: string[];
      difficulty: 'easy' | 'medium' | 'hard';
      estimatedTime: string;
      tags: string[];
    }>;
    imagePlaceholders: Array<{
      title: string;
      description: string;
      suggestedContent: string;
      requirements: string[];
      difficulty: 'easy' | 'medium' | 'hard';
      estimatedTime: string;
      tags: string[];
    }>;
  }> {
    if (!this.openai) {
      throw new Error('OpenAI API not configured');
    }

    const prompt = `Bạn là chuyên gia giáo dục và multimedia. Nhiệm vụ: Đề xuất các video và hình ảnh hữu ích cho bài học.

THÔNG TIN BÀI HỌC:
- Tiêu đề: ${nodeTitle}
- Mô tả: ${nodeDescription}
- Môn học: ${subjectName}

${existingConcepts?.length ? `CÁC KHÁI NIỆM TRONG BÀI:\n${existingConcepts.join('\n')}` : ''}

YÊU CẦU:
Đề xuất NỘI DUNG MEDIA phù hợp để cộng đồng có thể đóng góp.

1. VIDEO PLACEHOLDERS (1-3 video):
   - Chỉ đề xuất video KHI CẦN THIẾT (hướng dẫn thực hành, demo, giải thích phức tạp)
   - Mỗi video có:
     * title: Tên ngắn gọn
     * description: Mô tả ngắn về video
     * suggestedContent: Mô tả CHI TIẾT nội dung video (kịch bản, góc quay, các phần cần có)
     * requirements: Yêu cầu kỹ thuật (độ dài, chất lượng, âm thanh...)
     * difficulty: "easy" | "medium" | "hard" (độ khó để tạo video này)
     * estimatedTime: Thời gian ước tính để tạo
     * tags: Tags phân loại

2. IMAGE PLACEHOLDERS (2-4 hình ảnh):
   - Đề xuất hình ảnh/infographic/diagram hữu ích
   - Mỗi hình có:
     * title: Tên ngắn gọn
     * description: Mô tả ngắn
     * suggestedContent: Mô tả CHI TIẾT nội dung hình (bố cục, các phần tử, màu sắc gợi ý)
     * requirements: Yêu cầu kỹ thuật (kích thước, định dạng, font...)
     * difficulty: "easy" | "medium" | "hard"
     * estimatedTime: Thời gian ước tính
     * tags: Tags phân loại

LƯU Ý:
- Chỉ đề xuất media THỰC SỰ HỮU ÍCH cho bài học
- Nếu bài học là lý thuyết đơn giản, có thể không cần video
- Ưu tiên hình ảnh/diagram cho khái niệm trừu tượng
- Ưu tiên video cho hướng dẫn thực hành

Trả về JSON:
{
  "videoPlaceholders": [...],
  "imagePlaceholders": [...]
}`;

    try {
      const completion = await this.openai.chat.completions.create({
        model: this.model,
        messages: [{ role: 'user', content: prompt }],
        response_format: { type: 'json_object' },
        temperature: 0.7,
        max_tokens: 4096,
      });

      const content = completion.choices[0]?.message?.content;
      if (!content) {
        throw new Error('No response from AI');
      }

      const result = JSON.parse(content);

      console.log(`✅ Generated media placeholders: ${result.videoPlaceholders?.length || 0} videos, ${result.imagePlaceholders?.length || 0} images`);

      return {
        videoPlaceholders: result.videoPlaceholders || [],
        imagePlaceholders: result.imagePlaceholders || [],
      };
    } catch (error) {
      console.error('Error generating media placeholders:', error);
      throw new Error(`Failed to generate media placeholders: ${error.message}`);
    }
  }

  /**
   * Generate mind map (knowledge graph structure) for a subject
   * Returns nodes and edges representing the knowledge structure
   */
  async generateMindMap(
    subjectName: string,
    subjectDescription?: string,
  ): Promise<{
    nodes: Array<{
      name: string;
      description: string;
      type: 'subject' | 'domain' | 'concept' | 'topic';
      metadata?: {
        icon?: string;
        level?: 'beginner' | 'intermediate' | 'advanced';
        estimatedTime?: number;
        prerequisites?: string[];
      };
    }>;
    edges: Array<{
      from: string;
      to: string;
      type: 'prerequisite' | 'related' | 'part_of';
      metadata?: any;
    }>;
  }> {
    if (!this.openai) {
      throw new Error('OpenAI API not configured');
    }

    const prompt = `Bạn là một chuyên gia giáo dục và sư phạm. Nhiệm vụ: Tạo MIND MAP (sơ đồ tư duy) 3 LỚP CHI TIẾT và TOÀN DIỆN cho môn học "${subjectName}".

${subjectDescription ? `Mô tả môn học: ${subjectDescription}` : ''}

YÊU CẦU NGHIÊM NGẶT - MIND MAP 3 LỚP:

**LỚP 1 - SUBJECT (Môn học chính):**
- Chỉ có 1 node: Tên môn học "${subjectName}"
- type: "subject"
- description: Mô tả tổng quan về toàn bộ môn học (4-5 câu, rất chi tiết)
- metadata.icon: Emoji đại diện cho môn học

**LỚP 2 - DOMAINS (Các chương/lĩnh vực chính):**
- Tạo từ 6-10 domains (chương học/lĩnh vực chính)
- Mỗi domain phải:
  * type: "domain"
  * name: Tên domain rõ ràng, cụ thể (ví dụ: "Word - Soạn thảo văn bản", "Excel - Bảng tính", "PowerPoint - Trình chiếu")
  * description: Mô tả CHI TIẾT về domain này (3-4 câu, giải thích domain bao gồm những gì, tại sao quan trọng)
  * metadata.icon: Emoji phù hợp
  * metadata.level: Xác định level của domain
  * metadata.estimatedTime: Thời gian ước tính (giờ)
- Mỗi domain phải kết nối với subject bằng edge type: "part_of"

**LỚP 3 - TOPICS (Các chủ đề/concept trong mỗi domain):**
- Mỗi domain phải có từ 5-8 topics (chủ đề cụ thể)
- Tổng số topics: ít nhất 30-60 topics cho toàn bộ mind map
- Mỗi topic phải:
  * type: "topic"
  * name: Tên topic rất cụ thể và rõ ràng (ví dụ: "Định dạng văn bản cơ bản", "Tạo bảng trong Word", "Sử dụng công thức SUM trong Excel")
  * description: Mô tả CHI TIẾT về topic này (2-3 câu, giải thích người học sẽ học gì, học như thế nào)
  * metadata.icon: Emoji phù hợp
  * metadata.level: "beginner" | "intermediate" | "advanced"
  * metadata.estimatedTime: Thời gian ước tính (giờ)
  * metadata.prerequisites: Danh sách tên các topics cần học trước (nếu có)
- Mỗi topic phải kết nối với domain cha bằng edge type: "part_of"
- Tạo các edges "prerequisite" giữa các topics có quan hệ học tập tuần tự

**EDGES (Quan hệ):**
- part_of: Domain là phần của Subject, Topic là phần của Domain
- prerequisite: Topic này cần học trước Topic kia (tạo nhiều prerequisite edges)
- related: Các topics có liên quan nhưng không bắt buộc học trước

**YÊU CẦU CHẤT LƯỢNG:**
1. Mind map phải CHI TIẾT và TOÀN DIỆN, bao quát mọi khía cạnh của môn học
2. Mỗi node phải có description RẤT CHI TIẾT, không phải chỉ là tên
3. Phải có đủ topics (30-60 topics) để người học có lộ trình học tập rõ ràng
4. Logic học tập phải rõ ràng với nhiều prerequisite relationships
5. Phù hợp cho người mới bắt đầu đến nâng cao
6. Các tên node phải rõ ràng, dễ hiểu, không quá trừu tượng

Trả về JSON format (chỉ JSON, không có text khác):
{
  "nodes": [
    {
      "name": "Tên node",
      "description": "Mô tả RẤT CHI TIẾT về node này (2-4 câu)",
      "type": "subject" | "domain" | "topic",
      "metadata": {
        "icon": "📚",
        "level": "beginner" | "intermediate" | "advanced",
        "estimatedTime": 10,
        "prerequisites": ["Tên node khác"]
      }
    }
  ],
  "edges": [
    {
      "from": "Tên node nguồn",
      "to": "Tên node đích",
      "type": "prerequisite" | "related" | "part_of",
      "metadata": {}
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
        max_tokens: 16384,
      });

      const content = completion.choices[0]?.message?.content;
      if (!content) {
        throw new Error('No response from AI');
      }

      const result = JSON.parse(content);

      if (!result.nodes || !Array.isArray(result.nodes)) {
        throw new Error('Invalid AI response: missing nodes array');
      }

      if (!result.edges || !Array.isArray(result.edges)) {
        throw new Error('Invalid AI response: missing edges array');
      }

      // Validate nodes
      const nodes = result.nodes.map((node: any) => ({
        name: node.name || 'Unnamed',
        description: node.description || '',
        type: node.type || 'topic',
        metadata: node.metadata || {},
      }));

      // Validate edges
      const edges = result.edges.map((edge: any) => ({
        from: edge.from || '',
        to: edge.to || '',
        type: edge.type || 'related',
        metadata: edge.metadata || {},
      }));

      console.log(`✅ Generated mind map with ${nodes.length} nodes and ${edges.length} edges for "${subjectName}"`);
      return { nodes, edges };
    } catch (error) {
      console.error('Error generating mind map:', error);
      throw new Error(`Failed to generate mind map: ${error.message}`);
    }
  }

  /**
   * Generate image using DALL-E
   * Returns the URL of the generated image
   */
  async generateImage(
    prompt: string,
    options?: {
      size?: '1024x1024' | '1792x1024' | '1024x1792';
      quality?: 'standard' | 'hd';
      style?: 'vivid' | 'natural';
    },
  ): Promise<{
    url: string;
    revisedPrompt: string;
  }> {
    if (!this.openai) {
      throw new Error('OpenAI API not configured. Please set OPENAI_API_KEY in .env');
    }

    try {
      const response = await this.openai.images.generate({
        model: 'dall-e-3',
        prompt: prompt,
        n: 1,
        size: options?.size || '1024x1024',
        quality: options?.quality || 'standard',
        style: options?.style || 'natural',
      });

      const imageUrl = response.data[0]?.url;
      const revisedPrompt = response.data[0]?.revised_prompt || prompt;

      if (!imageUrl) {
        throw new Error('No image URL returned from DALL-E');
      }

      return {
        url: imageUrl,
        revisedPrompt,
      };
    } catch (error: any) {
      console.error('DALL-E API error:', error);
      throw new Error(`Failed to generate image: ${error.message}`);
    }
  }

  /**
   * Generate multiple images for batch processing
   * Uses parallel requests with rate limiting
   */
  async generateImagesInBatch(
    prompts: string[],
    options?: {
      size?: '1024x1024' | '1792x1024' | '1024x1792';
      quality?: 'standard' | 'hd';
      style?: 'vivid' | 'natural';
      delayMs?: number; // Delay between requests (default: 2000ms)
    },
  ): Promise<Array<{
    prompt: string;
    url?: string;
    revisedPrompt?: string;
    error?: string;
  }>> {
    const results: Array<{
      prompt: string;
      url?: string;
      revisedPrompt?: string;
      error?: string;
    }> = [];

    const delayMs = options?.delayMs || 2000;

    for (const prompt of prompts) {
      try {
        const result = await this.generateImage(prompt, options);
        results.push({
          prompt,
          url: result.url,
          revisedPrompt: result.revisedPrompt,
        });
      } catch (error: any) {
        results.push({
          prompt,
          error: error.message,
        });
      }

      // Rate limiting delay
      if (prompts.indexOf(prompt) < prompts.length - 1) {
        await new Promise(resolve => setTimeout(resolve, delayMs));
      }
    }

    return results;
  }

  /**
   * Generate quiz questions based on content
   * @param contentTitle - Title of the content item
   * @param contentText - The actual content text
   * @param contentType - 'concept' or 'example'
   * @param quizType - 'lesson' (for individual content) or 'boss' (for topic/chapter)
   */
  async generateQuiz(
    contentTitle: string,
    contentText: string,
    contentType: 'concept' | 'example',
    quizType: 'lesson' | 'boss' = 'lesson',
  ): Promise<{
    questions: Array<{
      id: string;
      question: string;
      options: { A: string; B: string; C: string; D: string };
      correctAnswer: 'A' | 'B' | 'C' | 'D';
      explanation: string;
      category: string;
    }>;
    passingScore: number;
    totalQuestions: number;
  }> {
    if (!this.openai) {
      throw new Error('OpenAI API not configured');
    }

    let prompt: string;
    let questionCount: number;
    let passingScore: number;

    if (quizType === 'boss') {
      // Boss Quiz: 25 câu, yêu cầu 80%
      questionCount = 25;
      passingScore = 80;
      prompt = `Bạn là người thiết kế bài kiểm tra kiến thức.

Nội dung cần kiểm tra:
Tiêu đề: ${contentTitle}
Nội dung: ${contentText}

Yêu cầu chung:
– Câu hỏi trắc nghiệm 4 lựa chọn (A, B, C, D)
– Chỉ có 1 đáp án đúng
– Không dùng câu hỏi yêu cầu nhớ nguyên văn định nghĩa
– Tránh câu quá dễ hoặc đánh đố vô lý

Cấu trúc 25 câu:

1. Khái niệm & bản chất (7-8 câu):
   - Định nghĩa theo cách hiểu
   - Phân biệt khái niệm gần nhau
   - Nhận diện phát biểu đúng/sai

2. Ví dụ & vận dụng (12-13 câu):
   - Nhận diện ví dụ đúng
   - Loại trừ ví dụ sai
   - Áp dụng vào tình huống ngắn

3. Liên hệ & tổng hợp (4-5 câu):
   - Kết nối các phần trong chương
   - Hiểu sai phổ biến
   - Hệ quả nếu áp dụng sai

Trả về JSON với format:
{
  "questions": [
    {
      "id": "q1",
      "question": "Câu hỏi...",
      "options": { "A": "...", "B": "...", "C": "...", "D": "..." },
      "correctAnswer": "A",
      "explanation": "Giải thích vì sao A đúng và các đáp án khác sai",
      "category": "concept|example|synthesis"
    }
  ]
}`;
    } else {
      // Lesson Quiz: ~12 câu, yêu cầu 70%
      passingScore = 70;
      
      if (contentType === 'concept') {
        questionCount = 5;
        prompt = `Bạn là người thiết kế bài kiểm tra kiến thức.

Kiến thức cần kiểm tra (KHÁI NIỆM):
Tiêu đề: ${contentTitle}
Nội dung: ${contentText}

Yêu cầu chung:
– Câu hỏi trắc nghiệm 4 lựa chọn (A, B, C, D)
– Chỉ có 1 đáp án đúng
– Không dùng câu hỏi yêu cầu nhớ nguyên văn định nghĩa
– Tránh câu quá dễ hoặc đánh đố vô lý

Mục tiêu: kiểm tra người học hiểu đúng bản chất, không học thuộc.

Tạo 5 câu hỏi:
- 2-3 câu: chọn định nghĩa đúng hoặc nhận diện mô tả đúng bản chất khái niệm
- 2-3 câu: phân biệt khái niệm này với các khái niệm gần giống, dễ nhầm lẫn

Trả về JSON với format:
{
  "questions": [
    {
      "id": "q1",
      "question": "Câu hỏi...",
      "options": { "A": "...", "B": "...", "C": "...", "D": "..." },
      "correctAnswer": "A",
      "explanation": "Giải thích vì sao A đúng và các đáp án khác sai",
      "category": "definition|distinction"
    }
  ]
}`;
      } else {
        questionCount = 7;
        prompt = `Bạn là người thiết kế bài kiểm tra kiến thức.

Kiến thức cần kiểm tra (VÍ DỤ / VẬN DỤNG):
Tiêu đề: ${contentTitle}
Nội dung: ${contentText}

Yêu cầu chung:
– Câu hỏi trắc nghiệm 4 lựa chọn (A, B, C, D)
– Chỉ có 1 đáp án đúng
– Không dùng câu hỏi yêu cầu nhớ nguyên văn định nghĩa
– Tránh câu quá dễ hoặc đánh đố vô lý

Mục tiêu: kiểm tra khả năng áp dụng và nhận diện đúng/sai.

Tạo 7 câu hỏi:
- 3-4 câu: chọn ví dụ đúng với khái niệm
- 2-3 câu: chọn ví dụ sai / không phù hợp
- 1-2 câu: tình huống ngắn (mini-case), yêu cầu xác định cách hiểu hoặc áp dụng đúng

Trả về JSON với format:
{
  "questions": [
    {
      "id": "q1", 
      "question": "Câu hỏi...",
      "options": { "A": "...", "B": "...", "C": "...", "D": "..." },
      "correctAnswer": "A",
      "explanation": "Giải thích vì sao A đúng và các đáp án khác sai",
      "category": "correct_example|wrong_example|mini_case"
    }
  ]
}`;
      }
    }

    try {
      const response = await this.openai.chat.completions.create({
        model: this.model,
        messages: [
          {
            role: 'system',
            content: 'Bạn là chuyên gia thiết kế bài kiểm tra. Luôn trả về JSON hợp lệ.',
          },
          { role: 'user', content: prompt },
        ],
        response_format: { type: 'json_object' },
        temperature: 0.7,
      });

      const content = response.choices[0]?.message?.content || '{}';
      const parsed = JSON.parse(content);

      return {
        questions: parsed.questions || [],
        passingScore,
        totalQuestions: parsed.questions?.length || questionCount,
      };
    } catch (error: any) {
      console.error('Error generating quiz:', error);
      throw new Error(`Failed to generate quiz: ${error.message}`);
    }
  }
}
