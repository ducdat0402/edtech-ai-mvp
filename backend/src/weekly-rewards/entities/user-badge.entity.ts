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

@Entity('user_badges')
@Index(['userId', 'code'])
export class UserBadge {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  userId: string;

  @Column()
  code: string; // e.g. 'top_1_week', 'top_2_week', 'top_3_week'

  @Column()
  name: string; // e.g. 'Top 1 tuần'

  @Column({ nullable: true })
  iconUrl: string;

  @Column({ type: 'jsonb', nullable: true })
  metadata: Record<string, any>; // { week: '2026-W04', rank: 1, xp: 5000 }

  @CreateDateColumn()
  awardedAt: Date;
}
