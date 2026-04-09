import {
  Injectable,
  BadRequestException,
  NotFoundException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, Repository } from 'typeorm';
import { UnlockTransaction } from './entities/unlock-transaction.entity';
import { UserUnlock } from './entities/user-unlock.entity';
import { UserOpenedNode } from './entities/user-opened-node.entity';
import { UserCurrencyService } from '../user-currency/user-currency.service';
import { SubjectsService } from '../subjects/subjects.service';
import { DomainsService } from '../domains/domains.service';
import { TopicsService } from '../topics/topics.service';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { Subject } from '../subjects/entities/subject.entity';
import {
  FREE_LESSONS_PER_DAY,
  DIAMOND_PER_LESSON_OPEN,
} from './lesson-access.constants';

// Giá theo bài (mở topic/domain/subject = tổng từ số bài × đơn giá này)
const DIAMOND_PER_LESSON = DIAMOND_PER_LESSON_OPEN;
const SUBJECT_DISCOUNT = 0.70; // 30% off
const DOMAIN_DISCOUNT = 0.85;  // 15% off
const TOPIC_DISCOUNT = 1.0;    // no discount

@Injectable()
export class UnlockTransactionsService {
  constructor(
    @InjectRepository(UnlockTransaction)
    private transactionRepository: Repository<UnlockTransaction>,
    @InjectRepository(UserUnlock)
    private unlockRepository: Repository<UserUnlock>,
    @InjectRepository(LearningNode)
    private nodeRepository: Repository<LearningNode>,
    @InjectRepository(UserOpenedNode)
    private openedNodeRepository: Repository<UserOpenedNode>,
    private dataSource: DataSource,
    private currencyService: UserCurrencyService,
    @Inject(forwardRef(() => SubjectsService))
    private subjectsService: SubjectsService,
    @Inject(forwardRef(() => DomainsService))
    private domainsService: DomainsService,
    @Inject(forwardRef(() => TopicsService))
    private topicsService: TopicsService,
  ) {}

  // ═══════════════════════════════════════════════════════
  //  PRICING
  // ═══════════════════════════════════════════════════════

