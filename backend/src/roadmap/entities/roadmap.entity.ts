import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToMany,
  CreateDateColumn,
  UpdateDateColumn,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Subject } from '../../subjects/entities/subject.entity';
import { RoadmapDay } from './roadmap-day.entity';

export enum RoadmapStatus {
  ACTIVE = 'active',
  COMPLETED = 'completed',
  PAUSED = 'paused',
}

@Entity('roadmaps')
export class Roadmap {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  userId: string;

  @ManyToOne(() => Subject)
  @JoinColumn({ name: 'subjectId' })
  subject: Subject;

  @Column()
  subjectId: string;

  @Column({ default: RoadmapStatus.ACTIVE })
  status: RoadmapStatus;

  @Column({ type: 'int', default: 30 })
  totalDays: number; // 30 ngày

  @Column({ type: 'int', default: 0 })
  currentDay: number; // Ngày hiện tại (1-30)

  @Column({ type: 'date' })
  startDate: Date;

  @Column({ type: 'date', nullable: true })
  endDate: Date;

  @Column({ type: 'jsonb', nullable: true })
  metadata: {
    level: string; // beginner, intermediate, advanced
    interests?: string[];
    learningGoals?: string;
    estimatedHoursPerDay?: number;
  };

  @OneToMany(() => RoadmapDay, (day) => day.roadmap)
  days: RoadmapDay[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

