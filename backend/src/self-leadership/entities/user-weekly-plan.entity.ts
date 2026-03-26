import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';

@Entity('user_weekly_plans')
@Index(['userId', 'weekStart'], { unique: true })
export class UserWeeklyPlan {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  userId: string;

  @Column({ type: 'date' })
  weekStart: string;

  @Column({ type: 'int', default: 3 })
  targetSessions: number;

  @Column({ type: 'int', default: 3 })
  targetLessons: number;

  @Column({ type: 'int', array: true, default: [1, 3, 5] })
  plannedDays: number[];

  @Column({ type: 'varchar', default: 'active' })
  status: 'active' | 'completed';

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

