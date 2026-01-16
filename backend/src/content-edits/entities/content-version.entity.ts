import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  JoinColumn,
} from 'typeorm';
import { ContentItem } from '../../content-items/entities/content-item.entity';
import { User } from '../../users/entities/user.entity';
import { ContentEdit } from './content-edit.entity';

/**
 * ContentVersion entity stores snapshots of content items when edits are approved.
 * This allows reverting to previous versions.
 */
@Entity('content_versions')
export class ContentVersion {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => ContentItem)
  @JoinColumn({ name: 'contentItemId' })
  contentItem: ContentItem;

  @Column()
  contentItemId: string;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'approvedByUserId' })
  approvedBy: User | null; // Admin who approved this version

  @Column({ nullable: true })
  approvedByUserId: string | null;

  @ManyToOne(() => ContentEdit, { nullable: true })
  @JoinColumn({ name: 'relatedEditId' })
  relatedEdit: ContentEdit | null; // The edit that created this version

  @Column({ nullable: true })
  relatedEditId: string | null;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'createdByUserId' })
  createdBy: User | null; // User who submitted the edit

  @Column({ nullable: true })
  createdByUserId: string | null;

  @Column({ type: 'int' })
  versionNumber: number; // Sequential version number (1, 2, 3, ...)

  // Full snapshot of content item at this version
  @Column({ type: 'jsonb' })
  contentSnapshot: {
    title: string;
    content: string;
    richContent?: any;
    media?: {
      videoUrl?: string;
      imageUrl?: string;
      imageUrls?: string[];
    };
    quizData?: {
      question?: string;
      options?: string[];
      correctAnswer?: number;
      explanation?: string;
    };
    format?: string;
    difficulty?: string;
    rewards?: {
      xp?: number;
      coin?: number;
    };
  };

  @Column({ type: 'text', nullable: true })
  description: string; // Description of what changed in this version

  @Column({ type: 'boolean', default: false })
  isCurrent: boolean; // Whether this is the current active version

  @CreateDateColumn()
  createdAt: Date;
}

