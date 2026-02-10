import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  JoinColumn,
  Index,
} from 'typeorm';
import { LearningNode } from '../../learning-nodes/entities/learning-node.entity';

/**
 * Stores version history for lesson type content.
 * Each time content is edited and approved, the old version is saved here.
 */
@Entity('lesson_type_content_versions')
@Index(['nodeId', 'lessonType'])
export class LessonTypeContentVersion {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => LearningNode, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'nodeId' })
  node: LearningNode;

  @Column()
  nodeId: string;

  @Column({ type: 'varchar', length: 20 })
  lessonType: 'image_quiz' | 'image_gallery' | 'video' | 'text';

  @Column({ type: 'int' })
  version: number;

  @Column({ type: 'jsonb' })
  lessonData: Record<string, any>;

  @Column({ type: 'jsonb', nullable: true })
  endQuiz: Record<string, any> | null;

  @Column({ nullable: true })
  contributorId: string;

  @Column({ nullable: true })
  title: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'text', nullable: true })
  note: string;

  @CreateDateColumn()
  createdAt: Date;
}