  /**
   * Get full pricing info for a subject (all tiers)
   * Prices are adjusted: already-unlocked lessons are deducted from the total
   */
  async getUnlockPricing(subjectId: string, userId?: string) {
    const subject = await this.subjectsService.findById(subjectId);
    if (!subject) {
      throw new NotFoundException('Không tìm thấy môn học');
    }

    const domains = await this.domainsService.findBySubject(subjectId);

    // Get user's existing unlocks
    const userUnlocks = userId
      ? await this.unlockRepository.find({ where: { userId } })
      : [];

    // Check if entire subject is unlocked
    const subjectUnlocked = userUnlocks.some(
      (u) => u.unlockLevel === 'subject' && u.subjectId === subjectId,
    );

    // Count total lessons in subject
    const allNodes = await this.nodeRepository.find({
      where: { subjectId },
    });
    const totalLessons = allNodes.length;

    // Build sets of unlocked domain/topic IDs for price deduction
    const unlockedDomainIds = new Set(
      userUnlocks
        .filter((u) => u.unlockLevel === 'domain' && u.subjectId === subjectId)
        .map((u) => u.domainId),
    );
    const unlockedTopicIds = new Set(
      userUnlocks
        .filter((u) => u.unlockLevel === 'topic' && u.subjectId === subjectId)
        .map((u) => u.topicId),
    );

    // Domain-level pricing
    const domainPricing = [];
    let totalIfBuyDomains = 0;
    let totalIfBuyTopics = 0;
    let totalAlreadyUnlockedLessons = 0;

    for (const domain of domains) {
      const domainNodes = allNodes.filter((n) => n.domainId === domain.id);
      const domainLessons = domainNodes.length;

      const domainUnlocked =
        subjectUnlocked ||
        unlockedDomainIds.has(domain.id);

      // Topic-level pricing
      const topics = await this.topicsService.findByDomain(domain.id);
      const topicPricing = [];
      let domainAlreadyUnlockedLessons = 0;

      for (const topic of topics) {
        const topicNodes = domainNodes.filter((n) => n.topicId === topic.id);
        const topicLessons = topicNodes.length;

        const topicUnlocked =
          subjectUnlocked ||
          domainUnlocked ||
          unlockedTopicIds.has(topic.id);

        const topicPrice = topicUnlocked ? 0 : topicLessons * DIAMOND_PER_LESSON;
        totalIfBuyTopics += topicLessons * DIAMOND_PER_LESSON; // full price reference

        if (topicUnlocked) {
          domainAlreadyUnlockedLessons += topicLessons;
        }

        topicPricing.push({
          topicId: topic.id,
          name: topic.name,
          lessonsCount: topicLessons,
          price: topicPrice,
          originalPrice: topicLessons * DIAMOND_PER_LESSON,
          discountPercent: 0,
          isUnlocked: topicUnlocked,
        });
      }

      totalAlreadyUnlockedLessons += domainAlreadyUnlockedLessons;

      // Domain price: only charge for remaining (non-unlocked) lessons
      const remainingDomainLessons = domainUnlocked ? 0 : domainLessons - domainAlreadyUnlockedLessons;
      const domainPrice = domainUnlocked ? 0 : Math.ceil(remainingDomainLessons * DIAMOND_PER_LESSON * DOMAIN_DISCOUNT);
      totalIfBuyDomains += domainUnlocked ? 0 : domainPrice;

      domainPricing.push({
        domainId: domain.id,
        name: domain.name,
        icon: domain.metadata?.icon || '📖',
        lessonsCount: domainLessons,
        remainingLessons: remainingDomainLessons,
        price: domainPrice,
        originalPrice: Math.ceil(domainLessons * DIAMOND_PER_LESSON * DOMAIN_DISCOUNT),
        discountPercent: 15,
        isUnlocked: domainUnlocked,
        topics: topicPricing,
      });
    }

    // Subject price: only charge for remaining lessons
    const remainingSubjectLessons = subjectUnlocked ? 0 : totalLessons - totalAlreadyUnlockedLessons;
    const subjectPrice = subjectUnlocked ? 0 : Math.ceil(remainingSubjectLessons * DIAMOND_PER_LESSON * SUBJECT_DISCOUNT);

    // User balance
    let userBalance = 0;
    if (userId) {
      const currency = await this.currencyService.getCurrency(userId);
      userBalance = currency.coins;
    }

    return {
      subjectId,
      subjectName: subject.name,
      totalLessons,
      remainingLessons: remainingSubjectLessons,
      alreadyUnlockedLessons: totalAlreadyUnlockedLessons,
      isSubjectUnlocked: subjectUnlocked,
      userBalance,
      // Subject-level
      subject: {
        price: subjectPrice,
        originalPrice: Math.ceil(totalLessons * DIAMOND_PER_LESSON * SUBJECT_DISCOUNT),
        discountPercent: 30,
        lessonsCount: totalLessons,
        remainingLessons: remainingSubjectLessons,
        savingsVsTopics: totalIfBuyTopics - subjectPrice,
        isUnlocked: subjectUnlocked,
      },
      // Domain-level
      domains: domainPricing,
      totalIfBuyDomains,
      totalIfBuyTopics,
    };
  }

  // ═══════════════════════════════════════════════════════
  //  UNLOCK ACTIONS
  // ═══════════════════════════════════════════════════════

