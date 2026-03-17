import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In, Not, MoreThan } from 'typeorm';
import { Friendship, FriendshipStatus } from './entities/friendship.entity';
import { UserBlock } from './entities/user-block.entity';
import { FriendActivity, FriendActivityType } from './entities/friend-activity.entity';
import { User } from '../users/entities/user.entity';
import { UserCurrency } from '../user-currency/entities/user-currency.entity';
import { UserProgress } from '../user-progress/entities/user-progress.entity';

@Injectable()
export class FriendsService {
  constructor(
    @InjectRepository(Friendship)
    private friendshipRepository: Repository<Friendship>,
    @InjectRepository(UserBlock)
    private blockRepository: Repository<UserBlock>,
    @InjectRepository(FriendActivity)
    private activityRepository: Repository<FriendActivity>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(UserCurrency)
    private currencyRepository: Repository<UserCurrency>,
    @InjectRepository(UserProgress)
    private progressRepository: Repository<UserProgress>,
  ) {}

  private getFriendLimit(level: number): number {
    if (level >= 30) return 200;
    if (level >= 20) return 150;
    if (level >= 10) return 100;
    return 50;
  }

  private async getAcceptedFriendCount(userId: string): Promise<number> {
    return this.friendshipRepository.count({
      where: [
        { requesterId: userId, status: FriendshipStatus.ACCEPTED },
        { addresseeId: userId, status: FriendshipStatus.ACCEPTED },
      ],
    });
  }

  private async isBlocked(userA: string, userB: string): Promise<boolean> {
    const block = await this.blockRepository.findOne({
      where: [
        { blockerId: userA, blockedId: userB },
        { blockerId: userB, blockedId: userA },
      ],
    });
    return !!block;
  }

  private async getBlockedUserIds(userId: string): Promise<string[]> {
    const blocks = await this.blockRepository.find({
      where: [{ blockerId: userId }, { blockedId: userId }],
    });
    const ids = new Set<string>();
    for (const b of blocks) {
      ids.add(b.blockerId === userId ? b.blockedId : b.blockerId);
    }
    return Array.from(ids);
  }

  private async getAcceptedFriendIds(userId: string): Promise<string[]> {
    const friendships = await this.friendshipRepository.find({
      where: [
        { requesterId: userId, status: FriendshipStatus.ACCEPTED },
        { addresseeId: userId, status: FriendshipStatus.ACCEPTED },
      ],
    });
    return friendships.map((f) =>
      f.requesterId === userId ? f.addresseeId : f.requesterId,
    );
  }

  // ─── Friend Requests ───────────────────────────────────────

  async sendRequest(userId: string, targetUserId: string): Promise<Friendship> {
    if (userId === targetUserId) {
      throw new BadRequestException('Cannot send request to yourself');
    }

    const target = await this.userRepository.findOne({ where: { id: targetUserId } });
    if (!target) throw new NotFoundException('User not found');

    if (await this.isBlocked(userId, targetUserId)) {
      throw new ForbiddenException('Cannot send request to this user');
    }

    const existing = await this.friendshipRepository.findOne({
      where: [
        { requesterId: userId, addresseeId: targetUserId },
        { requesterId: targetUserId, addresseeId: userId },
      ],
    });

    if (existing) {
      if (existing.status === FriendshipStatus.ACCEPTED) {
        throw new BadRequestException('Already friends');
      }
      if (existing.status === FriendshipStatus.PENDING) {
        if (existing.addresseeId === userId) {
          existing.status = FriendshipStatus.ACCEPTED;
          return this.friendshipRepository.save(existing);
        }
        throw new BadRequestException('Request already sent');
      }
      if (
        existing.status === FriendshipStatus.REJECTED ||
        existing.status === FriendshipStatus.CANCELLED
      ) {
        existing.requesterId = userId;
        existing.addresseeId = targetUserId;
        existing.status = FriendshipStatus.PENDING;
        return this.friendshipRepository.save(existing);
      }
    }

    const currency = await this.currencyRepository.findOne({ where: { userId } });
    const level = currency?.level || 1;
    const limit = this.getFriendLimit(level);
    const count = await this.getAcceptedFriendCount(userId);
    if (count >= limit) {
      throw new BadRequestException(
        `Friend limit reached (${limit}). Level up to increase your limit!`,
      );
    }

    const friendship = this.friendshipRepository.create({
      requesterId: userId,
      addresseeId: targetUserId,
      status: FriendshipStatus.PENDING,
    });
    return this.friendshipRepository.save(friendship);
  }

