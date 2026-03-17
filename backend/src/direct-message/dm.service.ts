import { Injectable, ForbiddenException, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan } from 'typeorm';
import { DirectMessage } from './entities/direct-message.entity';
import { FriendsService } from '../friends/friends.service';
import { FriendshipStatus } from '../friends/entities/friendship.entity';

const MAX_MESSAGE_LENGTH = 2000;
const DEFAULT_PAGE_SIZE = 50;

@Injectable()
export class DmService {
  constructor(
    @InjectRepository(DirectMessage)
    private dmRepository: Repository<DirectMessage>,
    private friendsService: FriendsService,
  ) {}

  /** Check if two users are friends (accepted) and not blocked */
  async canMessage(userA: string, userB: string): Promise<boolean> {
    const friends = await this.friendsService.getFriends(userA);
    return friends.some((f: any) => f.id === userB);
  }

  /** Send a direct message (only between friends). Returns saved message. */
  async sendMessage(
    senderId: string,
    receiverId: string,
    content: string,
    replyToId?: string | null,
  ): Promise<DirectMessage> {
    const trimmed = (content || '').trim();
    if (!trimmed) throw new BadRequestException('Nội dung tin nhắn không được để trống');
    if (trimmed.length > MAX_MESSAGE_LENGTH) {
      throw new BadRequestException(`Tin nhắn tối đa ${MAX_MESSAGE_LENGTH} ký tự`);
    }
    if (senderId === receiverId) throw new BadRequestException('Không thể gửi tin cho chính mình');

    const can = await this.canMessage(senderId, receiverId);
    if (!can) throw new ForbiddenException('Chỉ có thể nhắn tin với bạn bè');

    if (replyToId) {
      const replyTo = await this.dmRepository.findOne({ where: { id: replyToId } });
      if (!replyTo) throw new BadRequestException('Tin nhắn cần trả lời không tồn tại');
      const inConversation =
        (replyTo.senderId === senderId && replyTo.receiverId === receiverId) ||
        (replyTo.senderId === receiverId && replyTo.receiverId === senderId);
      if (!inConversation) throw new BadRequestException('Tin nhắn không thuộc hội thoại này');
    }

    const msg = this.dmRepository.create({
      senderId,
      receiverId,
      content: trimmed,
      readAt: null,
      replyToId: replyToId || null,
    });
    return this.dmRepository.save(msg);
  }

  /** Delete a DM (only sender can delete). Returns receiverId for broadcasting. */
  async deleteMessage(messageId: string, userId: string): Promise<{ receiverId: string }> {
    const msg = await this.dmRepository.findOne({ where: { id: messageId } });
    if (!msg) throw new NotFoundException('Tin nhắn không tồn tại');
    if (msg.senderId !== userId) throw new ForbiddenException('Chỉ xóa được tin nhắn của mình');
    const receiverId = msg.receiverId;
    await this.dmRepository.remove(msg);
    return { receiverId };
  }

  /** Get conversation between current user and peer (paginated, older first for history) */
  async getConversation(
    userId: string,
    peerId: string,
    options?: { limit?: number; before?: string },
  ): Promise<{ messages: DirectMessage[]; hasMore: boolean }> {
    const can = await this.canMessage(userId, peerId);
    if (!can) throw new ForbiddenException('Chỉ xem được hội thoại với bạn bè');

    const limit = Math.min(options?.limit ?? DEFAULT_PAGE_SIZE, 100);
    const before = options?.before ? new Date(options.before) : new Date();

    const messages = await this.dmRepository
      .createQueryBuilder('dm')
      .leftJoinAndSelect('dm.replyTo', 'replyTo')
      .where(
        '((dm.senderId = :userId AND dm.receiverId = :peerId) OR (dm.senderId = :peerId AND dm.receiverId = :userId))',
        { userId, peerId },
      )
      .andWhere('dm.createdAt < :before', { before })
      .orderBy('dm.createdAt', 'DESC')
      .take(limit + 1)
      .getMany();

    const hasMore = messages.length > limit;
    const list = hasMore ? messages.slice(0, limit) : messages;
    list.reverse();
    return { messages: list, hasMore };
  }

  /** List conversations for user: each item = { peer, lastMessage, unreadCount } */
  async getConversations(userId: string): Promise<
    Array<{
      peerId: string;
      peerName: string;
      lastMessage: { content: string; createdAt: Date; isFromPeer: boolean } | null;
      unreadCount: number;
    }>
  > {
    const friends = await this.friendsService.getFriends(userId);
    const friendIds = friends.map((f: any) => f.id);
    if (friendIds.length === 0) return [];

    const raw = await this.dmRepository
      .createQueryBuilder('dm')
      .where('dm.senderId = :userId OR dm.receiverId = :userId', { userId })
      .orderBy('dm.createdAt', 'DESC')
      .getMany();

    const byPeer = new Map<
      string,
      { last: DirectMessage | null; unread: number }
    >();
    for (const id of friendIds) {
      byPeer.set(id, { last: null, unread: 0 });
    }

    for (const m of raw) {
      const peerId = m.senderId === userId ? m.receiverId : m.senderId;
      if (!byPeer.has(peerId)) continue;
      const entry = byPeer.get(peerId)!;
      if (entry.last === null) entry.last = m;
      if (m.receiverId === userId && !m.readAt) entry.unread += 1;
    }

    const nameMap = new Map(friends.map((f: any) => [f.id, f.fullName || f.email || 'User']));

    const list = friendIds.map((peerId) => {
      const entry = byPeer.get(peerId)!;
      const last = entry.last;
      return {
        peerId,
        peerName: nameMap.get(peerId) || 'User',
        lastMessage: last
          ? {
              content: last.content,
              createdAt: last.createdAt,
              isFromPeer: last.senderId !== userId,
            }
          : null,
        unreadCount: entry.unread,
      };
    });
    list.sort((a, b) => {
      const aTime = a.lastMessage?.createdAt?.getTime() ?? 0;
      const bTime = b.lastMessage?.createdAt?.getTime() ?? 0;
      if (bTime !== aTime) return bTime - aTime;
      return (a.peerName || '').localeCompare(b.peerName || '');
    });
    return list;
  }

  /** Mark messages from peer to userId as read */
  async markAsRead(userId: string, peerId: string): Promise<void> {
    await this.dmRepository
      .createQueryBuilder()
      .update(DirectMessage)
      .set({ readAt: new Date() })
      .where('receiverId = :userId AND senderId = :peerId AND readAt IS NULL', {
        userId,
        peerId,
      })
      .execute();
  }
}