  /**
   * Unlock entire subject (only charges for remaining non-unlocked lessons)
   */
  async unlockSubject(userId: string, subjectId: string) {
    // Check if already unlocked
    const existing = await this.unlockRepository.findOne({
      where: { userId, unlockLevel: 'subject', subjectId },
    });
    if (existing) {
      throw new BadRequestException('Bạn đã mở khóa môn học này rồi');
    }

    const subject = await this.subjectsService.findById(subjectId);
    if (!subject) {
      throw new NotFoundException('Không tìm thấy môn học');
    }

    const allNodes = await this.nodeRepository.find({ where: { subjectId } });
    const totalLessons = allNodes.length;

    // Calculate already-unlocked lessons to deduct from price
    const existingUnlocks = await this.unlockRepository.find({
      where: { userId, subjectId },
    });
    const unlockedDomainIds = new Set(
      existingUnlocks.filter((u) => u.unlockLevel === 'domain').map((u) => u.domainId),
    );
    const unlockedTopicIds = new Set(
      existingUnlocks.filter((u) => u.unlockLevel === 'topic').map((u) => u.topicId),
    );

    let alreadyUnlockedCount = 0;
    for (const node of allNodes) {
      if (
        (node.domainId && unlockedDomainIds.has(node.domainId)) ||
        (node.topicId && unlockedTopicIds.has(node.topicId))
      ) {
        alreadyUnlockedCount++;
      }
    }

    const remainingLessons = totalLessons - alreadyUnlockedCount;
    const price = Math.ceil(remainingLessons * DIAMOND_PER_LESSON * SUBJECT_DISCOUNT);

    if (price > 0) {
      try {
        await this.currencyService.deductDiamonds(userId, price);
      } catch {
        const currency = await this.currencyService.getCurrency(userId);
        throw new BadRequestException(
          `Không đủ kim cương. Cần ${price} 💎, bạn có ${currency.diamonds ?? 0} 💎.`,
        );
      }
    }

    const unlock = this.unlockRepository.create({
      userId,
      unlockLevel: 'subject',
      subjectId,
      diamondsCost: price,
      lessonsCount: totalLessons,
      discountPercent: 30,
    });

    const saved = await this.unlockRepository.save(unlock);

    return {
      message: `Đã mở khóa toàn bộ môn ${subject.name} (${totalLessons} bài)`,
      unlock: saved,
      diamondsSpent: price,
    };
  }

  /**
   * Unlock a domain (chapter) - only charges for remaining non-unlocked lessons
   */
  async unlockDomain(userId: string, domainId: string) {
    const domain = await this.domainsService.findById(domainId);
    if (!domain) {
      throw new NotFoundException('Không tìm thấy chương học');
    }

    // Check if subject already unlocked
    const subjectUnlocked = await this.unlockRepository.findOne({
      where: { userId, unlockLevel: 'subject', subjectId: domain.subjectId },
    });
    if (subjectUnlocked) {
      throw new BadRequestException('Bạn đã mở khóa toàn bộ môn học này rồi');
    }

    // Check if domain already unlocked
    const existing = await this.unlockRepository.findOne({
      where: { userId, unlockLevel: 'domain', domainId },
    });
    if (existing) {
      throw new BadRequestException('Bạn đã mở khóa chương này rồi');
    }

    const domainNodes = await this.nodeRepository.find({ where: { domainId } });
    const lessonsCount = domainNodes.length;

    // Calculate already-unlocked topics in this domain
    const existingTopicUnlocks = await this.unlockRepository.find({
      where: { userId, unlockLevel: 'topic' as const, domainId },
    });
    const unlockedTopicIds = new Set(existingTopicUnlocks.map((u) => u.topicId));

    let alreadyUnlockedCount = 0;
    for (const node of domainNodes) {
      if (node.topicId && unlockedTopicIds.has(node.topicId)) {
        alreadyUnlockedCount++;
      }
    }

    const remainingLessons = lessonsCount - alreadyUnlockedCount;
    const price = Math.ceil(remainingLessons * DIAMOND_PER_LESSON * DOMAIN_DISCOUNT);

    if (price > 0) {
      try {
        await this.currencyService.deductDiamonds(userId, price);
      } catch {
        const currency = await this.currencyService.getCurrency(userId);
        throw new BadRequestException(
          `Không đủ kim cương. Cần ${price} 💎, bạn có ${currency.diamonds ?? 0} 💎.`,
        );
      }
    }

    const unlock = this.unlockRepository.create({
      userId,
      unlockLevel: 'domain',
      subjectId: domain.subjectId,
      domainId,
      diamondsCost: price,
      lessonsCount,
      discountPercent: 15,
    });

    const saved = await this.unlockRepository.save(unlock);

    return {
      message: `Đã mở khóa chương "${domain.name}" (${lessonsCount} bài)`,
      unlock: saved,
      diamondsSpent: price,
    };
  }

