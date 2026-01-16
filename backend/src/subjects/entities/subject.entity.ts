import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { LearningNode } from '../../learning-nodes/entities/learning-node.entity';
import { Domain } from '../../domains/entities/domain.entity';

@Entity('subjects')
export class Subject {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string; // "IC3 GS6", "Marketing", etc.

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ default: 'explorer' })
  track: 'explorer' | 'scholar'; // Nhánh nào

  @Column({ type: 'int', nullable: true })
  price: number; // Giá khóa học Scholar (VND)

  @Column({ type: 'jsonb', nullable: true })
  metadata: {
    icon?: string;
    color?: string;
    estimatedDays?: number;
  };

  @Column({ type: 'jsonb', nullable: true })
  unlockConditions: {
    minCoin?: number; // Số coin tối thiểu cần để unlock
    minShards?: Record<string, number>; // Shards cần thiết
  };

  @OneToMany(() => LearningNode, (node) => node.subject)
  nodes: LearningNode[];

  @OneToMany(() => Domain, (domain) => domain.subject)
  domains: Domain[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

