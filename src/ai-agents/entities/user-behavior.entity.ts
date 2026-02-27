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
import { LearningNode } from '../../learning-nodes/entities/learning-node.entity';

/**
 * Track user behavior for DRL and ITS
 * Stores detailed metrics about user interactions with learning content
 */
@Entity('user_behaviors')
@Index(['userId', 'nodeId', 'createdAt'])
export class UserBehavior {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  userId: string;

  @ManyToOne(() => LearningNode, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'nodeId' })
  node: LearningNode;

  @Column()
  nodeId: string;

  @Column({ type: 'varchar', nullable: true })
  contentItemId: string; // Specific content item (concept, example, quiz)

  @Column({ type: 'varchar' })
  action: string; // 'view', 'complete', 'attempt_quiz', 'error', 'hint_request', 'skip'

  @Column({ type: 'jsonb', default: {} })
  metrics: {
    // Time metrics
    timeSpent?: number; // seconds
    completionTime?: number; // seconds
    timeToFirstInteraction?: number; // seconds

    // Performance metrics
    attempts?: number; // Number of attempts (for quizzes)
    errors?: number; // Number of errors
    correctAnswers?: number; // Number of correct answers
    accuracy?: number; // 0-1 ratio

    // Engagement metrics
    hintsUsed?: number; // Number of hints requested
    skipped?: boolean; // Whether content was skipped
    masteryLevel?: number; // 0-1, calculated mastery

    // Context
    difficulty?: 'easy' | 'medium' | 'hard' | 'expert';
    contentType?: 'concept' | 'example' | 'quiz' | 'video' | 'image';
    previousMastery?: number; // Mastery level before this interaction
  };

  @Column({ type: 'jsonb', nullable: true })
  context: {
    // Learning path context
    pathPosition?: number; // Position in learning path
    prerequisitesCompleted?: string[]; // IDs of completed prerequisite nodes
    relatedNodes?: string[]; // Related nodes user has seen

    // Session context
    sessionId?: string;
    sessionStartTime?: Date;
    consecutiveErrors?: number; // Errors in a row
    consecutiveSuccesses?: number; // Successes in a row

    // Adaptive context
    suggestedDifficulty?: 'easy' | 'medium' | 'hard' | 'expert';
    adaptiveHint?: string; // Hint provided by ITS
    pathOptimization?: any; // DRL path optimization data
  };

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

