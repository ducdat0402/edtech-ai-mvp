

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
import { Domain } from '../../domains/entities/domain.entity';
import { Topic } from '../../topics/entities/topic.entity';

@Entity('learning_nodes')
export class LearningNode {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Subject, (subject) => subject.nodes)
  @JoinColumn({ name: 'subjectId' })
  subject: Subject;

  @Column()
  subjectId: string;

  @ManyToOne(() => Domain, (domain) => domain.nodes, { nullable: true })
  @JoinColumn({ name: 'domainId' })
  domain: Domain | null;

  @Column({ nullable: true })
  domainId: string | null;

  @ManyToOne(() => Topic, (topic) => topic.nodes, { nullable: true })
  @JoinColumn({ name: 'topicId' })
  topic: Topic | null;

  @Column({ nullable: true })
  topicId: string | null;

  @Column()
  title: string; // "Vệ Sĩ Mật Khẩu"

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'int', default: 0 })
  order: number; // Thứ tự trong cây

  @Column({ type: 'jsonb', default: [] })
  prerequisites: string[]; // Node IDs cần hoàn thành trước

  @Column({ type: 'jsonb' })
  contentStructure: {
    concepts: number; // 4
    examples: number; // 10
    hiddenRewards: number; // 5
    bossQuiz: number; // 1
  };

  @Column({ type: 'jsonb', nullable: true })
  metadata: {
    icon?: string;
    position?: { x: number; y: number }; // Vị trí trên bản đồ
  };

  @Column({
    type: 'varchar',
    length: 20,
    nullable: true,
    default: 'theory',
  })
  type: 'theory' | 'practice' | 'assessment'; // Phân loại bài học: lý thuyết, thực hành, đánh giá

  @Column({
    type: 'varchar',
    length: 20,
    nullable: true,
    default: 'medium',
  })
  difficulty: 'easy' | 'medium' | 'hard'; // Độ khó: dễ, trung bình, khó

  @Column({ type: 'int', default: 0 })
  expReward: number; // EXP nhận được khi hoàn thành bài học

  @Column({ type: 'int', default: 0 })
  coinReward: number; // Coin nhận được khi hoàn thành bài học

  // === NEW: 4 Lesson Types ===
  @Column({
    type: 'varchar',
    length: 20,
    nullable: true,
    default: null,
  })
  lessonType: 'image_quiz' | 'image_gallery' | 'video' | 'text' | null;

  @Column({ type: 'jsonb', nullable: true, default: null })
  lessonData: Record<string, any> | null;
  // image_quiz: { slides: [{ imageUrl, question, options: [{text, explanation}], correctAnswer, hint }] }
  // image_gallery: { images: [{ url, description }] }
  // video: { videoUrl, summary, keyPoints: [{title, description?, timestamp?}], keywords: [] }
  // text: { sections: [{title, content, richContent?}], inlineQuizzes: [{afterSectionIndex, question, options, correctAnswer}], summary, learningObjectives: [] }

  @Column({ type: 'jsonb', nullable: true, default: null })
  endQuiz: {
    questions: Array<{
      question: string;
      options: Array<{ text: string; explanation: string }>;
      correctAnswer: number;
    }>;
    passingScore: number;
  } | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