  async acceptRequest(userId: string, friendshipId: string): Promise<Friendship> {
    const friendship = await this.friendshipRepository.findOne({
      where: { id: friendshipId, addresseeId: userId, status: FriendshipStatus.PENDING },
    });
    if (!friendship) throw new NotFoundException('Pending request not found');

    const currency = await this.currencyRepository.findOne({ where: { userId } });
    const level = currency?.level || 1;
    const limit = this.getFriendLimit(level);
    const count = await this.getAcceptedFriendCount(userId);
    if (count >= limit) {
      throw new BadRequestException(
        `Friend limit reached (${limit}). Level up to increase your limit!`,
      );
    }

    friendship.status = FriendshipStatus.ACCEPTED;
    return this.friendshipRepository.save(friendship);
  }

  async rejectRequest(userId: string, friendshipId: string): Promise<Friendship> {
    const friendship = await this.friendshipRepository.findOne({
      where: { id: friendshipId, addresseeId: userId, status: FriendshipStatus.PENDING },
    });
    if (!friendship) throw new NotFoundException('Pending request not found');

    friendship.status = FriendshipStatus.REJECTED;
    return this.friendshipRepository.save(friendship);
  }

  async cancelRequest(userId: string, friendshipId: string): Promise<Friendship> {
    const friendship = await this.friendshipRepository.findOne({
      where: { id: friendshipId, requesterId: userId, status: FriendshipStatus.PENDING },
    });
    if (!friendship) throw new NotFoundException('Pending request not found');

    friendship.status = FriendshipStatus.CANCELLED;
    return this.friendshipRepository.save(friendship);
  }

  // ─── Friend Management ─────────────────────────────────────

  async getFriends(userId: string): Promise<any[]> {
    const friendships = await this.friendshipRepository.find({
      where: [
        { requesterId: userId, status: FriendshipStatus.ACCEPTED },
        { addresseeId: userId, status: FriendshipStatus.ACCEPTED },
      ],
      relations: ['requester', 'addressee'],
      order: { updatedAt: 'DESC' },
    });

    const friendIds = friendships.map((f) =>
      f.requesterId === userId ? f.addresseeId : f.requesterId,
    );

    const currencies = friendIds.length
      ? await this.currencyRepository.find({ where: { userId: In(friendIds) } })
      : [];
    const currencyMap = new Map(currencies.map((c) => [c.userId, c]));

    return friendships.map((f) => {
      const friend = f.requesterId === userId ? f.addressee : f.requester;
      const curr = currencyMap.get(friend.id);
      return {
        friendshipId: f.id,
        id: friend.id,
        fullName: friend.fullName,
        email: friend.email,
        level: curr?.level || 1,
        currentStreak: curr?.currentStreak || 0,
        totalXP: curr?.xp || 0,
        friendsSince: f.updatedAt,
      };
    });
  }

  async unfriend(userId: string, friendshipId: string): Promise<void> {
    const friendship = await this.friendshipRepository.findOne({
      where: [
        { id: friendshipId, requesterId: userId, status: FriendshipStatus.ACCEPTED },
        { id: friendshipId, addresseeId: userId, status: FriendshipStatus.ACCEPTED },
      ],
    });
    if (!friendship) throw new NotFoundException('Friendship not found');

    await this.friendshipRepository.remove(friendship);
  }

  async blockUser(userId: string, targetUserId: string): Promise<void> {
    if (userId === targetUserId) {
      throw new BadRequestException('Cannot block yourself');
    }

    const target = await this.userRepository.findOne({ where: { id: targetUserId } });
    if (!target) throw new NotFoundException('User not found');

    const existing = await this.blockRepository.findOne({
      where: { blockerId: userId, blockedId: targetUserId },
    });
    if (existing) return;

    const friendships = await this.friendshipRepository.find({
      where: [
        { requesterId: userId, addresseeId: targetUserId },
        { requesterId: targetUserId, addresseeId: userId },
      ],
    });
    if (friendships.length) {
      await this.friendshipRepository.remove(friendships);
    }

    const block = this.blockRepository.create({
      blockerId: userId,
      blockedId: targetUserId,
    });
    await this.blockRepository.save(block);
  }

  async unblockUser(userId: string, targetUserId: string): Promise<void> {
    const block = await this.blockRepository.findOne({
      where: { blockerId: userId, blockedId: targetUserId },
    });
    if (!block) throw new NotFoundException('Block not found');

    await this.blockRepository.remove(block);
  }

  // ─── Requests ──────────────────────────────────────────────

