import {
  Injectable,
  BadRequestException,
  NotFoundException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UnlockTransaction } from './entities/unlock-transaction.entity';
import { UserUnlock } from './entities/user-unlock.entity';
import { UserCurrencyService } from '../user-currency/user-currency.service';
import { SubjectsService } from '../subjects/subjects.service';
import { DomainsService } from '../domains/domains.service';
import { TopicsService } from '../topics/topics.service';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';

// Pricing constants
const DIAMOND_PER_LESSON = 25;
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

    // Auto-unlock first topic if user hasn't unlocked anything yet
    if (userId) {
      await this.ensureFirstTopicUnlocked(userId, subjectId);
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
  //  AUTO-UNLOCK FIRST TOPIC (FREE)
  // ═══════════════════════════════════════════════════════

  /**
   * Auto-unlock the first topic of a subject for free.
   * Called when user first accesses a subject's learning path.
   * Returns the topicId that was unlocked (or already unlocked).
   */
  async ensureFirstTopicUnlocked(
    userId: string,
    subjectId: string,
  ): Promise<{ topicId: string | null; alreadyUnlocked: boolean }> {
    if (!userId || !subjectId) {
      return { topicId: null, alreadyUnlocked: false };
    }

    // Check if user already has ANY unlock for this subject
    const existingUnlocks = await this.unlockRepository.find({
      where: { userId, subjectId },
    });

    if (existingUnlocks.length > 0) {
      // Already has some unlock - don't auto-unlock again
      const firstTopicUnlock = existingUnlocks.find(
        (u) => u.unlockLevel === 'topic' && u.diamondsCost === 0,
      );
      return {
        topicId: firstTopicUnlock?.topicId || null,
        alreadyUnlocked: true,
      };
    }

    // Find first domain (by order)
    const domains = await this.domainsService.findBySubject(subjectId);
    if (domains.length === 0) {
      return { topicId: null, alreadyUnlocked: false };
    }

    const firstDomain = domains[0];

    // Find first topic of first domain
    const topics = await this.topicsService.findByDomain(firstDomain.id);
    if (topics.length === 0) {
      return { topicId: null, alreadyUnlocked: false };
    }

    const firstTopic = topics[0];

    // Count lessons in this topic
    const topicNodes = await this.nodeRepository.find({
      where: { topicId: firstTopic.id },
    });

    // Create free unlock record
    const unlock = this.unlockRepository.create({
      userId,
      unlockLevel: 'topic' as const,
      subjectId,
      domainId: firstDomain.id,
      topicId: firstTopic.id,
      diamondsCost: 0,
      lessonsCount: topicNodes.length,
      discountPercent: 100, // 100% free
    });

    await this.unlockRepository.save(unlock);

    return { topicId: firstTopic.id, alreadyUnlocked: false };
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
        await this.currencyService.deductCoins(userId, price);
      } catch {
        const currency = await this.currencyService.getCurrency(userId);
        throw new BadRequestException(
          `Không đủ kim cương. Cần ${price} 💎, bạn có ${currency.coins} 💎.`,
        );
      }
    }

    // Create unlock record
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
        await this.currencyService.deductCoins(userId, price);
      } catch {
        const currency = await this.currencyService.getCurrency(userId);
        throw new BadRequestException(
          `Không đủ kim cương. Cần ${price} 💎, bạn có ${currency.coins} 💎.`,
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

    // Atomic deduct
    try {
      await this.currencyService.deductCoins(userId, price);
    } catch {
      const currency = await this.currencyService.getCurrency(userId);
      throw new BadRequestException(
        `Không đủ kim cương. Cần ${price} 💎, bạn có ${currency.coins} 💎.`,
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
  //  ACCESS CHECK
  // ═══════════════════════════════════════════════════════

  /**
   * Check if user can access a specific learning node
   */
  async canAccessNode(
    userId: string,
    nodeId: string,
  ): Promise<{ canAccess: boolean; nodeInfo?: any }> {
    if (!userId) return { canAccess: false };

    const node = await this.nodeRepository.findOne({ where: { id: nodeId } });
    if (!node) return { canAccess: false };

    // Check subject-level unlock
    if (node.subjectId) {
      const subjectUnlock = await this.unlockRepository.findOne({
        where: { userId, unlockLevel: 'subject', subjectId: node.subjectId },
      });
      if (subjectUnlock) return { canAccess: true };
    }

    // Check domain-level unlock
    if (node.domainId) {
      const domainUnlock = await this.unlockRepository.findOne({
        where: { userId, unlockLevel: 'domain', domainId: node.domainId },
      });
      if (domainUnlock) return { canAccess: true };
    }

    // Check topic-level unlock
    if (node.topicId) {
      const topicUnlock = await this.unlockRepository.findOne({
        where: { userId, unlockLevel: 'topic', topicId: node.topicId },
      });
      if (topicUnlock) return { canAccess: true };
    }

    return {
      canAccess: false,
      nodeInfo: {
        subjectId: node.subjectId,
        domainId: node.domainId,
        topicId: node.topicId,
        price: DIAMOND_PER_LESSON,
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
      where: { userId },
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
