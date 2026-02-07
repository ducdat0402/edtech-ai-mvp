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

  // The actual data for the contribution (varies by type)
  @Column({ type: 'jsonb' })
  data: Record<string, any>;
  // For subject: { name, description, track }
  // For domain: { name, description, subjectId }
  // For topic: { name, description, domainId, subjectId }
  // For lesson: { title, content, richContent, nodeId, subjectId }

  // Parent reference (subjectId for domain/topic/lesson)
  @Column({ type: 'uuid', nullable: true })
  parentSubjectId: string;

  // Parent reference (domainId for topic)
  @Column({ type: 'uuid', nullable: true })
  parentDomainId: string;

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
