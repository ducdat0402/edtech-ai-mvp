import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToMany,
  CreateDateColumn,
  UpdateDateColumn,
  JoinColumn,
  Index,
} from 'typeorm';
import { SkillTree } from './skill-tree.entity';
import { LearningNode } from '../../learning-nodes/entities/learning-node.entity';
import { UserSkillProgress } from './user-skill-progress.entity';

export enum NodeType {
  SKILL = 'skill', // Kỹ năng chính
  CONCEPT = 'concept', // Khái niệm
  PRACTICE = 'practice', // Thực hành
  BOSS = 'boss', // Boss node (quiz cuối)
  REWARD = 'reward', // Reward node
}

@Entity('skill_nodes')
@Index(['skillTreeId', 'order'], { unique: true })
export class SkillNode {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => SkillTree, (tree) => tree.nodes)
  @JoinColumn({ name: 'skillTreeId' })
  skillTree: SkillTree;

  @Column()
  skillTreeId: string;

  @ManyToOne(() => LearningNode, { nullable: true })
  @JoinColumn({ name: 'learningNodeId' })
  learningNode: LearningNode;

  @Column({ nullable: true })
  learningNodeId: string; // Link đến LearningNode để học

  @Column()
  title: string; // "Vệ Sĩ Mật Khẩu"

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'int' })
  order: number; // Thứ tự trong tree (0 = root node)

  @Column({ type: 'jsonb', default: [] })
  prerequisites: string[]; // SkillNode IDs cần hoàn thành trước

  @Column({ type: 'jsonb', default: [] })
  children: string[]; // SkillNode IDs là children (nodes tiếp theo)

  @Column({ type: 'enum', enum: NodeType, default: NodeType.SKILL })
  type: NodeType;

  @Column({ type: 'int', default: 0 })
  requiredXP: number; // XP cần để unlock (nếu có)

  @Column({ type: 'int', default: 0 })
  rewardXP: number; // XP nhận được khi hoàn thành

  @Column({ type: 'int', default: 0 })
  rewardCoins: number; // Coins nhận được khi hoàn thành

  @Column({ type: 'jsonb', nullable: true })
  unlockConditions: {
    prerequisites?: string[]; // Node IDs cần complete
    minXP?: number; // XP tối thiểu
    minLevel?: string; // Level tối thiểu (beginner/intermediate/advanced)
    customConditions?: Record<string, any>; // Điều kiện tùy chỉnh
  };

  @Column({ type: 'jsonb', nullable: true })
  position: {
    x: number; // Vị trí X trên tree (0-100)
    y: number; // Vị trí Y trên tree (0-100)
    tier: number; // Tier trong tree (0 = root, 1, 2, 3...)
  };

  @Column({ type: 'jsonb', nullable: true })
  visual: {
    icon?: string; // Icon name
    color?: string; // Màu sắc
    size?: 'small' | 'medium' | 'large'; // Kích thước
    glow?: boolean; // Có hiệu ứng glow không
  };

  @Column({ type: 'jsonb', nullable: true })
  metadata: {
    difficulty?: string; // beginner, intermediate, advanced
    estimatedMinutes?: number; // Thời gian ước tính
    tags?: string[]; // Tags
  };

  @OneToMany(() => UserSkillProgress, (progress) => progress.skillNode)
  userProgress: UserSkillProgress[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