  /**
   * Unlock a topic
   */
  async unlockTopic(userId: string, topicId: string) {
    const topic = await this.topicsService.findById(topicId);
    if (!topic) {
      throw new NotFoundException('Không tìm thấy chủ đề');
    }

    const domain = await this.domainsService.findById(topic.domainId);

    // Check if subject already unlocked
    if (domain) {
      const subjectUnlocked = await this.unlockRepository.findOne({
        where: { userId, unlockLevel: 'subject', subjectId: domain.subjectId },
      });
      if (subjectUnlocked) {
        throw new BadRequestException('Bạn đã mở khóa toàn bộ môn học này rồi');
      }
    }

    // Check if domain already unlocked
    const domainUnlocked = await this.unlockRepository.findOne({
      where: { userId, unlockLevel: 'domain', domainId: topic.domainId },
    });
    if (domainUnlocked) {
      throw new BadRequestException('Bạn đã mở khóa toàn bộ chương này rồi');
    }

    // Check if topic already unlocked
    const existing = await this.unlockRepository.findOne({
      where: { userId, unlockLevel: 'topic', topicId },
    });
    if (existing) {
      throw new BadRequestException('Bạn đã mở khóa chủ đề này rồi');
    }

    const topicNodes = await this.nodeRepository.find({ where: { topicId } });
    const lessonsCount = topicNodes.length;
    const price = lessonsCount * DIAMOND_PER_LESSON; // no discount

    try {
      await this.currencyService.deductDiamonds(userId, price);
    } catch {
      const currency = await this.currencyService.getCurrency(userId);
      throw new BadRequestException(
        `Không đủ kim cương. Cần ${price} 💎, bạn có ${currency.diamonds ?? 0} 💎.`,
      );
    }

    const unlock = this.unlockRepository.create({
      userId,
      unlockLevel: 'topic',
      subjectId: domain?.subjectId || null,
      domainId: topic.domainId,
      topicId,
      diamondsCost: price,
      lessonsCount,
      discountPercent: 0,
    });

    const saved = await this.unlockRepository.save(unlock);

    return {
      message: `Đã mở khóa chủ đề "${topic.name}" (${lessonsCount} bài)`,
      unlock: saved,
      diamondsSpent: price,
    };
  }

  // ═══════════════════════════════════════════════════════
  //  DAILY FREE LESSONS + PER-NODE OPEN
  // ═══════════════════════════════════════════════════════

  /** Ngày theo lịch Việt Nam (YYYY-MM-DD) — dùng cho quota 2 bài/ngày. */
  calendarDateVN(d: Date = new Date()): string {
    return d.toLocaleDateString('en-CA', { timeZone: 'Asia/Ho_Chi_Minh' });
  }

  /**
   * Số suất miễn phí (2 bài/ngày) đã dùng — chỉ đếm bài community/expert mở bằng suất ngày.
   * Không đếm: môn private (cũng ghi diamondsPaid=0), mở bằng xu (diamondsPaid=0 nhưng coinsPaid>0).
   */
  private async countDailyFreeSlotsUsed(
    userId: string,
    today: string,
    openedRepo: Repository<UserOpenedNode>,
  ): Promise<number> {
    return openedRepo
      .createQueryBuilder('o')
      .innerJoin(LearningNode, 'n', 'n.id = o.nodeId')
      .innerJoin(Subject, 's', 's.id = n.subjectId')
      .where('o.userId = :userId', { userId })
      .andWhere('o.diamondsPaid = 0')
      .andWhere('o.coinsPaid = 0')
      .andWhere('s.subjectType != :priv', { priv: 'private' })
      .andWhere(
        `to_char(timezone('Asia/Ho_Chi_Minh', o.openedAt), 'YYYY-MM-DD') = :d`,
        { d: today },
      )
      .getCount();
  }

