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
import { LearningNode } from '../../learning-nodes/entities/learning-node.entity';

@Entity('lesson_type_contents')
@Index(['nodeId', 'lessonType'], { unique: true })
export class LessonTypeContent {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => LearningNode, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'nodeId' })
  node: LearningNode;

  @Column()
  nodeId: string;

  @Column({
    type: 'varchar',
    length: 20,
  })
  lessonType: 'image_quiz' | 'image_gallery' | 'video' | 'text';

  @Column({ type: 'jsonb' })
  lessonData: Record<string, any>;

  @Column({ type: 'jsonb' })
  endQuiz: {
    questions: Array<{
      question: string;
      options: Array<{ text: string; explanation: string }>;
      correctAnswer: number;
    }>;
    passingScore: number;
  };

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
