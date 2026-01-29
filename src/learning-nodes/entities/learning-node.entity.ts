

import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToMany,
  CreateDateColumn,
  UpdateDateColumn,
  JoinColumn,
} from 'typeorm';
import { Subject } from '../../subjects/entities/subject.entity';
import { Domain } from '../../domains/entities/domain.entity';
import { ContentItem } from '../../content-items/entities/content-item.entity';

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
  domainId: string | null; // Nullable để backward compatible với data cũ

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

  @OneToMany(() => ContentItem, (item) => item.node)
  contentItems: ContentItem[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

