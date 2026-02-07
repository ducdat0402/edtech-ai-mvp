import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  UpdateDateColumn,
  JoinColumn,
} from 'typeorm';
import { ContentItem } from '../../content-items/entities/content-item.entity';
import { User } from '../../users/entities/user.entity';

export enum ContentEditStatus {
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected',
}

export enum ContentEditType {
  ADD_VIDEO = 'add_video',
  ADD_IMAGE = 'add_image',
  ADD_TEXT = 'add_text',
  UPDATE_CONTENT = 'update_content',
}

@Entity('content_edits')
export class ContentEdit {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => ContentItem)
  @JoinColumn({ name: 'contentItemId' })
  contentItem: ContentItem;

  @Column()
  contentItemId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  userId: string;

  @Column({
    type: 'enum',
    enum: ContentEditType,
  })
  type: ContentEditType;

  @Column({
    type: 'enum',
    enum: ContentEditStatus,
    default: ContentEditStatus.PENDING,
  })
  status: ContentEditStatus;

  @Column({ type: 'jsonb', nullable: true })
  media: {
    videoUrl?: string;
    imageUrl?: string; // Single image (legacy)
    imageUrls?: string[]; // Multiple images (new)
    caption?: string;
  };

  @Column({ type: 'text', nullable: true })
  textContent: string; // Plain text (legacy)

  @Column({ type: 'jsonb', nullable: true })
  richContent: any; // Rich text content (JSON from flutter_quill) - detailed version

  // Text variants for 3 complexity levels (Đơn giản, Chi tiết, Chuyên sâu)
  @Column({ type: 'jsonb', nullable: true })
  textVariants: {
    simple?: string; // Đơn giản - plain text
    detailed?: string; // Chi tiết - plain text (default)
    comprehensive?: string; // Chuyên sâu - plain text
    simpleRichContent?: any; // Rich text version for simple
    detailedRichContent?: any; // Rich text version for detailed (same as richContent)
    comprehensiveRichContent?: any; // Rich text version for comprehensive
  };

  @Column({ type: 'text', nullable: true })
  title: string; // Lesson title (for community edit)

  @Column({ type: 'text', nullable: true })
  description: string; // Mô tả về chỉnh sửa này

  @Column({ type: 'jsonb', nullable: true })
  quizData: {
    question?: string;
    options?: string[];
    correctAnswer?: number;
    explanation?: string;
  }; // Quiz data (for quiz content items)

  @Column({ type: 'jsonb', nullable: true })
  originalContentSnapshot: {
    title?: string;
    content?: string;
    richContent?: any;
    textVariants?: {
      simple?: string;
      detailed?: string;
      comprehensive?: string;
      simpleRichContent?: any;
      detailedRichContent?: any;
      comprehensiveRichContent?: any;
    };
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
  }; // Snapshot of content item before this edit is applied

  @Column({ type: 'int', default: 0 })
  upvotes: number;

  @Column({ type: 'int', default: 0 })
  downvotes: number;

  @Column({ type: 'jsonb', default: [] })
  voters: string[]; // User IDs đã vote

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

