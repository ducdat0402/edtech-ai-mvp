import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/entities/user.entity';
import { UserCurrency } from '../user-currency/entities/user-currency.entity';
import { QuoteService } from './quote.service';

export type UserEngagementState =
  | 'inactive_long'     // 7+ days no activity
  | 'inactive_recent'   // 3-6 days no activity
  | 'streak_broken'     // was active but missed yesterday
  | 'streak_low'        // streak 1-3
  | 'streak_building'   // streak 4-14
  | 'streak_high'       // streak 15+
  | 'new_user';         // no lastActiveDate

export interface NotificationPayload {
  userId: string;
  title: string;
  body: string;
  quote: string;
  quoteAuthor: string;
  engagementState: UserEngagementState;
  streak: number;
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  private readonly VIETNAM_TZ_OFFSET = 7;

  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(UserCurrency)
    private currencyRepository: Repository<UserCurrency>,
    private quoteService: QuoteService,
  ) {}

  classifyUser(currency: UserCurrency): UserEngagementState {
    if (!currency.lastActiveDate) return 'new_user';

    const now = new Date();
    const lastActive = new Date(currency.lastActiveDate);
    const diffMs = now.getTime() - lastActive.getTime();
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

    if (diffDays >= 7) return 'inactive_long';
    if (diffDays >= 3) return 'inactive_recent';

    if (diffDays >= 2 && currency.currentStreak === 0) return 'streak_broken';
    if (currency.currentStreak === 0) return 'streak_broken';
    if (currency.currentStreak <= 3) return 'streak_low';
    if (currency.currentStreak <= 14) return 'streak_building';
    return 'streak_high';
  }

  buildNotification(
    user: User,
    currency: UserCurrency,
    state: UserEngagementState,
  ): NotificationPayload {
    const streak = currency.currentStreak ?? 0;
    const contextMessage = this.getContextMessage(state, streak, user.fullName);
    const category = this.quoteService.pickCategoryForState(
      streak,
      this.daysSinceActive(currency),
    );
    const quote = this.quoteService.getRandomQuote(user.id, category);

    return {
      userId: user.id,
      title: this.getNotificationTitle(state),
      body: contextMessage,
      quote: quote.text,
      quoteAuthor: quote.author,
      engagementState: state,
      streak,
    };
  }

  private getNotificationTitle(state: UserEngagementState): string {
    switch (state) {
      case 'inactive_long':   return 'Nhớ bạn quá! 🥺';
      case 'inactive_recent': return 'Đã lâu không gặp! 👋';
      case 'streak_broken':   return 'Đừng bỏ cuộc nhé! 💪';
      case 'streak_low':      return 'Giữ vững phong độ! 🔥';
      case 'streak_building': return 'Bạn đang rất tuyệt! 🚀';
      case 'streak_high':     return 'Huyền thoại! 👑';
      case 'new_user':        return 'Chào mừng bạn mới! 🌟';
    }
  }

  private getContextMessage(
    state: UserEngagementState,
    streak: number,
    name?: string,
  ): string {
    const displayName = name || 'bạn';

    switch (state) {
      case 'inactive_long':
        return `${displayName} ơi, lâu rồi bạn chưa học. Chỉ cần 5 phút hôm nay là đủ!`;
      case 'inactive_recent':
        return `${displayName}, mấy hôm rồi bạn chưa quay lại. Hãy dành một chút thời gian nhé!`;
      case 'streak_broken':
        return `Streak bị gián đoạn rồi. Nhưng không sao, ${displayName} có thể bắt đầu lại ngay hôm nay!`;
      case 'streak_low':
        return `${displayName} đang có ${streak} ngày streak! Tiếp tục để tạo thói quen nhé.`;
      case 'streak_building':
        return `Wow, ${streak} ngày liên tục! ${displayName} đang xây dựng thói quen tuyệt vời.`;
      case 'streak_high':
        return `${streak} ngày streak! ${displayName} là nguồn cảm hứng cho cả cộng đồng! 🏆`;
      case 'new_user':
        return `Chào ${displayName}! Hãy bắt đầu bài học đầu tiên để khám phá nhé.`;
    }
  }

  private daysSinceActive(currency: UserCurrency): number {
    if (!currency.lastActiveDate) return 999;
    const now = new Date();
    const lastActive = new Date(currency.lastActiveDate);
    return Math.floor(
      (now.getTime() - lastActive.getTime()) / (1000 * 60 * 60 * 24),
    );
  }

  /**
   * Get today's motivation for a specific user (called by mobile app on open).
   */
  async getDailyMotivation(userId: string): Promise<NotificationPayload | null> {
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) return null;

    const currency = await this.currencyRepository.findOne({
      where: { userId },
    });
    if (!currency) return null;

    const pref = user.onboardingData?.notificationPreference;
    if (pref === 'no') return null;

    const state = this.classifyUser(currency);
    return this.buildNotification(user, currency, state);
  }

  /**
   * Cron: evaluate all users daily at 8:00 AM Vietnam time (1:00 AM UTC).
   * Currently logs notifications; integrate push service (FCM) when ready.
   */
  @Cron('0 1 * * *')
  async evaluateAllUsers(): Promise<void> {
    this.logger.log('Starting daily notification evaluation...');

    const users = await this.userRepository.find();
    let sent = 0;
    let skipped = 0;

    for (const user of users) {
      try {
        const pref = user.onboardingData?.notificationPreference;
        if (pref === 'no') {
          skipped++;
          continue;
        }

        const currency = await this.currencyRepository.findOne({
          where: { userId: user.id },
        });
        if (!currency) {
          skipped++;
          continue;
        }

        const state = this.classifyUser(currency);

        // Anti-spam: skip users who were active today (they're already engaged)
        if (this.daysSinceActive(currency) === 0 && state !== 'new_user') {
          skipped++;
          continue;
        }

        // Skip "yes_sometimes" users unless they're inactive 3+ days
        if (pref === 'yes_sometimes' && this.daysSinceActive(currency) < 3) {
          skipped++;
          continue;
        }

        const payload = this.buildNotification(user, currency, state);

        // TODO: Replace with actual push notification (FCM) when integrated
        this.logger.log(
          `[NOTIFY] ${user.fullName || user.email} (${state}, streak=${payload.streak}): ${payload.body} | "${payload.quote}"`,
        );
        sent++;
      } catch (error) {
        this.logger.error(`Error evaluating user ${user.id}:`, error);
      }
    }

    this.logger.log(
      `Daily evaluation complete: ${sent} notifications, ${skipped} skipped.`,
    );
  }

  /**
   * Cron: generate new AI quotes weekly (Sunday 3 AM UTC).
   */
  @Cron('0 3 * * 0')
  async generateWeeklyQuotes(): Promise<void> {
    this.logger.log('Generating weekly AI quotes...');
    const quotes = await this.quoteService.generateQuotesWithAI(15);
    this.logger.log(`Generated ${quotes.length} new AI quotes.`);
  }

  getQuoteStats() {
    return this.quoteService.getQuoteStats();
  }
}
