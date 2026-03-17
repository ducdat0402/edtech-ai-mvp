import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('weekly_reward_history')
@Index(['userId', 'weekCode'])
@Index(['weekCode', 'rank'])
export class WeeklyRewardHistory {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  userId: string;

  @Column()
  weekCode: string; // ISO week e.g. '2026-W04'

  @Column({ type: 'int' })
  rank: number;

  @Column({ type: 'int' })
  weeklyXp: number;

  @Column({ type: 'int', default: 0 })
  diamondsAwarded: number;

  @Column({ nullable: true })
  badgeCode: string; // null if rank > 3

  @Column({ type: 'boolean', default: false })
  notified: boolean;

  @CreateDateColumn()
  createdAt: Date;
}
