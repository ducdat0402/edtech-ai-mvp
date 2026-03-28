import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { CommunityStatus } from './entities/community-status.entity';
import {
  CommunityStatusReaction,
  CommunityReactionKind,
} from './entities/community-status-reaction.entity';
import { CommunityStatusComment } from './entities/community-status-comment.entity';
import { FriendsService } from '../friends/friends.service';
import { CreateCommunityStatusDto } from './dto/create-status.dto';
import { CreateCommunityCommentDto } from './dto/create-comment.dto';

@Injectable()
export class CommunityService {
  constructor(
    @InjectRepository(CommunityStatus)
    private readonly statusRepo: Repository<CommunityStatus>,
    @InjectRepository(CommunityStatusReaction)
    private readonly reactionRepo: Repository<CommunityStatusReaction>,
    @InjectRepository(CommunityStatusComment)
    private readonly commentRepo: Repository<CommunityStatusComment>,
    private readonly friendsService: FriendsService,
  ) {}

  private async assertCanSeeAuthor(viewerId: string, authorId: string) {
    if (viewerId === authorId) return;
    const blocked = await this.friendsService.getBlockedPeers(viewerId);
    if (blocked.includes(authorId)) {
      throw new ForbiddenException('Cannot access this content');
    }
  }

  private mapAuthor(user: { id: string; fullName: string | null; avatarUrl: string | null }) {
    return {
      id: user.id,
      fullName: user.fullName || 'Anonymous',
      avatarUrl: user.avatarUrl ?? null,
    };
  }

  async listStatuses(viewerId: string, limit = 20, before?: string) {
    const take = Math.min(Math.max(limit, 1), 50);
    const blocked = await this.friendsService.getBlockedPeers(viewerId);

    const qb = this.statusRepo
      .createQueryBuilder('s')
      .innerJoin('s.user', 'user')
      .addSelect(['user.id', 'user.fullName', 'user.avatarUrl'])
      .orderBy('s.createdAt', 'DESC')
      .addOrderBy('s.id', 'DESC')
      .take(take);

    if (blocked.length) {
      qb.andWhere('s.userId NOT IN (:...blocked)', { blocked });
    }

    if (before) {
      const d = new Date(before);
      if (!Number.isNaN(d.getTime())) {
        qb.andWhere('s.createdAt < :before', { before: d });
      }
    }

    const rows = await qb.getMany();
    if (rows.length === 0) return { items: [], nextCursor: null as string | null };

    const ids = rows.map((r) => r.id);
    const [likeRows, dislikeRows, mine] = await Promise.all([
      this.reactionRepo
        .createQueryBuilder('r')
        .select('r.statusId', 'statusId')
        .addSelect('COUNT(*)', 'cnt')
        .where('r.statusId IN (:...ids)', { ids })
        .andWhere("r.kind = 'like'")
        .groupBy('r.statusId')
        .getRawMany(),
      this.reactionRepo
        .createQueryBuilder('r')
        .select('r.statusId', 'statusId')
        .addSelect('COUNT(*)', 'cnt')
        .where('r.statusId IN (:...ids)', { ids })
        .andWhere("r.kind = 'dislike'")
        .groupBy('r.statusId')
        .getRawMany(),
      this.reactionRepo.find({
        where: { userId: viewerId, statusId: In(ids) },
      }),
    ]);

    const likeMap = new Map(likeRows.map((x) => [x.statusId, parseInt(x.cnt, 10)]));
    const dislikeMap = new Map(dislikeRows.map((x) => [x.statusId, parseInt(x.cnt, 10)]));
    const mineMap = new Map(mine.map((x) => [x.statusId, x.kind]));

    const commentCounts = await this.commentRepo
      .createQueryBuilder('c')
      .select('c.statusId', 'statusId')
      .addSelect('COUNT(*)', 'cnt')
      .where('c.statusId IN (:...ids)', { ids })
      .groupBy('c.statusId')
      .getRawMany();
    const commentMap = new Map(commentCounts.map((x) => [x.statusId, parseInt(x.cnt, 10)]));

    const items = rows.map((s) => ({
      id: s.id,
      content: s.content,
      createdAt: s.createdAt.toISOString(),
      author: this.mapAuthor(s.user),
      likeCount: likeMap.get(s.id) ?? 0,
      dislikeCount: dislikeMap.get(s.id) ?? 0,
      commentCount: commentMap.get(s.id) ?? 0,
      myReaction: mineMap.get(s.id) ?? null,
    }));

    const last = rows[rows.length - 1];
    const nextCursor = rows.length === take ? last.createdAt.toISOString() : null;

    return { items, nextCursor };
  }

