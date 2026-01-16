import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  UpdateDateColumn,
  JoinColumn,
} from 'typeorm';
import { LearningNode } from '../../learning-nodes/entities/learning-node.entity';

@Entity('content_items')
export class ContentItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => LearningNode, (node) => node.contentItems)
  @JoinColumn({ name: 'nodeId' })
  node: LearningNode;

  @Column()
  nodeId: string;

  @Column()
  type: 'concept' | 'example' | 'hidden_reward' | 'boss_quiz';

  @Column({
    type: 'varchar',
    length: 20,
    nullable: true,
    default: null,
  })
  format: 'video' | 'image' | 'mixed' | 'quiz' | 'text' | null; // Content format classification

  @Column({
    type: 'varchar',
    length: 20,
    nullable: true,
    default: 'medium',
  })
  difficulty: 'easy' | 'medium' | 'hard' | 'expert'; // Difficulty level

  @Column()
  title: string;

  @Column({ type: 'text', nullable: true })
  content: string; // JSON hoặc markdown

  @Column({ type: 'jsonb', nullable: true })
  richContent: any; // Rich text content (JSON from flutter_quill)

  @Column({ type: 'jsonb', nullable: true })
  media: {
    videoUrl?: string;
    imageUrl?: string;
    imageUrls?: string[]; // Multiple images
    interactiveUrl?: string;
  };

  @Column({ type: 'int', default: 0 })
  order: number;

  @Column({ type: 'jsonb', nullable: true })
  rewards: {
    xp?: number;
    coin?: number;
    shard?: string; // Shard type ID
    shardAmount?: number;
  };

  @Column({ type: 'jsonb', nullable: true })
  quizData: {
    question?: string;
    options?: string[];
    correctAnswer?: number;
    explanation?: string;
  };

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

