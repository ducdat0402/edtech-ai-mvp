import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AiUsageLog } from './entities/ai-usage-log.entity';

@Injectable()
export class AiUsageService {
  constructor(
    @InjectRepository(AiUsageLog)
    private readonly repo: Repository<AiUsageLog>,
  ) {}

  /** Ngày theo lịch Việt Nam (YYYY-MM-DD). */
  calendarDateVN(d: Date = new Date()): string {
    return d.toLocaleDateString('en-CA', { timeZone: 'Asia/Ho_Chi_Minh' });
  }

  /**
   * Atomically consume 1 free usage for (userId, buttonType, today).
   * Throws 429 when limit exceeded.
   */
  async consumeFreeOrThrow(params: {
    userId: string;
    buttonType: string;
    freeLimit: number;
  }): Promise<{ usedCount: number; remainingFreeUsesToday: number; date: string }> {
    const { userId, buttonType, freeLimit } = params;
    const date = this.calendarDateVN();

    // Use an UPSERT with a guard to keep it atomic under concurrency.
    const rows = (await this.repo.query(
      `
INSERT INTO ai_usage_logs ("userId","buttonType","date","usedCount")
VALUES ($1,$2,$3,1)
ON CONFLICT ("userId","buttonType","date")
DO UPDATE SET "usedCount" = ai_usage_logs."usedCount" + 1, "updatedAt" = now()
WHERE ai_usage_logs."usedCount" < $4
RETURNING "usedCount";
      `,
      [userId, buttonType, date, freeLimit],
    )) as Array<{ usedCount: number }>;

    if (!rows || rows.length === 0) {
      const existing = await this.repo.findOne({
        where: { userId, buttonType, date },
        select: { usedCount: true, date: true },
      });
      const used = existing?.usedCount ?? freeLimit;
      throw new HttpException(
        {
        message:
          'Bạn đã dùng hết lượt miễn phí hôm nay. Nâng cấp để dùng nhiều lượt hơn.',
        requiresPaywall: true,
        remainingFreeUsesToday: Math.max(0, freeLimit - used),
        freeLimit,
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const usedCount = Number(rows[0].usedCount) || 1;
    return {
      usedCount,
      remainingFreeUsesToday: Math.max(0, freeLimit - usedCount),
      date,
    };
  }
}