  /** Số bài đã mở bằng suất miễn phí trong ngày (VN). */
  async countFreeLessonOpensToday(userId: string): Promise<number> {
    const today = this.calendarDateVN();
    return this.countDailyFreeSlotsUsed(
      userId,
      today,
      this.openedNodeRepository,
    );
  }

  private async hasTierUnlockForNode(
    userId: string,
    node: Pick<LearningNode, 'subjectId' | 'domainId' | 'topicId'>,
  ): Promise<boolean> {
    const unlock = await this.unlockRepository
      .createQueryBuilder('u')
      .where('u.userId = :userId', { userId })
      .andWhere(
        '(u.unlockLevel = :subject AND u.subjectId = :subjectId) OR ' +
          '(u.unlockLevel = :domain AND u.domainId = :domainId) OR ' +
          '(u.unlockLevel = :topic AND u.topicId = :topicId)',
        {
          subject: 'subject',
          domain: 'domain',
          topic: 'topic',
          subjectId: node.subjectId || '',
          domainId: node.domainId || '',
          topicId: node.topicId || '',
        },
      )
      .limit(1)
      .getOne();
    return !!unlock;
  }

  /**
   * Mở một bài học: tối đa 2 bài/ngày (toàn hệ thống) miễn phí, sau đó 50 💎/bài.
   * Không kiểm tra prerequisites — học tự do: user có thể mở bất kỳ bài nào (miễn còn suất / đủ 💎).
   */
  async openLearningNode(
    userId: string,
    nodeId: string,
    preferredCurrency?: 'coins' | 'diamonds',
  ) {
    const node = await this.nodeRepository.findOne({
      where: { id: nodeId },
      select: ['id', 'subjectId', 'domainId', 'topicId'],
    });
    if (!node?.subjectId) {
      throw new NotFoundException('Không tìm thấy bài học');
    }
    const subject = await this.dataSource.getRepository(Subject).findOne({
      where: { id: node.subjectId },
      select: ['id', 'subjectType', 'ownerUserId'],
    });
    if (!subject) {
      throw new NotFoundException('Không tìm thấy môn học');
    }
    if (subject.subjectType === 'private') {
      if (subject.ownerUserId !== userId) {
        throw new BadRequestException('Bạn không có quyền truy cập môn private này');
      }
      await this.openedNodeRepository
        .createQueryBuilder()
        .insert()
        .values({ userId, nodeId, diamondsPaid: 0, coinsPaid: 0 })
        .orIgnore()
        .execute();
      return {
        success: true,
        usedFreeDailySlot: false,
        freePrivateLesson: true,
        message: 'Bài học private của bạn được mở miễn phí',
      };
    }

    const existingOpen = await this.openedNodeRepository.findOne({
      where: { userId, nodeId },
    });
    if (existingOpen) {
      return {
        success: true,
        alreadyUnlocked: true,
        diamondsPaid: existingOpen.diamondsPaid,
        message: 'Bài học đã được mở trước đó',
      };
    }

    if (await this.hasTierUnlockForNode(userId, node)) {
      return {
        success: true,
        viaBulkUnlock: true,
        message: 'Bài nằm trong phạm vi đã mở khóa (môn/chương/chủ đề)',
      };
    }

    await this.currencyService.getOrCreate(userId);

    return this.dataSource.transaction(async (manager) => {
      const openedRepo = manager.getRepository(UserOpenedNode);
      const dup = await openedRepo.findOne({ where: { userId, nodeId } });
      if (dup) {
        return {
          success: true,
          alreadyUnlocked: true,
          diamondsPaid: dup.diamondsPaid,
        };
      }

      const today = this.calendarDateVN();
      const freeUsed = await this.countDailyFreeSlotsUsed(
        userId,
        today,
        openedRepo,
      );

      if (freeUsed < FREE_LESSONS_PER_DAY) {
        await openedRepo.insert({
          userId,
          nodeId,
          diamondsPaid: 0,
          coinsPaid: 0,
        });
        return {
          success: true,
          usedFreeDailySlot: true,
          diamondsPaid: 0,
          remainingFreeLessonsToday: FREE_LESSONS_PER_DAY - freeUsed - 1,
          message: 'Đã mở bài bằng suất miễn phí trong ngày',
        };
      }

      const shouldUseCoins =
        subject.subjectType === 'community' && preferredCurrency === 'coins';
      if (shouldUseCoins) {
        try {
          await this.currencyService.deductCoinsTransactional(
            manager,
            userId,
            DIAMOND_PER_LESSON_OPEN,
          );
        } catch {
          const currency = await this.currencyService.getCurrency(userId);
          throw new BadRequestException(
            `Không đủ xu. Cần ${DIAMOND_PER_LESSON_OPEN} xu để mở bài, bạn có ${currency.coins ?? 0} xu.`,
          );
        }
      } else {
        try {
          await this.currencyService.deductDiamondsTransactional(
            manager,
            userId,
            DIAMOND_PER_LESSON_OPEN,
          );
        } catch {
          const currency = await this.currencyService.getCurrency(userId);
          throw new BadRequestException(
            `Không đủ kim cương. Cần ${DIAMOND_PER_LESSON_OPEN} 💎 để mở bài, bạn có ${currency.diamonds ?? 0} 💎. Mỗi ngày có ${FREE_LESSONS_PER_DAY} bài miễn phí (đã dùng hết hôm nay).`,
          );
        }
      }

      await openedRepo.insert({
        userId,
        nodeId,
        diamondsPaid: shouldUseCoins ? 0 : DIAMOND_PER_LESSON_OPEN,
        coinsPaid: shouldUseCoins ? DIAMOND_PER_LESSON_OPEN : 0,
      });

      return {
        success: true,
        usedFreeDailySlot: false,
        diamondsPaid: shouldUseCoins ? 0 : DIAMOND_PER_LESSON_OPEN,
        coinsPaid: shouldUseCoins ? DIAMOND_PER_LESSON_OPEN : 0,
        remainingFreeLessonsToday: 0,
        message: shouldUseCoins
          ? `Đã mở bài (${DIAMOND_PER_LESSON_OPEN} xu)`
          : `Đã mở bài (${DIAMOND_PER_LESSON_OPEN} 💎)`,
      };
    });
  }

