import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum ContributionType {
  SUBJECT = 'subject',
  DOMAIN = 'domain',
  TOPIC = 'topic',
  LESSON = 'lesson',
}

export enum ContributionAction {
  CREATE = 'create',
  EDIT = 'edit',
  DELETE = 'delete',
}

export enum ContributionStatus {
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected',
}

@Entity('pending_contributions')
export class PendingContribution {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar' })
  type: ContributionType; // subject, domain, topic, lesson

  @Column({ type: 'varchar', default: ContributionAction.CREATE })
  action: ContributionAction; // create, edit, delete

  @Column({ type: 'varchar', default: ContributionStatus.PENDING })
  status: ContributionStatus;

  @Column()
  contributorId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'contributorId' })
  contributor: User;

  // Title of the contribution (subject name, domain name, topic name, lesson title)
  @Column()
  title: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  // Admin-readable description: "UserA đề xuất xóa topic X trong domain Y ở môn Z"
  @Column({ type: 'text', nullable: true })
  contextDescription: string;

  // The actual data for the contribution (varies by type)
  @Column({ type: 'jsonb' })
  data: Record<string, any>;
  // For create subject: { name, description, track }
  // For create domain: { name, description, subjectId, subjectName }
  // For create topic: { name, description, domainId, subjectId }
  // For edit: { entityId, oldName, newName, newDescription?, subjectName, domainName? }
  // For delete: { entityId, entityName, subjectName, domainName?, reason? }

  // Parent reference (subjectId for domain/topic/lesson)
  @Column({ type: 'uuid', nullable: true })
  parentSubjectId: string;

  // Parent reference (domainId for topic)
  @Column({ type: 'uuid', nullable: true })
  parentDomainId: string;

  // Parent reference (topicId for lesson)
  @Column({ type: 'uuid', nullable: true })
  parentTopicId: string;

  // Admin who reviewed
  @Column({ type: 'uuid', nullable: true })
  reviewedBy: string;

  @Column({ type: 'text', nullable: true })
  reviewNote: string;

  @Column({ type: 'timestamp', nullable: true })
  reviewedAt: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