  async getRequests(userId: string): Promise<{ received: any[]; sent: any[] }> {
    const [received, sent] = await Promise.all([
      this.friendshipRepository.find({
        where: { addresseeId: userId, status: FriendshipStatus.PENDING },
        relations: ['requester'],
        order: { createdAt: 'DESC' },
      }),
      this.friendshipRepository.find({
        where: { requesterId: userId, status: FriendshipStatus.PENDING },
        relations: ['addressee'],
        order: { createdAt: 'DESC' },
      }),
    ]);

    const allIds = [
      ...received.map((r) => r.requesterId),
      ...sent.map((s) => s.addresseeId),
    ];
    const currencies = allIds.length
      ? await this.currencyRepository.find({ where: { userId: In(allIds) } })
      : [];
    const currencyMap = new Map(currencies.map((c) => [c.userId, c]));

    return {
      received: received.map((r) => {
        const curr = currencyMap.get(r.requesterId);
        return {
          friendshipId: r.id,
          id: r.requester.id,
          fullName: r.requester.fullName,
          email: r.requester.email,
          level: curr?.level || 1,
          totalXP: curr?.xp || 0,
          sentAt: r.createdAt,
        };
      }),
      sent: sent.map((s) => {
        const curr = currencyMap.get(s.addresseeId);
        return {
          friendshipId: s.id,
          id: s.addressee.id,
          fullName: s.addressee.fullName,
          email: s.addressee.email,
          level: curr?.level || 1,
          totalXP: curr?.xp || 0,
          sentAt: s.createdAt,
        };
      }),
    };
  }

  async getPendingCount(userId: string): Promise<number> {
    return this.friendshipRepository.count({
      where: { addresseeId: userId, status: FriendshipStatus.PENDING },
    });
  }

  // ─── Discovery ─────────────────────────────────────────────

  async searchUsers(
    userId: string,
    query: string,
    limit = 20,
  ): Promise<any[]> {
    if (!query || query.trim().length < 2) return [];

    const blockedIds = await this.getBlockedUserIds(userId);
    const excludeIds = [userId, ...blockedIds];

    const qb = this.userRepository
      .createQueryBuilder('user')
      .where('user.id NOT IN (:...excludeIds)', { excludeIds })
      .andWhere('(LOWER(user.fullName) LIKE :q OR LOWER(user.email) LIKE :q)', {
        q: `%${query.toLowerCase().trim()}%`,
      })
      .orderBy('user.fullName', 'ASC')
      .take(limit);

    const users = await qb.getMany();
    const userIds = users.map((u) => u.id);

    const currencies = userIds.length
      ? await this.currencyRepository.find({ where: { userId: In(userIds) } })
      : [];
    const currencyMap = new Map(currencies.map((c) => [c.userId, c]));

    const friendships = userIds.length
      ? await this.friendshipRepository.find({
          where: [
            { requesterId: userId, addresseeId: In(userIds) },
            { requesterId: In(userIds), addresseeId: userId },
          ],
        })
      : [];

    const statusMap = new Map<string, { status: FriendshipStatus; friendshipId: string; isRequester: boolean }>();
    for (const f of friendships) {
      const otherId = f.requesterId === userId ? f.addresseeId : f.requesterId;
      statusMap.set(otherId, {
        status: f.status,
        friendshipId: f.id,
        isRequester: f.requesterId === userId,
      });
    }

    return users.map((u) => {
      const curr = currencyMap.get(u.id);
      const rel = statusMap.get(u.id);
      return {
        id: u.id,
        fullName: u.fullName,
        email: u.email,
        level: curr?.level || 1,
        totalXP: curr?.xp || 0,
        friendshipStatus: rel?.status || null,
        friendshipId: rel?.friendshipId || null,
        isRequester: rel?.isRequester ?? null,
      };
    });
  }

