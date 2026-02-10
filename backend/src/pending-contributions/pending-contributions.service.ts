import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  PendingContribution,
  ContributionType,
  ContributionAction,
  ContributionStatus,
} from './entities/pending-contribution.entity';
import { SubjectsService } from '../subjects/subjects.service';
import { DomainsService } from '../domains/domains.service';
import { TopicsService } from '../topics/topics.service';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { LessonTypeContentsService } from '../lesson-type-contents/lesson-type-contents.service';

@Injectable()
export class PendingContributionsService {
  constructor(
    @InjectRepository(PendingContribution)
    private readonly pendingRepo: Repository<PendingContribution>,
    private readonly subjectsService: SubjectsService,
    @Inject(forwardRef(() => DomainsService))
    private readonly domainsService: DomainsService,
    @Inject(forwardRef(() => TopicsService))
    private readonly topicsService: TopicsService,
    @InjectRepository(LearningNode)
    private readonly learningNodeRepo: Repository<LearningNode>,
    private readonly lessonTypeContentsService: LessonTypeContentsService,
  ) {}

  // =====================
  // Create contributions
  // =====================

  async createSubjectContribution(
    contributorId: string,
    data: { name: string; description?: string; track?: 'explorer' | 'scholar' },
  ): Promise<PendingContribution> {
    const contribution = this.pendingRepo.create({
      type: ContributionType.SUBJECT,
      action: ContributionAction.CREATE,
      status: ContributionStatus.PENDING,
      contributorId,
      title: data.name,
      description: data.description || '',
      contextDescription: `Đề xuất tạo môn học mới: "${data.name}"`,
      data: {
        name: data.name,
        description: data.description || '',
        track: data.track || 'explorer',
      },
    });
    return this.pendingRepo.save(contribution);
  }

  async createDomainContribution(
    contributorId: string,
    data: {
      name: string;
      description?: string;
      subjectId: string;
      difficulty?: 'easy' | 'medium' | 'hard';
      afterEntityId?: string; // ID of the domain this should come after
      expReward?: number;
      coinReward?: number;
    },
  ): Promise<PendingContribution> {
    const subject = await this.subjectsService.findById(data.subjectId);
    if (!subject) {
      throw new NotFoundException('Subject not found');
    }

    const contribution = this.pendingRepo.create({
      type: ContributionType.DOMAIN,
      action: ContributionAction.CREATE,
      status: ContributionStatus.PENDING,
      contributorId,
      title: data.name,
      description: data.description || '',
      parentSubjectId: data.subjectId,
      contextDescription: `Đề xuất tạo domain "${data.name}" trong môn "${subject.name}"`,
      data: {
        name: data.name,
        description: data.description || '',
        subjectId: data.subjectId,
        subjectName: subject.name,
        difficulty: data.difficulty || 'medium',
        afterEntityId: data.afterEntityId || null,
        expReward: data.expReward || 0,
        coinReward: data.coinReward || 0,
      },
    });
    return this.pendingRepo.save(contribution);
  }

  async createTopicContribution(
    contributorId: string,
    data: {
      name: string;
      description?: string;
      domainId: string;
      subjectId: string;
      difficulty?: 'easy' | 'medium' | 'hard';
      afterEntityId?: string; // ID of the topic this should come after
      expReward?: number;
      coinReward?: number;
    },
  ): Promise<PendingContribution> {
    const subject = await this.subjectsService.findById(data.subjectId);
    const domain = await this.domainsService.findById(data.domainId);

    const contribution = this.pendingRepo.create({
      type: ContributionType.TOPIC,
      action: ContributionAction.CREATE,
      status: ContributionStatus.PENDING,
      contributorId,
      title: data.name,
      description: data.description || '',
      parentSubjectId: data.subjectId,
      parentDomainId: data.domainId,
      contextDescription: `Đề xuất tạo topic "${data.name}" trong domain "${domain?.name || '?'}" ở môn "${subject?.name || '?'}"`,
      data: {
        name: data.name,
        description: data.description || '',
        domainId: data.domainId,
        subjectId: data.subjectId,
        domainName: domain?.name || '',
        subjectName: subject?.name || '',
        difficulty: data.difficulty || 'medium',
        afterEntityId: data.afterEntityId || null,
        expReward: data.expReward || 0,
        coinReward: data.coinReward || 0,
      },
    });
    return this.pendingRepo.save(contribution);
  }