  // ═══════════════════════════════════════════════════════
  //  ACCESS CHECK
  // ═══════════════════════════════════════════════════════

  /**
   * Check if user can access a specific learning node
   */
  async canAccessNode(
    userId: string,
    nodeId: string,
  ): Promise<{
    canAccess: boolean;
    nodeInfo?: any;
    remainingFreeLessonsToday?: number;
    subjectType?: 'private' | 'community' | 'expert';
    coinCost?: number;
    diamondCost?: number;
    userCoins?: number;
    userDiamonds?: number;
  }> {
    if (!userId) return { canAccess: false };

    const opened = await this.openedNodeRepository.findOne({
      where: { userId, nodeId },
    });
    if (opened) return { canAccess: true };

    const node = await this.nodeRepository.findOne({
      where: { id: nodeId },
      select: ['id', 'subjectId', 'domainId', 'topicId'],
    });
    if (!node) return { canAccess: false };
    const subject = await this.dataSource.getRepository(Subject).findOne({
      where: { id: node.subjectId },
      select: ['id', 'subjectType', 'ownerUserId'],
    });
    if (!subject) return { canAccess: false };
    if (subject.subjectType === 'private') {
      return {
        canAccess: subject.ownerUserId === userId,
        subjectType: 'private',
      };
    }

    if (await this.hasTierUnlockForNode(userId, node)) {
      return { canAccess: true };
    }

    const currency = await this.currencyService.getCurrency(userId);
    const usedFree = await this.countFreeLessonOpensToday(userId);
    const remaining = Math.max(0, FREE_LESSONS_PER_DAY - usedFree);

    return {
      canAccess: false,
      subjectType: subject.subjectType,
      remainingFreeLessonsToday: remaining,
      coinCost: subject.subjectType === 'community' ? DIAMOND_PER_LESSON_OPEN : undefined,
      diamondCost: DIAMOND_PER_LESSON_OPEN,
      userCoins: currency.coins ?? 0,
      userDiamonds: currency.diamonds ?? 0,
      nodeInfo: {
        subjectId: node.subjectId,
        domainId: node.domainId,
        topicId: node.topicId,
        price: DIAMOND_PER_LESSON_OPEN,
        freeLessonsPerDay: FREE_LESSONS_PER_DAY,
      },
    };
  }

