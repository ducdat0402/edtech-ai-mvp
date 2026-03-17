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

export enum FriendActivityType {
  LESSON_COMPLETED = 'lesson_completed',
  ACHIEVEMENT_UNLOCKED = 'achievement_unlocked',
  LEVEL_UP = 'level_up',
  STREAK_MILESTONE = 'streak_milestone',
  SUBJECT_COMPLETED = 'subject_completed',
  QUIZ_PERFECT = 'quiz_perfect',
}

@Entity('friend_activities')
@Index(['userId', 'createdAt'])
export class FriendActivity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  userId: string;

  @Column({ type: 'varchar' })
  type: FriendActivityType;

  @Column({ type: 'jsonb', default: {} })
  metadata: Record<string, any>;

  @CreateDateColumn()
  createdAt: Date;
}
