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
import { Topic } from '../../topics/entities/topic.entity';

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

  @Column({ type: 'varchar', length: 20, nullable: true, default: 'medium' })
  difficulty: 'easy' | 'medium' | 'hard';

  @Column({ type: 'int', default: 0 })
  expReward: number; // EXP nhận được khi hoàn thành domain

  @Column({ type: 'int', default: 0 })
  coinReward: number; // Coin nhận được khi hoàn thành domain

  @Column({ type: 'jsonb', nullable: true })
  metadata: {
    icon?: string;
    color?: string;
    estimatedDays?: number;
  };

  @OneToMany(() => Topic, (topic) => topic.domain)
  topics: Topic[];

  @OneToMany(() => LearningNode, (node) => node.domain)
  nodes: LearningNode[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

