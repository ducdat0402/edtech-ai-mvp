import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  UpdateDateColumn,
  JoinColumn,
} from 'typeorm';
import { Subject } from '../../subjects/entities/subject.entity';
import { DifficultyLevel } from './placement-test.entity';

@Entity('questions')
export class Question {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Subject, { nullable: true })
  @JoinColumn({ name: 'subjectId' })
  subject: Subject;

  @Column({ nullable: true })
  subjectId: string; // null = general question

  @Column()
  question: string;

  @Column({ type: 'jsonb' })
  options: string[]; // Array of answer options

  @Column({ type: 'int' })
  correctAnswer: number; // Index of correct answer

  @Column({ default: DifficultyLevel.BEGINNER })
  difficulty: DifficultyLevel;

  @Column({ type: 'text', nullable: true })
  explanation: string; // Giải thích đáp án

  @Column({ type: 'jsonb', nullable: true })
  metadata: {
    category?: string;
    tags?: string[];
  };

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

