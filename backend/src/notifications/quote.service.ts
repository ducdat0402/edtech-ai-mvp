import { Injectable } from '@nestjs/common';
import { BUILT_IN_QUOTES, MotivationalQuote } from './data/quotes';
import { AiService } from '../ai/ai.service';

@Injectable()
export class QuoteService {
  private aiGeneratedQuotes: MotivationalQuote[] = [];
  private userQuoteHistory: Map<string, string[]> = new Map();
  private static readonly HISTORY_SIZE = 20;

  constructor(private aiService: AiService) {}

  get allQuotes(): MotivationalQuote[] {
    return [...BUILT_IN_QUOTES, ...this.aiGeneratedQuotes];
  }

  getRandomQuote(
    userId: string,
    preferredCategory?: MotivationalQuote['category'],
  ): MotivationalQuote {
    const history = this.userQuoteHistory.get(userId) ?? [];
    let pool = this.allQuotes.filter((q) => !history.includes(q.id));

    if (preferredCategory) {
      const categoryPool = pool.filter((q) => q.category === preferredCategory);
      if (categoryPool.length > 0) pool = categoryPool;
    }

    if (pool.length === 0) {
      this.userQuoteHistory.set(userId, []);
      pool = this.allQuotes;
      if (preferredCategory) {
        const categoryPool = pool.filter((q) => q.category === preferredCategory);
        if (categoryPool.length > 0) pool = categoryPool;
      }
    }

    const quote = pool[Math.floor(Math.random() * pool.length)];

    const updatedHistory = [...history, quote.id].slice(-QuoteService.HISTORY_SIZE);
    this.userQuoteHistory.set(userId, updatedHistory);

    return quote;
  }

  /**
   * Pick the best category based on user state.
   * - inactive / broken streak → healing or encouragement
   * - low streak (1-3) → encouragement or discipline
   * - building streak (4-14) → discipline or stoic
   * - high streak (15+) → stoic or proverb (praise mode)
   */
  pickCategoryForState(
    streakDays: number,
    daysSinceLastActive: number,
  ): MotivationalQuote['category'] {
    if (daysSinceLastActive >= 3) return 'healing';
    if (daysSinceLastActive >= 1 && streakDays === 0) return 'encouragement';
    if (streakDays <= 3) return 'encouragement';
    if (streakDays <= 14) return 'discipline';
    return 'stoic';
  }

  async generateQuotesWithAI(count: number = 10): Promise<MotivationalQuote[]> {
    try {
      const prompt = `Tạo ${count} câu nói truyền cảm hứng về học tập, kỷ luật, và phát triển bản thân.
Mỗi câu ngắn gọn (tối đa 20 từ), bằng tiếng Việt, phong cách gần gũi với học sinh/sinh viên Việt Nam.
Pha trộn: triết học Khắc kỷ, tục ngữ, chữa lành, kỷ luật, động viên.

Trả về JSON array:
[{"text": "...", "author": "...", "category": "stoic|proverb|healing|discipline|encouragement"}]

Chỉ trả về JSON, không giải thích.`;

      const result = await this.aiService.chatWithJsonMode([
        { role: 'user', content: prompt },
      ]);

      const parsed = JSON.parse(result);
      if (!Array.isArray(parsed)) return [];

      const newQuotes: MotivationalQuote[] = parsed.map(
        (q: any, i: number) => ({
          id: `ai_${Date.now()}_${i}`,
          text: q.text,
          author: q.author || '',
          category: q.category || 'encouragement',
        }),
      );

      this.aiGeneratedQuotes.push(...newQuotes);

      const maxAiQuotes = 100;
      if (this.aiGeneratedQuotes.length > maxAiQuotes) {
        this.aiGeneratedQuotes = this.aiGeneratedQuotes.slice(-maxAiQuotes);
      }

      return newQuotes;
    } catch (error) {
      console.error('Failed to generate AI quotes:', error);
      return [];
    }
  }

  getQuoteStats() {
    return {
      builtIn: BUILT_IN_QUOTES.length,
      aiGenerated: this.aiGeneratedQuotes.length,
      total: this.allQuotes.length,
      categoryCounts: {
        stoic: this.allQuotes.filter((q) => q.category === 'stoic').length,
        proverb: this.allQuotes.filter((q) => q.category === 'proverb').length,
        healing: this.allQuotes.filter((q) => q.category === 'healing').length,
        discipline: this.allQuotes.filter((q) => q.category === 'discipline').length,
        encouragement: this.allQuotes.filter((q) => q.category === 'encouragement').length,
      },
    };
  }
}
