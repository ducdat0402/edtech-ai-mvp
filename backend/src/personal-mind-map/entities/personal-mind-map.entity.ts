import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Unique,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Subject } from '../../subjects/entities/subject.entity';

export interface PersonalMindMapNode {
  id: string;
  title: string;
  description?: string;
  level: number; // 1 = goal, 2 = milestone, 3 = topic
  parentId?: string;
  position: { x: number; y: number };
  status: 'not_started' | 'in_progress' | 'completed';
  priority: 'high' | 'medium' | 'low';
  estimatedDays?: number;
  metadata?: {
    icon?: string;
    color?: string;
    linkedTopicId?: string; // Link to knowledge graph topic
    linkedLearningNodeId?: string | null; // Link to learning node for actual learning content
    linkedLearningNodeTitle?: string | null; // Title of linked learning node
    hasLearningContent?: boolean; // Whether this topic has associated learning content
    learningNodeType?: 'theory' | 'video' | 'image'; // Type of learning node
  };
}

export interface PersonalMindMapEdge {
  id: string;
  from: string;
  to: string;
  type: 'leads_to' | 'requires' | 'optional';
}

@Entity('personal_mind_maps')
@Unique(['userId', 'subjectId'])
export class PersonalMindMap {
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

  @Column({ type: 'text', nullable: true })
  learningGoal: string; // Mục tiêu học tập của user

  @Column({ type: 'jsonb', default: [] })
  nodes: PersonalMindMapNode[];

  @Column({ type: 'jsonb', default: [] })
  edges: PersonalMindMapEdge[];

  @Column({ type: 'jsonb', nullable: true })
  aiConversationHistory: {
    role: 'user' | 'assistant';
    content: string;
    timestamp: Date;
  }[];

  @Column({ type: 'int', default: 0 })
  completedNodes: number;

  @Column({ type: 'int', default: 0 })
  totalNodes: number;

  @Column({ type: 'float', default: 0 })
  progressPercent: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