  // =====================
  // Edit contributions (rename)
  // =====================

  async createEditContribution(
    contributorId: string,
    data: {
      type: ContributionType; // subject, domain, topic, lesson
      entityId: string;
      newName: string;
      newDescription?: string;
      reason?: string;
    },
  ): Promise<PendingContribution> {
    let title = '';
    let contextDesc = '';
    let oldName = '';
    let parentSubjectId: string | null = null;
    let parentDomainId: string | null = null;
    const extra: Record<string, any> = {};

    switch (data.type) {
      case ContributionType.SUBJECT:
        const subject = await this.subjectsService.findById(data.entityId);
        if (!subject) throw new NotFoundException('Subject not found');
        oldName = subject.name;
        title = `Sửa tên: "${oldName}" → "${data.newName}"`;
        contextDesc = `Đề xuất đổi tên môn học "${oldName}" thành "${data.newName}"`;
        extra.subjectName = oldName;
        break;

      case ContributionType.DOMAIN:
        const domain = await this.domainsService.findById(data.entityId);
        if (!domain) throw new NotFoundException('Domain not found');
        oldName = domain.name;
        parentSubjectId = domain.subjectId;
        const domainSubject = await this.subjectsService.findById(domain.subjectId);
        title = `Sửa tên: "${oldName}" → "${data.newName}"`;
        contextDesc = `Đề xuất đổi tên domain "${oldName}" thành "${data.newName}" trong môn "${domainSubject?.name || '?'}"`;
        extra.subjectName = domainSubject?.name || '';
        extra.domainName = oldName;
        break;

      case ContributionType.TOPIC:
        const topicEntity = await this.topicsService.findById(data.entityId);
        if (!topicEntity) throw new NotFoundException('Topic not found');
        oldName = topicEntity.name;
        parentDomainId = topicEntity.domainId;
        title = `Sửa tên topic: "${oldName}" → "${data.newName}"`;
        const topicDomain2 = topicEntity.domain || await this.domainsService.findById(topicEntity.domainId);
        if (topicDomain2) {
          parentSubjectId = topicDomain2.subjectId;
          const topicSubject2 = await this.subjectsService.findById(topicDomain2.subjectId);
          contextDesc = `Đề xuất đổi tên topic "${oldName}" thành "${data.newName}" trong domain "${topicDomain2.name}" ở môn "${topicSubject2?.name || '?'}"`;
          extra.domainName = topicDomain2.name;
          extra.subjectName = topicSubject2?.name || '';
        } else {
          contextDesc = `Đề xuất đổi tên topic "${oldName}" thành "${data.newName}"`;
        }
        break;

      case ContributionType.LESSON:
        const lesson = await this.learningNodeRepo.findOne({
          where: { id: data.entityId },
          relations: ['subject', 'topic'],
        });
        if (!lesson) throw new NotFoundException('Learning node not found');
        oldName = lesson.title;
        parentSubjectId = lesson.subjectId;
        parentDomainId = lesson.domainId;
        title = `Sửa bài học: "${oldName}" → "${data.newName}"`;
        contextDesc = `Đề xuất đổi tên bài học "${oldName}" thành "${data.newName}" trong môn "${lesson.subject?.name || '?'}"`;
        extra.subjectName = lesson.subject?.name || '';
        extra.lessonType = lesson.lessonType;
        break;

      default:
        throw new BadRequestException('Edit not supported for this type');
    }

    const contribution = this.pendingRepo.create({
      type: data.type,
      action: ContributionAction.EDIT,
      status: ContributionStatus.PENDING,
      contributorId,
      title,
      description: data.reason || '',
      contextDescription: contextDesc,
      parentSubjectId,
      parentDomainId,
      data: {
        entityId: data.entityId,
        oldName,
        newName: data.newName,
        newDescription: data.newDescription,
        reason: data.reason || '',
        ...extra,
      },
    });
    return this.pendingRepo.save(contribution);
  }

  // =====================
  // Delete contributions
  // =====================

