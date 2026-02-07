import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { ContentItem } from '../../content-items/entities/content-item.entity';
import { LearningNode } from '../../learning-nodes/entities/learning-node.entity';

export interface QuizQuestion {
  id: string;
  question: string;
  options: { A: string; B: string; C: string; D: string };
  correctAnswer: 'A' | 'B' | 'C' | 'D';
  explanation: string;
  category: string;
}

@Entity('quizzes')
export class Quiz {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  // Quiz can be for a specific content item (concept/example)
  @Column({ nullable: true })
  contentItemId: string;

  @ManyToOne(() => ContentItem, { nullable: true, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'contentItemId' })
  contentItem: ContentItem;

  // Or for a learning node (boss quiz)
  @Column({ nullable: true })
  learningNodeId: string;

  @ManyToOne(() => LearningNode, { nullable: true, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'learningNodeId' })
  learningNode: LearningNode;

  // Quiz type: 'lesson' for content items, 'boss' for learning nodes
  @Column({ default: 'lesson' })
  type: 'lesson' | 'boss';

  // Content type: 'concept' or 'example' (for lesson quizzes)
  @Column({ nullable: true })
  contentType: 'concept' | 'example';

  // Quiz questions stored as JSON
  @Column('jsonb')
  questions: QuizQuestion[];

  // Number of questions
  @Column({ default: 0 })
  totalQuestions: number;

  // Passing score percentage (70 for lesson, 80 for boss)
  @Column({ default: 70 })
  passingScore: number;

  // Title for display
  @Column({ nullable: true })
  title: string;

  // Generation metadata
  @Column({ nullable: true })
  generatedAt: Date;

  @Column({ nullable: true })
  generationModel: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
