import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  UpdateDateColumn,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Subject } from '../../subjects/entities/subject.entity';

export enum AdaptiveTestStatus {
  IN_PROGRESS = 'in_progress',
  COMPLETED = 'completed',
  ABANDONED = 'abandoned',
}

export enum DifficultyLevel {
  BEGINNER = 'beginner',
  INTERMEDIATE = 'intermediate',
  ADVANCED = 'advanced',
}

export interface TopicAssessment {
  topicId: string;
  topicName: string;
  domainId: string;
  domainName: string;
  nodesTested: string[];
  nodesCorrect: string[];
  nodesIncorrect: string[];
  level: DifficultyLevel;
  score: number; // 0-100
}

export interface QuestionResponse {
  questionId: string;
  nodeId: string;
  topicId: string;
  domainId: string;
  question: string;
  options: string[];
  correctAnswer: number;
  userAnswer: number;
  isCorrect: boolean;
  difficulty: DifficultyLevel;
  answeredAt: Date;
  timeSpentMs?: number;
}

@Entity('adaptive_tests')
export class AdaptiveTest {
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

  @Column({ default: AdaptiveTestStatus.IN_PROGRESS })
  status: AdaptiveTestStatus;

  // Current state
  @Column({ nullable: true })
  currentDomainId: string;

  @Column({ nullable: true })
  currentTopicId: string;

  @Column({ nullable: true })
  currentNodeId: string;

  @Column({ type: 'enum', enum: DifficultyLevel, default: DifficultyLevel.INTERMEDIATE })
  currentDifficulty: DifficultyLevel;

  // Tracking which domains/topics/nodes to test
  @Column({ type: 'jsonb', default: [] })
  domainsToTest: string[];

  @Column({ type: 'jsonb', default: [] })
  topicsToTest: string[];

  @Column({ type: 'jsonb', default: [] })
  nodesToTest: string[]; // Sample nodes for current topic

  @Column({ type: 'jsonb', default: [] })
  testedDomains: string[];

  @Column({ type: 'jsonb', default: [] })
  testedTopics: string[];

  @Column({ type: 'jsonb', default: [] })
  testedNodes: string[];

  // All responses
  @Column({ type: 'jsonb', default: [] })
  responses: QuestionResponse[];

  // Assessment results per topic
  @Column({ type: 'jsonb', default: [] })
  topicAssessments: TopicAssessment[];

  // Estimated total questions (for progress tracking)
  @Column({ type: 'int', default: 20 })
  estimatedQuestions: number;

  // Adaptive tracking
  @Column({ type: 'jsonb', nullable: true })
  adaptiveState: {
    consecutiveCorrect: number;
    consecutiveIncorrect: number;
    totalCorrect: number;
    totalAnswered: number;
    currentTopicCorrect: number;
    currentTopicAnswered: number;
    difficultyHistory: DifficultyLevel[];
  };

  // Summary results
  @Column({ type: 'int', nullable: true })
  score: number; // 0-100

  @Column({ type: 'enum', enum: DifficultyLevel, nullable: true })
  overallLevel: DifficultyLevel;

  @Column({ type: 'jsonb', nullable: true })
  strongAreas: string[]; // Topic names

  @Column({ type: 'jsonb', nullable: true })
  weakAreas: string[]; // Topic names

  @Column({ type: 'jsonb', nullable: true })
  recommendedPath: string[]; // Node IDs in recommended order

  @Column({ type: 'timestamp', nullable: true })
  startedAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  completedAt: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