  async createDeleteContribution(
    contributorId: string,
    data: {
      type: ContributionType; // subject, domain, topic
      entityId: string;
      reason?: string;
      domainId?: string; // Required for topic deletion
    },
  ): Promise<PendingContribution> {
    let title = '';
    let contextDesc = '';
    let entityName = '';
    let parentSubjectId: string | null = null;
    let parentDomainId: string | null = null;
    const extra: Record<string, any> = {};

    switch (data.type) {
      case ContributionType.SUBJECT:
        const subject = await this.subjectsService.findById(data.entityId);
        if (!subject) throw new NotFoundException('Subject not found');
        entityName = subject.name;
        title = `Xóa môn học: "${entityName}"`;
        contextDesc = `Đề xuất xóa môn học "${entityName}"`;
        extra.subjectName = entityName;
        break;

      case ContributionType.DOMAIN:
        const domain = await this.domainsService.findById(data.entityId);
        if (!domain) throw new NotFoundException('Domain not found');
        entityName = domain.name;
        parentSubjectId = domain.subjectId;
        const domainSubject = await this.subjectsService.findById(domain.subjectId);
        title = `Xóa domain: "${entityName}"`;
        contextDesc = `Đề xuất xóa domain "${entityName}" trong môn "${domainSubject?.name || '?'}"`;
        extra.subjectName = domainSubject?.name || '';
        extra.domainName = entityName;
        break;

      case ContributionType.TOPIC:
        const delTopic = await this.topicsService.findById(data.entityId);
        if (!delTopic) throw new NotFoundException('Topic not found');
        entityName = delTopic.name;
        parentDomainId = delTopic.domainId;
        title = `Xóa topic: "${entityName}"`;
        const delDomain = delTopic.domain || await this.domainsService.findById(delTopic.domainId);
        if (delDomain) {
          parentSubjectId = delDomain.subjectId;
          const delSubject = await this.subjectsService.findById(delDomain.subjectId);
          contextDesc = `Đề xuất xóa topic "${entityName}" trong domain "${delDomain.name}" ở môn "${delSubject?.name || '?'}"`;
          extra.domainName = delDomain.name;
          extra.subjectName = delSubject?.name || '';
        }
        if (!contextDesc) contextDesc = `Đề xuất xóa topic "${entityName}"`;
        break;

      case ContributionType.LESSON:
        const delLesson = await this.learningNodeRepo.findOne({
          where: { id: data.entityId },
          relations: ['subject', 'topic'],
        });
        if (!delLesson) throw new NotFoundException('Learning node not found');
        entityName = delLesson.title;
        parentSubjectId = delLesson.subjectId;
        parentDomainId = delLesson.domainId;
        title = `Xóa bài học: "${entityName}"`;
        contextDesc = `Đề xuất xóa bài học "${entityName}" trong môn "${delLesson.subject?.name || '?'}"`;
        extra.subjectName = delLesson.subject?.name || '';
        extra.lessonType = delLesson.lessonType;
        break;

      default:
        throw new BadRequestException('Delete not supported for this type');
    }

    const contribution = this.pendingRepo.create({
      type: data.type,
      action: ContributionAction.DELETE,
      status: ContributionStatus.PENDING,
      contributorId,
      title,
      description: data.reason || '',
      contextDescription: contextDesc,
      parentSubjectId,
      parentDomainId,
      data: {
        entityId: data.entityId,
        entityName,
        reason: data.reason || '',
        domainId: data.domainId,
        ...extra,
      },
    });
    return this.pendingRepo.save(contribution);
  }