  /**
   * Get all unlocked node IDs for a user in a subject
   * Used by learning-nodes and personal-mind-map services
   */
  async getUserUnlockedNodeIds(
    userId: string,
    subjectId: string,
  ): Promise<Set<string>> {
    const unlocks = await this.unlockRepository.find({
      where: { userId, subjectId },
      select: ['unlockLevel', 'subjectId', 'domainId', 'topicId'],
    });

    // Check subject-level unlock
    const hasSubjectUnlock = unlocks.some(
      (u) => u.unlockLevel === 'subject' && u.subjectId === subjectId,
    );

    if (hasSubjectUnlock) {
      // All nodes in subject are unlocked
      const nodes = await this.nodeRepository.find({
        where: { subjectId },
        select: ['id'],
      });
      return new Set(nodes.map((n) => n.id));
    }

    // Collect unlocked domain IDs and topic IDs
    const unlockedDomainIds = new Set(
      unlocks
        .filter((u) => u.unlockLevel === 'domain' && u.subjectId === subjectId)
        .map((u) => u.domainId),
    );
    const unlockedTopicIds = new Set(
      unlocks
        .filter((u) => u.unlockLevel === 'topic' && u.subjectId === subjectId)
        .map((u) => u.topicId),
    );

    if (unlockedDomainIds.size === 0 && unlockedTopicIds.size === 0) {
      return new Set();
    }

    // Get all nodes in subject
    const allNodes = await this.nodeRepository.find({
      where: { subjectId },
      select: ['id', 'domainId', 'topicId'],
    });

    const unlockedNodeIds = new Set<string>();
    for (const node of allNodes) {
      if (
        (node.domainId && unlockedDomainIds.has(node.domainId)) ||
        (node.topicId && unlockedTopicIds.has(node.topicId))
      ) {
        unlockedNodeIds.add(node.id);
      }
    }

    const openedRows = await this.openedNodeRepository.find({
      where: { userId },
      select: ['nodeId'],
    });
    const openedSet = new Set(openedRows.map((r) => r.nodeId));
    for (const node of allNodes) {
      if (openedSet.has(node.id)) {
        unlockedNodeIds.add(node.id);
      }
    }

    return unlockedNodeIds;
  }

  // ═══════════════════════════════════════════════════════
  //  LEGACY (kept for backward compat)
  // ═══════════════════════════════════════════════════════

  async getUserTransactions(userId: string): Promise<UnlockTransaction[]> {
    return this.transactionRepository.find({
      where: { userId },
      relations: ['subject'],
      order: { createdAt: 'DESC' },
    });
  }

  async getUserUnlocks(userId: string): Promise<UserUnlock[]> {
    return this.unlockRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }
}
