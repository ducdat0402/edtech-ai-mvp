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
    imageUrl?: string;
    caption?: string;
  };

  @Column({ type: 'text', nullable: true })
  textContent: string;

  @Column({ type: 'text', nullable: true })
  description: string; // Mô tả về chỉnh sửa này

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