  async createLessonContribution(
    contributorId: string,
    data: {
      title: string;
      content?: string;
      richContent?: any;
      nodeId?: string;
      subjectId: string;
      domainId?: string;
      topicId?: string;
      description?: string;
      // New lesson type fields
      lessonType?: 'image_quiz' | 'image_gallery' | 'video' | 'text';
      lessonData?: Record<string, any>;
      endQuiz?: Record<string, any>;
      topicName?: string;
      // Ordering & rewards
      difficulty?: 'easy' | 'medium' | 'hard';
      afterEntityId?: string;
      expReward?: number;
      coinReward?: number;
    },
  ): Promise<PendingContribution> {
    // Resolve topic name for context description
    let topicLabel = data.topicName || '';
    if (!topicLabel && data.topicId) {
      const topic = await this.topicsService.findById(data.topicId);
      if (topic) topicLabel = topic.name;
    }

    const contextDescription = data.lessonType
      ? `Tạo bài học dạng "${data.lessonType}" - "${data.title}"${topicLabel ? ` trong topic "${topicLabel}"` : ''}`
      : `Tạo bài học "${data.title}"`;

    const contribution = this.pendingRepo.create({
      type: ContributionType.LESSON,
      action: ContributionAction.CREATE,
      status: ContributionStatus.PENDING,
      contributorId,
      title: data.title,
      description: data.description || '',
      contextDescription,
      parentSubjectId: data.subjectId,
      parentDomainId: data.domainId || null,
      data: {
        title: data.title,
        description: data.description || '',
        content: data.content || '',
        richContent: data.richContent,
        nodeId: data.nodeId,
        subjectId: data.subjectId,
        domainId: data.domainId,
        topicId: data.topicId,
        topicName: topicLabel,
        // New lesson type fields
        lessonType: data.lessonType,
        lessonData: data.lessonData,
        endQuiz: data.endQuiz,
        // Ordering & rewards
        difficulty: data.difficulty || 'medium',
        afterEntityId: data.afterEntityId || null,
        expReward: data.expReward || 0,
        coinReward: data.coinReward || 0,
      },
    });
    return this.pendingRepo.save(contribution);
  }

  // =====================
  // Lesson Content Edit contributions
  // =====================

  /**
   * Create a contribution to edit the content of a specific lesson type.
   * This differs from createEditContribution which only renames entities.
   */
  async createLessonContentEditContribution(
    contributorId: string,
    data: {
      nodeId: string;
      lessonType: 'image_quiz' | 'image_gallery' | 'video' | 'text';
      lessonData: Record<string, any>;
      endQuiz?: Record<string, any>;
      reason?: string;
    },
  ): Promise<PendingContribution> {
    // Verify the node exists
    const node = await this.learningNodeRepo.findOne({
      where: { id: data.nodeId },
      relations: ['subject'],
    });
    if (!node) throw new NotFoundException('Learning node not found');

    const lessonTypeLabel = data.lessonType.replace(/_/g, ' ');
    const title = `Sửa nội dung dạng "${lessonTypeLabel}" - "${node.title}"`;
    const contextDesc = `Đề xuất sửa nội dung dạng "${lessonTypeLabel}" cho bài "${node.title}" trong môn "${node.subject?.name || '?'}"`;

    const contribution = this.pendingRepo.create({
      type: ContributionType.LESSON,
      action: ContributionAction.EDIT,
      status: ContributionStatus.PENDING,
      contributorId,
      title,
      description: data.reason || '',
      contextDescription: contextDesc,
      parentSubjectId: node.subjectId,
      parentDomainId: node.domainId,
      data: {
        entityId: data.nodeId,
        nodeId: data.nodeId,
        lessonType: data.lessonType,
        lessonData: data.lessonData,
        endQuiz: data.endQuiz || null,
        reason: data.reason || '',
        isContentEdit: true, // flag to distinguish from rename edits
        subjectName: node.subject?.name || '',
        lessonTitle: node.title,
      },
    });
    return this.pendingRepo.save(contribution);
  }

  // =====================
  // Read contributions
  // =====================

  async findAll(filters?: {
    type?: ContributionType;
    status?: ContributionStatus;
    contributorId?: string;
  }): Promise<PendingContribution[]> {
    const where: any = {};
    if (filters?.type) where.type = filters.type;
    if (filters?.status) where.status = filters.status;
    if (filters?.contributorId) where.contributorId = filters.contributorId;

    return this.pendingRepo.find({
      where,
      order: { createdAt: 'DESC' },
      relations: ['contributor'],
    });
  }

  async findById(id: string): Promise<PendingContribution> {
    const contribution = await this.pendingRepo.findOne({
      where: { id },
      relations: ['contributor'],
    });
    if (!contribution) {
      throw new NotFoundException('Contribution not found');
    }
    return contribution;
  }

  async findMyContributions(
    contributorId: string,
  ): Promise<PendingContribution[]> {
    return this.pendingRepo.find({
      where: { contributorId },
      order: { createdAt: 'DESC' },
    });
  }

  async findPending(): Promise<PendingContribution[]> {
    return this.pendingRepo.find({
      where: { status: ContributionStatus.PENDING },
      order: { createdAt: 'ASC' },
      relations: ['contributor'],
    });
  }

