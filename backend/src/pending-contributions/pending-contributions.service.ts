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
  ContributionStatus,
} from './entities/pending-contribution.entity';
import { SubjectsService } from '../subjects/subjects.service';
import { DomainsService } from '../domains/domains.service';

@Injectable()
export class PendingContributionsService {
  constructor(
    @InjectRepository(PendingContribution)
    private readonly pendingRepo: Repository<PendingContribution>,
    private readonly subjectsService: SubjectsService,
    @Inject(forwardRef(() => DomainsService))
    private readonly domainsService: DomainsService,
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
      status: ContributionStatus.PENDING,
      contributorId,
      title: data.name,
      description: data.description || '',
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
    data: { name: string; description?: string; subjectId: string },
  ): Promise<PendingContribution> {
    // Validate subject exists
    const subject = await this.subjectsService.findById(data.subjectId);
    if (!subject) {
      throw new NotFoundException('Subject not found');
    }

    const contribution = this.pendingRepo.create({
      type: ContributionType.DOMAIN,
      status: ContributionStatus.PENDING,
      contributorId,
      title: data.name,
      description: data.description || '',
      parentSubjectId: data.subjectId,
      data: {
        name: data.name,
        description: data.description || '',
        subjectId: data.subjectId,
        subjectName: subject.name,
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
    },
  ): Promise<PendingContribution> {
    const contribution = this.pendingRepo.create({
      type: ContributionType.TOPIC,
      status: ContributionStatus.PENDING,
      contributorId,
      title: data.name,
      description: data.description || '',
      parentSubjectId: data.subjectId,
      parentDomainId: data.domainId,
      data: {
        name: data.name,
        description: data.description || '',
        domainId: data.domainId,
        subjectId: data.subjectId,
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
      nodeId: string;
      subjectId: string;
      description?: string;
    },
  ): Promise<PendingContribution> {
    const contribution = this.pendingRepo.create({
      type: ContributionType.LESSON,
      status: ContributionStatus.PENDING,
      contributorId,
      title: data.title,
      description: data.description || '',
      parentSubjectId: data.subjectId,
      data: {
        title: data.title,
        content: data.content || '',
        richContent: data.richContent,
        nodeId: data.nodeId,
        subjectId: data.subjectId,
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

    // Actually create the entity based on type
    try {
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
          const domain = await this.domainsService.create(
            contribution.data.subjectId || contribution.parentSubjectId,
            {
              name: contribution.data.name,
              description: contribution.data.description,
              metadata: {
                topics: contribution.data.topics || [],
              },
            },
          );
          contribution.data = { ...contribution.data, createdEntityId: domain.id };
          break;

        case ContributionType.TOPIC:
          // Topics are stored as metadata in domains
          // Add the topic name to the domain's metadata.topics array
          const domainId = contribution.data.domainId || contribution.parentDomainId;
          if (domainId) {
            const existingDomain = await this.domainsService.findById(domainId);
            if (existingDomain) {
              const currentTopics = existingDomain.metadata?.topics || [];
              const topicName = contribution.data.name;
              if (!currentTopics.includes(topicName)) {
                currentTopics.push(topicName);
                await this.domainsService.update(domainId, {
                  metadata: { ...existingDomain.metadata, topics: currentTopics },
                });
              }
              contribution.data = { ...contribution.data, addedToDomainId: domainId };
            }
          }
          break;

        default:
          break;
      }
    } catch (error) {
      throw new BadRequestException(
        `Failed to create entity: ${error.message}`,
      );
    }

    contribution.status = ContributionStatus.APPROVED;
    contribution.reviewedBy = adminId;
    contribution.reviewNote = note || '';
    contribution.reviewedAt = new Date();

    return this.pendingRepo.save(contribution);
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
