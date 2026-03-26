import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';

@Entity('learning_communication_attempts')
@Index(['userId', 'createdAt'])
@Index(['userId', 'nodeId', 'lessonType'])
export class LearningCommunicationAttempt {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  userId: string;

  @Column({ type: 'uuid' })
  nodeId: string;

  @Column({ type: 'varchar', nullable: true })
  lessonType: string | null;

  @Column({ type: 'text' })
  responseText: string;

  @Column({ type: 'jsonb', default: {} })
  aiScores: {
    clarity: number;
    structure: number;
    coverage: number;
    audienceFit: number;
    conciseness: number;
  };

  @Column({ type: 'text', nullable: true })
  feedbackShort: string | null;

  @Column({ type: 'int' })
  totalScore: number;

  @CreateDateColumn()
  createdAt: Date;
}

