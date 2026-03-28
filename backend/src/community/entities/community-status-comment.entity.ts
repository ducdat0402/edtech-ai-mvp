import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { CommunityStatus } from './community-status.entity';

@Entity('community_status_comments')
export class CommunityStatusComment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column('uuid')
  statusId: string;

  @ManyToOne(() => CommunityStatus, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'statusId' })
  status: CommunityStatus;

  @Column('uuid')
  userId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column({ type: 'text' })
  content: string;

  @CreateDateColumn()
  createdAt: Date;
}
