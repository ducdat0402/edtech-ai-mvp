import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  JoinColumn,
  Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum RewardSource {
  CONTENT_ITEM = 'content_item',
  QUEST = 'quest',
  SKILL_NODE = 'skill_node',
  DAILY_STREAK = 'daily_streak',
  BONUS = 'bonus',
}

@Entity('reward_transactions')
@Index(['userId', 'createdAt'])
export class RewardTransaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  userId: string;

  @Column({
    type: 'enum',
    enum: RewardSource,
  })
  source: RewardSource;

  @Column({ nullable: true })
  sourceId: string; // ID of the source (contentItemId, questId, etc.)

  @Column({ nullable: true })
  sourceName: string; // Human-readable name (e.g., "VLOOKUP Concept", "Daily Quest")

  @Column({ type: 'int', default: 0 })
  xp: number;

  @Column({ type: 'int', default: 0 })
  coins: number;

  @Column({ type: 'jsonb', nullable: true })
  shards: Record<string, number>; // { "ai-shard": 1 }

  @CreateDateColumn()
  createdAt: Date;
}

