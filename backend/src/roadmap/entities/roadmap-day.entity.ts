import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  UpdateDateColumn,
  JoinColumn,
  Index,
} from 'typeorm';
import { Roadmap } from './roadmap.entity';
import { LearningNode } from '../../learning-nodes/entities/learning-node.entity';

export enum DayStatus {
  PENDING = 'pending',
  IN_PROGRESS = 'in_progress',
  COMPLETED = 'completed',
  SKIPPED = 'skipped',
}

@Entity('roadmap_days')
@Index(['roadmapId', 'dayNumber'], { unique: true })
export class RoadmapDay {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Roadmap, (roadmap) => roadmap.days)
  @JoinColumn({ name: 'roadmapId' })
  roadmap: Roadmap;

  @Column()
  roadmapId: string;

  @Column({ type: 'int' })
  dayNumber: number; // 1-30

  @Column({ type: 'date' })
  scheduledDate: Date;

  @Column({ default: DayStatus.PENDING })
  status: DayStatus;

  @ManyToOne(() => LearningNode, { nullable: true })
  @JoinColumn({ name: 'nodeId' })
  node: LearningNode;

  @Column({ nullable: true })
  nodeId: string; // Node học trong ngày này

  @Column({ type: 'jsonb', nullable: true })
  content: {
    title: string;
    description: string;
    estimatedMinutes: number;
    type: 'video' | 'quiz' | 'simulation' | 'review';
    reviewItems?: string[]; // Node IDs cần review (spaced repetition)
  };

  @Column({ type: 'timestamp', nullable: true })
  completedAt: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

