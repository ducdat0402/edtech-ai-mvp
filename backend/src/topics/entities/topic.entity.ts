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
import { Domain } from '../../domains/entities/domain.entity';
import { LearningNode } from '../../learning-nodes/entities/learning-node.entity';

@Entity('topics')
export class Topic {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Domain, (domain) => domain.topics, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'domainId' })
  domain: Domain;

  @Column()
  domainId: string;

  @Column()
  name: string; // "Công thức cơ bản", "Hàm IF/VLOOKUP", etc.

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'int', default: 0 })
  order: number; // Thứ tự trong domain

  @Column({ type: 'varchar', length: 20, nullable: true, default: 'medium' })
  difficulty: 'easy' | 'medium' | 'hard';

  @Column({ type: 'int', default: 0 })
  expReward: number; // EXP nhận được khi hoàn thành topic

  @Column({ type: 'int', default: 0 })
  coinReward: number; // Coin nhận được khi hoàn thành topic

  @Column({ type: 'jsonb', nullable: true })
  metadata: {
    icon?: string;
    color?: string;
  };

  @OneToMany(() => LearningNode, (node) => node.topic)
  nodes: LearningNode[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