  async getSuggestions(userId: string, limit = 20): Promise<any[]> {
    const blockedIds = await this.getBlockedUserIds(userId);
    const friendIds = await this.getAcceptedFriendIds(userId);

    const recentRejected = await this.friendshipRepository.find({
      where: [
        {
          requesterId: userId,
          status: FriendshipStatus.REJECTED,
          updatedAt: MoreThan(new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)),
        },
        {
          addresseeId: userId,
          status: FriendshipStatus.REJECTED,
          updatedAt: MoreThan(new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)),
        },
      ],
    });
    const rejectedIds = recentRejected.map((r) =>
      r.requesterId === userId ? r.addresseeId : r.requesterId,
    );

    const pendingFriendships = await this.friendshipRepository.find({
      where: [
        { requesterId: userId, status: FriendshipStatus.PENDING },
        { addresseeId: userId, status: FriendshipStatus.PENDING },
      ],
    });
    const pendingIds = pendingFriendships.map((p) =>
      p.requesterId === userId ? p.addresseeId : p.requesterId,
    );

    const excludeIds = new Set([
      userId,
      ...blockedIds,
      ...friendIds,
      ...rejectedIds,
      ...pendingIds,
    ]);

    const myCurrency = await this.currencyRepository.findOne({ where: { userId } });
    const myLevel = myCurrency?.level || 1;

    const myNodeIds = (
      await this.progressRepository.find({
        where: { userId, isCompleted: true },
        select: ['nodeId'],
      })
    ).map((p) => p.nodeId);

    // Scored candidates: mutual friends, same nodes, similar level
    const allUsers = await this.userRepository.find({
      select: ['id', 'fullName', 'email'],
    });

    const candidateIds = allUsers
      .filter((u) => !excludeIds.has(u.id))
      .map((u) => u.id);

    if (!candidateIds.length) return [];

    const currencies = await this.currencyRepository.find({
      where: { userId: In(candidateIds) },
    });
    const currencyMap = new Map(currencies.map((c) => [c.userId, c]));

    // Mutual friends scoring
    const mutualCounts = new Map<string, number>();
    if (friendIds.length) {
      for (const candidateId of candidateIds) {
        const mutual = await this.friendshipRepository
          .createQueryBuilder('f')
          .where('f.status = :status', { status: FriendshipStatus.ACCEPTED })
          .andWhere(
            '((f.requesterId = :cid AND f.addresseeId IN (:...fids)) OR ' +
              '(f.addresseeId = :cid AND f.requesterId IN (:...fids)))',
            { cid: candidateId, fids: friendIds },
          )
          .getCount();
        if (mutual > 0) mutualCounts.set(candidateId, mutual);
      }
    }

    // Shared completed nodes scoring
    const sharedNodeCounts = new Map<string, number>();
    if (myNodeIds.length) {
      const candidateProgresses = await this.progressRepository.find({
        where: {
          userId: In(candidateIds),
          isCompleted: true,
          nodeId: In(myNodeIds),
        },
        select: ['userId'],
      });
      for (const p of candidateProgresses) {
        sharedNodeCounts.set(p.userId, (sharedNodeCounts.get(p.userId) || 0) + 1);
      }
    }

    type Scored = { id: string; score: number };
    const scored: Scored[] = candidateIds.map((id) => {
      const mutualScore = (mutualCounts.get(id) || 0) * 10;
      const nodeScore = (sharedNodeCounts.get(id) || 0) * 3;
      const candLevel = currencyMap.get(id)?.level || 1;
      const levelDiff = Math.abs(candLevel - myLevel);
      const levelScore = Math.max(0, 5 - levelDiff);
      return { id, score: mutualScore + nodeScore + levelScore };
    });

    scored.sort((a, b) => b.score - a.score);
    const topIds = scored.slice(0, limit).map((s) => s.id);

    const userMap = new Map(allUsers.map((u) => [u.id, u]));

    return topIds.map((id) => {
      const u = userMap.get(id)!;
      const curr = currencyMap.get(id);
      const mc = mutualCounts.get(id) || 0;
      return {
        id: u.id,
        fullName: u.fullName,
        email: u.email,
        level: curr?.level || 1,
        totalXP: curr?.xp || 0,
        mutualFriends: mc,
      };
    });
  }

  // ─── Activity Feed ─────────────────────────────────────────

  async logActivity(
    userId: string,
    type: FriendActivityType,
    metadata: Record<string, any> = {},
  ): Promise<void> {
    try {
      const activity = this.activityRepository.create({
        userId,
        type,
        metadata,
      });
      await this.activityRepository.save(activity);
    } catch (error) {
      console.error('Error logging friend activity:', error);
    }
  }

  async getActivities(
    userId: string,
    page = 1,
    limit = 20,
  ): Promise<{ activities: any[]; total: number }> {
    const friendIds = await this.getAcceptedFriendIds(userId);
    if (!friendIds.length) return { activities: [], total: 0 };

    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const [activities, total] = await this.activityRepository
      .createQueryBuilder('a')
      .leftJoinAndSelect('a.user', 'user')
      .where('a.userId IN (:...friendIds)', { friendIds })
      .andWhere('a.createdAt >= :since', { since: sevenDaysAgo })
      .orderBy('a.createdAt', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return {
      activities: activities.map((a) => ({
        id: a.id,
        type: a.type,
        metadata: a.metadata,
        createdAt: a.createdAt,
        user: {
          id: a.user.id,
          fullName: a.user.fullName,
          email: a.user.email,
        },
      })),
      total,
    };
  }
}