  async createStatus(userId: string, dto: CreateCommunityStatusDto) {
    const content = dto.content.trim();
    if (!content) throw new BadRequestException('Content is empty');

    const s = this.statusRepo.create({ userId, content });
    const saved = await this.statusRepo.save(s);
    const full = await this.statusRepo
      .createQueryBuilder('s')
      .innerJoin('s.user', 'user')
      .addSelect(['user.id', 'user.fullName', 'user.avatarUrl'])
      .where('s.id = :id', { id: saved.id })
      .getOne();
    if (!full) throw new NotFoundException();
    return {
      id: full.id,
      content: full.content,
      createdAt: full.createdAt.toISOString(),
      author: this.mapAuthor(full.user),
      likeCount: 0,
      dislikeCount: 0,
      commentCount: 0,
      myReaction: null,
    };
  }

  async deleteStatus(userId: string, statusId: string) {
    const s = await this.statusRepo.findOne({ where: { id: statusId } });
    if (!s) throw new NotFoundException('Status not found');
    if (s.userId !== userId) throw new ForbiddenException('Not your status');
    await this.statusRepo.remove(s);
    return { success: true };
  }

  async setReaction(userId: string, statusId: string, kind: CommunityReactionKind) {
    const status = await this.statusRepo.findOne({ where: { id: statusId } });
    if (!status) throw new NotFoundException('Status not found');
    await this.assertCanSeeAuthor(userId, status.userId);

    const existing = await this.reactionRepo.findOne({
      where: { userId: userId, statusId },
    });

    if (existing && existing.kind === kind) {
      await this.reactionRepo.remove(existing);
    } else if (existing) {
      existing.kind = kind;
      await this.reactionRepo.save(existing);
    } else {
      await this.reactionRepo.save(
        this.reactionRepo.create({ userId, statusId, kind }),
      );
    }

    const [likes, dislikes, mine] = await Promise.all([
      this.reactionRepo.count({ where: { statusId, kind: 'like' } }),
      this.reactionRepo.count({ where: { statusId, kind: 'dislike' } }),
      this.reactionRepo.findOne({ where: { userId, statusId } }),
    ]);

    return {
      likeCount: likes,
      dislikeCount: dislikes,
      myReaction: mine?.kind ?? null,
    };
  }

  async listComments(viewerId: string, statusId: string, limit = 50) {
    const status = await this.statusRepo.findOne({ where: { id: statusId } });
    if (!status) throw new NotFoundException('Status not found');
    await this.assertCanSeeAuthor(viewerId, status.userId);

    const take = Math.min(Math.max(limit, 1), 100);
    const comments = await this.commentRepo
      .createQueryBuilder('c')
      .innerJoin('c.user', 'user')
      .addSelect(['user.id', 'user.fullName', 'user.avatarUrl'])
      .where('c.statusId = :statusId', { statusId })
      .orderBy('c.createdAt', 'ASC')
      .take(take)
      .getMany();

    return comments.map((c) => ({
      id: c.id,
      content: c.content,
      createdAt: c.createdAt.toISOString(),
      author: this.mapAuthor(c.user),
    }));
  }

  async addComment(userId: string, statusId: string, dto: CreateCommunityCommentDto) {
    const content = dto.content.trim();
    if (!content) throw new BadRequestException('Comment is empty');

    const status = await this.statusRepo.findOne({ where: { id: statusId } });
    if (!status) throw new NotFoundException('Status not found');
    await this.assertCanSeeAuthor(userId, status.userId);

    const c = this.commentRepo.create({ userId, statusId, content });
    const saved = await this.commentRepo.save(c);
    const full = await this.commentRepo
      .createQueryBuilder('c')
      .innerJoin('c.user', 'user')
      .addSelect(['user.id', 'user.fullName', 'user.avatarUrl'])
      .where('c.id = :id', { id: saved.id })
      .getOne();
    if (!full) throw new NotFoundException();

    return {
      id: full.id,
      content: full.content,
      createdAt: full.createdAt.toISOString(),
      author: this.mapAuthor(full.user),
    };
  }
}
