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

export enum EditHistoryAction {
  CREATE = 'create',
  UPDATE = 'update',
  APPROVE = 'approve',
  REJECT = 'reject',
  REMOVE = 'remove',
  SUBMIT = 'submit',
}

@Entity('edit_history')
export class EditHistory {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => ContentItem, { nullable: true })
  @JoinColumn({ name: 'contentItemId' })
  contentItem: ContentItem | null;

  @Column({ nullable: true })
  contentItemId: string | null;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  userId: string;

  @Column({
    type: 'varchar',
    length: 50,
  })
  action: EditHistoryAction;

  @Column({ type: 'text', nullable: true })
  description: string; // Human-readable description of the change

  @Column({ type: 'jsonb', nullable: true })
  changes: {
    field?: string;
    oldValue?: any;
    newValue?: any;
    [key: string]: any;
  } | null; // Snapshot of changes

  @Column({ type: 'jsonb', nullable: true })
  previousState: Record<string, any> | null; // Full snapshot before change

  @Column({ type: 'jsonb', nullable: true })
  newState: Record<string, any> | null; // Full snapshot after change

  @Column({ type: 'varchar', length: 50, nullable: true })
  relatedEditId: string | null; // ID of ContentEdit if this is related to a community edit

  @CreateDateColumn()
  createdAt: Date;
}