  // =====================
  // Update contributions
  // =====================

  async updateContribution(
    id: string,
    contributorId: string,
    data: { title?: string; description?: string; data?: Record<string, any> },
  ): Promise<PendingContribution> {
    const contribution = await this.findById(id);

    if (contribution.contributorId !== contributorId) {
      throw new ForbiddenException('You can only edit your own contributions');
    }
    if (contribution.status !== ContributionStatus.PENDING) {
      throw new BadRequestException(
        'Cannot edit a contribution that has already been reviewed',
      );
    }

    if (data.title) contribution.title = data.title;
    if (data.description !== undefined)
      contribution.description = data.description;
    if (data.data) contribution.data = { ...contribution.data, ...data.data };

    return this.pendingRepo.save(contribution);
  }

  async deleteContribution(
    id: string,
    contributorId: string,
  ): Promise<void> {
    const contribution = await this.findById(id);

    if (contribution.contributorId !== contributorId) {
      throw new ForbiddenException('You can only delete your own contributions');
    }
    if (contribution.status !== ContributionStatus.PENDING) {
      throw new BadRequestException(
        'Cannot delete a contribution that has already been reviewed',
      );
    }

    await this.pendingRepo.remove(contribution);
  }

  // =====================
  // Admin: Approve/Reject
  // =====================

  async approveContribution(
    id: string,
    adminId: string,
    note?: string,
  ): Promise<PendingContribution> {
    const contribution = await this.findById(id);

    if (contribution.status !== ContributionStatus.PENDING) {
      throw new BadRequestException('Contribution already reviewed');
    }

    // Determine action - handle old contributions that don't have action field
    let action = contribution.action || ContributionAction.CREATE;
    // Infer action from data if action column is null (pre-migration contributions)
    if (!contribution.action && contribution.data) {
      if (contribution.data.oldName && contribution.data.newName) {
        action = ContributionAction.EDIT;
      } else if (contribution.data.entityName && !contribution.data.name) {
        action = ContributionAction.DELETE;
      }
    }

    try {
      if (action === ContributionAction.CREATE) {
        await this.executeCreateAction(contribution);
      } else if (action === ContributionAction.EDIT) {
        await this.executeEditAction(contribution);
      } else if (action === ContributionAction.DELETE) {
        await this.executeDeleteAction(contribution);
      }
    } catch (error) {
      throw new BadRequestException(
        `Failed to execute ${action} action: ${error.message}`,
      );
    }

    contribution.status = ContributionStatus.APPROVED;
    contribution.reviewedBy = adminId;
    contribution.reviewNote = note || '';
    contribution.reviewedAt = new Date();

    return this.pendingRepo.save(contribution);
  }

