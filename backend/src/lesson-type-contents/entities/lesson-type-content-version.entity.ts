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

  /**
   * Người được ghi nhận trên node (learning_nodes.contributorId) tại thời điểm lưu bản —
   * tức ghi công cho *nội dung* của snapshot này.
   */
  @Column({ type: 'uuid', nullable: true })
  contentCreditedContributorId: string | null;

  /**
   * Người gửi bản chỉnh sửa đã duyệt — thao tác này kích hoạt lưu snapshot (bản cũ).
   */
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
