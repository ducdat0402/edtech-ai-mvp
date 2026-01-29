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
import { User } from '../../users/entities/user.entity';
import { Subject } from '../../subjects/entities/subject.entity';
import { SkillNode } from './skill-node.entity';

export enum SkillTreeStatus {
  ACTIVE = 'active',
  COMPLETED = 'completed',
  LOCKED = 'locked',
}

@Entity('skill_trees')
export class SkillTree {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  userId: string;

  @ManyToOne(() => Subject)
  @JoinColumn({ name: 'subjectId' })
  subject: Subject;

  @Column()
  subjectId: string;

  @Column({ default: SkillTreeStatus.ACTIVE })
  status: SkillTreeStatus;

  @Column({ type: 'int', default: 0 })
  totalNodes: number; // Tổng số nodes trong tree

  @Column({ type: 'int', default: 0 })
  unlockedNodes: number; // Số nodes đã unlock

  @Column({ type: 'int', default: 0 })
  completedNodes: number; // Số nodes đã hoàn thành

  @Column({ type: 'int', default: 0 })
  totalXP: number; // Tổng XP đã kiếm được từ tree này

  @Column({ type: 'jsonb', nullable: true })
  metadata: {
    level: string; // beginner, intermediate, advanced (từ placement test)
    startingLevel?: string; // Level khi bắt đầu
    completionPercentage?: number; // % hoàn thành
    lastUnlockedAt?: Date; // Thời gian unlock node cuối cùng
  };

  @OneToMany(() => SkillNode, (node) => node.skillTree)
  nodes: SkillNode[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

