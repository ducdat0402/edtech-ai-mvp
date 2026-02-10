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
import { User } from '../../users/entities/user.entity';
import { LearningNode } from '../../learning-nodes/entities/learning-node.entity';

@Entity('user_progress')
@Index(['userId', 'nodeId'], { unique: true })
export class UserProgress {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  userId: string;

  @ManyToOne(() => LearningNode, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'nodeId' })
  node: LearningNode;

  @Column()
  nodeId: string;

  @Column({ type: 'jsonb', default: {} })
  completedItems: {
    concepts: string[];
    examples: string[];
    hiddenRewards: string[];
    bossQuiz: string[];
  };

  @Column({ type: 'jsonb', default: [] })
  completedLessonTypes: string[]; // e.g. ['image_quiz', 'video']

  @Column({ type: 'float', default: 0 })
  progressPercentage: number; // 0-100

  @Column({ default: false })
  isCompleted: boolean;

  @Column({ type: 'timestamp', nullable: true })
  completedAt: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

