import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  UpdateDateColumn,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Subject } from '../../subjects/entities/subject.entity';

export enum TestStatus {
  NOT_STARTED = 'not_started',
  IN_PROGRESS = 'in_progress',
  COMPLETED = 'completed',
}

export enum DifficultyLevel {
  BEGINNER = 'beginner',
  INTERMEDIATE = 'intermediate',
  ADVANCED = 'advanced',
}

@Entity('placement_tests')
export class PlacementTest {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  userId: string;

  @ManyToOne(() => Subject, { nullable: true })
  @JoinColumn({ name: 'subjectId' })
  subject: Subject;

  @Column({ nullable: true })
  subjectId: string;

  @Column({ default: TestStatus.NOT_STARTED })
  status: TestStatus;

  @Column({ type: 'jsonb', default: [] })
  questions: Array<{
    questionId: string;
    question: string;
    options: string[];
    correctAnswer: number;
    difficulty: DifficultyLevel;
    userAnswer?: number;
    isCorrect?: boolean;
    answeredAt?: Date;
  }>;

  @Column({ type: 'int', default: 0 })
  currentQuestionIndex: number;

  @Column({ type: 'int', nullable: true })
  score: number; // 0-100

  @Column({ nullable: true })
  level: DifficultyLevel; // Kết quả đánh giá trình độ

  @Column({ type: 'jsonb', nullable: true })
  adaptiveData: {
    currentDifficulty: DifficultyLevel;
    correctStreak: number;
    incorrectStreak: number;
    totalCorrect: number;
    totalAnswered: number;
  };

  @Column({ type: 'timestamp', nullable: true })
  startedAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  completedAt: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