  private async executeCreateAction(contribution: PendingContribution): Promise<void> {
    switch (contribution.type) {
      case ContributionType.SUBJECT:
        const subject = await this.subjectsService.createIfNotExists(
          contribution.data.name,
          contribution.data.description,
          contribution.data.track || 'explorer',
        );
        contribution.data = { ...contribution.data, createdEntityId: subject.id };
        break;

      case ContributionType.DOMAIN:
        // Calculate order based on afterEntityId
        let domainOrder = 0;
        if (contribution.data.afterEntityId) {
          const afterDomain = await this.domainsService.findById(contribution.data.afterEntityId);
          if (afterDomain) domainOrder = (afterDomain.order || 0) + 1;
        }
        const domain = await this.domainsService.create(
          contribution.data.subjectId || contribution.parentSubjectId,
          {
            name: contribution.data.name,
            description: contribution.data.description,
            order: domainOrder,
            difficulty: contribution.data.difficulty || 'medium',
            expReward: contribution.data.expReward || 0,
            coinReward: contribution.data.coinReward || 0,
            metadata: {
              topics: contribution.data.topics || [],
            },
          },
        );
        contribution.data = { ...contribution.data, createdEntityId: domain.id };
        break;

      case ContributionType.TOPIC:
        const topicDomainId = contribution.data.domainId || contribution.parentDomainId;
        if (topicDomainId) {
          // Calculate order based on afterEntityId
          let topicOrder = 0;
          if (contribution.data.afterEntityId) {
            const afterTopic = await this.topicsService.findById(contribution.data.afterEntityId);
            if (afterTopic) topicOrder = (afterTopic.order || 0) + 1;
          }
          const topic = await this.topicsService.create(topicDomainId, {
            name: contribution.data.name,
            description: contribution.data.description || '',
            order: topicOrder,
            difficulty: contribution.data.difficulty || 'medium',
            expReward: contribution.data.expReward || 0,
            coinReward: contribution.data.coinReward || 0,
          });
          contribution.data = { ...contribution.data, createdEntityId: topic.id };
        }
        break;

      case ContributionType.LESSON:
        // Calculate order based on afterEntityId
        let lessonOrder = 0;
        if (contribution.data.afterEntityId) {
          const afterLesson = await this.learningNodeRepo.findOne({ where: { id: contribution.data.afterEntityId } });
          if (afterLesson) lessonOrder = (afterLesson.order || 0) + 1;
        }

        if (contribution.data.nodeId) {
          // Adding lesson type content to an EXISTING node
          const existingNode = await this.learningNodeRepo.findOne({ where: { id: contribution.data.nodeId } });
          if (existingNode && contribution.data.lessonType && contribution.data.lessonData) {
            // Create a LessonTypeContent row in the new table
            try {
              await this.lessonTypeContentsService.create({
                nodeId: existingNode.id,
                lessonType: contribution.data.lessonType,
                lessonData: contribution.data.lessonData,
                endQuiz: contribution.data.endQuiz || { questions: [], passingScore: 70 },
              });
            } catch (error) {
              // If duplicate, update instead
              if (error.status === 409) {
                await this.lessonTypeContentsService.update(existingNode.id, contribution.data.lessonType, {
                  lessonData: contribution.data.lessonData,
                  endQuiz: contribution.data.endQuiz,
                });
              } else {
                throw error;
              }
            }

            // Also update the legacy fields on the node for backward compat
            existingNode.lessonType = contribution.data.lessonType;
            existingNode.lessonData = contribution.data.lessonData;
            existingNode.endQuiz = contribution.data.endQuiz || existingNode.endQuiz;
            await this.learningNodeRepo.save(existingNode);
            contribution.data = { ...contribution.data, createdEntityId: existingNode.id };
          }
        } else {
          // Creating a NEW lesson node (may or may not have lesson type content)
          const newNode = this.learningNodeRepo.create({
            subjectId: contribution.data.subjectId || contribution.parentSubjectId,
            domainId: contribution.data.domainId || null,
            topicId: contribution.data.topicId || null,
            title: contribution.data.title || contribution.title,
            description: contribution.data.description || '',
            lessonType: contribution.data.lessonType || null,
            lessonData: contribution.data.lessonData || null,
            endQuiz: contribution.data.endQuiz || null,
            type: 'theory',
            difficulty: contribution.data.difficulty || 'medium',
            order: lessonOrder,
            expReward: contribution.data.expReward || 0,
            coinReward: contribution.data.coinReward || 0,
            contentStructure: { concepts: 0, examples: 0, hiddenRewards: 0, bossQuiz: 0 },
          });
          const savedNode = await this.learningNodeRepo.save(newNode);

          // If lesson type content is provided, also create a LessonTypeContent row
          if (contribution.data.lessonType && contribution.data.lessonData) {
            try {
              await this.lessonTypeContentsService.create({
                nodeId: savedNode.id,
                lessonType: contribution.data.lessonType,
                lessonData: contribution.data.lessonData,
                endQuiz: contribution.data.endQuiz || { questions: [], passingScore: 70 },
              });
            } catch (error) {
              console.error('Error creating lesson type content:', error);
            }
          }

          contribution.data = { ...contribution.data, createdEntityId: savedNode.id };
        }
        break;

      default:
        break;
    }
  }

