import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  Unique,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { CommunityStatus } from './community-status.entity';

export type CommunityReactionKind = 'like' | 'dislike';

@Entity('community_status_reactions')
@Unique(['statusId', 'userId'])
export class CommunityStatusReaction {
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

  @Column({ type: 'varchar', length: 16 })
  kind: CommunityReactionKind;

  @CreateDateColumn()
  createdAt: Date;
}
