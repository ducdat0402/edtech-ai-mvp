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
import { LearningNode } from '../../learning-nodes/entities/learning-node.entity';

@Entity('domains')
export class Domain {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Subject, (subject) => subject.domains)
  @JoinColumn({ name: 'subjectId' })
  subject: Subject;

  @Column()
  subjectId: string;

  @Column()
  name: string; // "Cơ bản về Excel", "Công thức và Hàm", etc.

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'int', default: 0 })
  order: number; // Thứ tự trong subject

  @Column({ type: 'jsonb', nullable: true })
  metadata: {
    icon?: string;
    color?: string;
    estimatedDays?: number;
    topics?: string[]; // Các chủ đề trong domain này
  };

  @OneToMany(() => LearningNode, (node) => node.domain)
  nodes: LearningNode[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