  private async executeEditAction(contribution: PendingContribution): Promise<void> {
    const { entityId, newName, newDescription } = contribution.data;

    switch (contribution.type) {
      case ContributionType.SUBJECT:
        const subjectUpdate: any = {};
        if (newName) subjectUpdate.name = newName;
        if (newDescription !== undefined) subjectUpdate.description = newDescription;
        await this.subjectsService.update(entityId, subjectUpdate);
        break;

      case ContributionType.DOMAIN:
        const domainUpdate: any = {};
        if (newName) domainUpdate.name = newName;
        if (newDescription !== undefined) domainUpdate.description = newDescription;
        await this.domainsService.update(entityId, domainUpdate);
        break;

      case ContributionType.TOPIC:
        const topicUpdate: any = {};
        if (newName) topicUpdate.name = newName;
        if (newDescription !== undefined) topicUpdate.description = newDescription;
        await this.topicsService.update(entityId, topicUpdate);
        break;

      case ContributionType.LESSON:
        // Check if this is a content edit (vs a rename edit)
        if (contribution.data.isContentEdit && contribution.data.lessonType && contribution.data.lessonData) {
          const contentNodeId = contribution.data.nodeId || entityId;
          const contentLessonType = contribution.data.lessonType;

          // Save the current version to history before updating
          try {
            await this.lessonTypeContentsService.saveVersionSnapshot(
              contentNodeId,
              contentLessonType,
              contribution.contributorId,
              `Phiên bản trước khi chỉnh sửa bởi contributor`,
            );
          } catch (e) {
            // If no existing content to snapshot, that's OK (it will be created)
            console.log('No existing content to snapshot:', e.message);
          }

          // Update or create the lesson type content
          const existingContent = await this.lessonTypeContentsService.getByNodeIdAndType(
            contentNodeId,
            contentLessonType,
          );

          if (existingContent) {
            await this.lessonTypeContentsService.update(contentNodeId, contentLessonType, {
              lessonData: contribution.data.lessonData,
              endQuiz: contribution.data.endQuiz || undefined,
            });
          } else {
            await this.lessonTypeContentsService.create({
              nodeId: contentNodeId,
              lessonType: contentLessonType,
              lessonData: contribution.data.lessonData,
              endQuiz: contribution.data.endQuiz || { questions: [], passingScore: 70 },
            });
          }

          // Also update legacy fields on the node
          const contentNode = await this.learningNodeRepo.findOne({ where: { id: contentNodeId } });
          if (contentNode) {
            contentNode.lessonType = contentLessonType;
            contentNode.lessonData = contribution.data.lessonData;
            if (contribution.data.endQuiz) contentNode.endQuiz = contribution.data.endQuiz;
            await this.learningNodeRepo.save(contentNode);
          }
        } else {
          // Rename edit
          const lesson = await this.learningNodeRepo.findOne({ where: { id: entityId } });
          if (lesson) {
            if (newName) lesson.title = newName;
            if (newDescription !== undefined) lesson.description = newDescription;
            await this.learningNodeRepo.save(lesson);
          }
        }
        break;

      default:
        break;
    }
  }

  private async executeDeleteAction(contribution: PendingContribution): Promise<void> {
    const { entityId, domainId: dataDomainId } = contribution.data;

    switch (contribution.type) {
      case ContributionType.SUBJECT:
        await this.subjectsService.delete(entityId);
        break;

      case ContributionType.DOMAIN:
        await this.domainsService.delete(entityId);
        break;

      case ContributionType.TOPIC:
        await this.topicsService.delete(entityId);
        break;

      case ContributionType.LESSON:
        const lesson = await this.learningNodeRepo.findOne({ where: { id: entityId } });
        if (lesson) {
          // Clean up related records that may have FK constraints
          await this.learningNodeRepo.manager.query(
            `DELETE FROM user_progress WHERE "nodeId" = $1`,
            [entityId],
          );
          await this.learningNodeRepo.manager.query(
            `DELETE FROM lesson_type_contents WHERE "nodeId" = $1`,
            [entityId],
          ).catch(() => {});
          await this.learningNodeRepo.manager.query(
            `DELETE FROM user_behavior WHERE "nodeId" = $1`,
            [entityId],
          ).catch(() => {});
          await this.learningNodeRepo.remove(lesson);
        }
        break;

      default:
        break;
    }
  }

  async rejectContribution(
    id: string,
    adminId: string,
    note?: string,
  ): Promise<PendingContribution> {
    const contribution = await this.findById(id);

    if (contribution.status !== ContributionStatus.PENDING) {
      throw new BadRequestException('Contribution already reviewed');
    }

    contribution.status = ContributionStatus.REJECTED;
    contribution.reviewedBy = adminId;
    contribution.reviewNote = note || '';
    contribution.reviewedAt = new Date();

    return this.pendingRepo.save(contribution);
  }
}
