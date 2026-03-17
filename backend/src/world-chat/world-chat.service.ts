import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ChatMessage } from './entities/chat-message.entity';
import { UserCurrencyService } from '../user-currency/user-currency.service';

@Injectable()
export class WorldChatService {
  private static readonly MAX_MESSAGE_LENGTH = 500;
  private static readonly RATE_LIMIT_SECONDS = 3;
  private static readonly MAX_MESSAGES_PER_FETCH = 50;

  private lastMessageTime = new Map<string, number>();

  constructor(
    @InjectRepository(ChatMessage)
    private chatRepository: Repository<ChatMessage>,
    private currencyService: UserCurrencyService,
  ) {}

  async sendMessage(
    userId: string,
    username: string,
    message: string,
    replyToId?: string | null,
  ): Promise<ChatMessage> {
    const trimmed = message.trim();
    if (!trimmed || trimmed.length === 0) {
      throw new BadRequestException('Tin nhắn không được để trống');
    }
    if (trimmed.length > WorldChatService.MAX_MESSAGE_LENGTH) {
      throw new BadRequestException(
        `Tin nhắn tối đa ${WorldChatService.MAX_MESSAGE_LENGTH} ký tự`,
      );
    }

    const now = Date.now();
    const last = this.lastMessageTime.get(userId) || 0;
    if (now - last < WorldChatService.RATE_LIMIT_SECONDS * 1000) {
      throw new BadRequestException('Bạn gửi tin quá nhanh. Vui lòng chờ vài giây.');
    }
    this.lastMessageTime.set(userId, now);

    let userLevel = 1;
    try {
      const currency = await this.currencyService.getCurrency(userId);
      userLevel = currency.level || 1;
    } catch {}

    if (replyToId) {
      const replyTo = await this.chatRepository.findOne({ where: { id: replyToId } });
      if (!replyTo) throw new BadRequestException('Tin nhắn cần trả lời không tồn tại');
    }

    const chatMessage = this.chatRepository.create({
      userId,
      username,
      message: trimmed,
      userLevel,
      replyToId: replyToId || null,
    });

    return this.chatRepository.save(chatMessage);
  }

  async deleteMessage(messageId: string, userId: string): Promise<void> {
    const msg = await this.chatRepository.findOne({ where: { id: messageId } });
    if (!msg) throw new NotFoundException('Tin nhắn không tồn tại');
    if (msg.userId !== userId) throw new ForbiddenException('Chỉ xóa được tin nhắn của mình');
    await this.chatRepository.remove(msg);
  }

  async getMessages(options?: {
    limit?: number;
    before?: string;
    after?: string;
  }): Promise<ChatMessage[]> {
    const limit = Math.min(
      options?.limit || 30,
      WorldChatService.MAX_MESSAGES_PER_FETCH,
    );

    const qb = this.chatRepository
      .createQueryBuilder('msg')
      .leftJoinAndSelect('msg.replyTo', 'replyTo')
      .orderBy('msg.createdAt', 'DESC')
      .take(limit);

    if (options?.before) {
      qb.andWhere('msg.createdAt < :before', { before: new Date(options.before) });
    }
    if (options?.after) {
      qb.andWhere('msg.createdAt > :after', { after: new Date(options.after) });
    }

    const messages = await qb.getMany();
    return messages.reverse();
  }

  async getOnlineCount(): Promise<number> {
    const fiveMinutesAgo = new Date();
    fiveMinutesAgo.setMinutes(fiveMinutesAgo.getMinutes() - 5);

    const result = await this.chatRepository
      .createQueryBuilder('msg')
      .select('COUNT(DISTINCT msg.userId)', 'count')
      .where('msg.createdAt > :since', { since: fiveMinutesAgo })
      .getRawOne();

    return parseInt(result?.count || '0', 10);
  }
}
