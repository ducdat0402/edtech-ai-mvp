import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';

/**
 * Mỗi lần user nộp end-quiz (legacy node hoặc theo lessonType).
 * Dùng cho Memory v2: delayed recall, stability, first-try.
 */
@Entity('learning_quiz_attempts')
@Index(['userId', 'createdAt'])
@Index(['userId', 'nodeId', 'lessonType'])
export class LearningQuizAttempt {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string;

  @Column()
  nodeId: string;

  /** null = end quiz gắn trực tiếp vào node (legacy) */
  @Column({ type: 'varchar', length: 32, nullable: true })
  lessonType: string | null;

  @Column({ type: 'int' })
  score: number;

  @Column({ default: false })
  passed: boolean;

  @Column({ type: 'int' })
  totalQuestions: number;

  @Column({ type: 'int' })
  correctCount: number;

  @CreateDateColumn()
  createdAt: Date;
}
