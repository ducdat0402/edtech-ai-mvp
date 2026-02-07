import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  UpdateDateColumn,
  JoinColumn,
  Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { SkillNode } from './skill-node.entity';
import { NodeStatus } from './node-status.enum';

@Entity('user_skill_progress')
@Index(['userId', 'skillNodeId'], { unique: true })
export class UserSkillProgress {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  userId: string;

  @ManyToOne(() => SkillNode, (node) => node.userProgress)
  @JoinColumn({ name: 'skillNodeId' })
  skillNode: SkillNode;

  @Column()
  skillNodeId: string;

  @Column({ type: 'enum', enum: NodeStatus, default: NodeStatus.LOCKED })
  status: NodeStatus;

  @Column({ type: 'int', default: 0 })
  progress: number; // 0-100 (percentage)

  @Column({ type: 'int', default: 0 })
  xpEarned: number; // XP đã kiếm được từ node này

  @Column({ type: 'int', default: 0 })
  coinsEarned: number; // Coins đã kiếm được

  @Column({ type: 'timestamp', nullable: true })
  unlockedAt: Date; // Thời gian unlock

  @Column({ type: 'timestamp', nullable: true })
  startedAt: Date; // Thời gian bắt đầu học

  @Column({ type: 'timestamp', nullable: true })
  completedAt: Date; // Thời gian hoàn thành

  @Column({ type: 'jsonb', nullable: true })
  progressData: {
    completedItems?: string[]; // Content item IDs đã hoàn thành
    quizScore?: number; // Điểm quiz (nếu có)
    attempts?: number; // Số lần thử
    bestScore?: number; // Điểm cao nhất
  };

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

