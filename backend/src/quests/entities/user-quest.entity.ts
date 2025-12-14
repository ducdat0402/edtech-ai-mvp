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
import { Quest, QuestStatus } from './quest.entity';

@Entity('user_quests')
@Index(['userId', 'questId', 'date'], { unique: true })
export class UserQuest {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  userId: string;

  @ManyToOne(() => Quest)
  @JoinColumn({ name: 'questId' })
  quest: Quest;

  @Column()
  questId: string;

  @Column({ type: 'date' })
  date: Date; // Date of the quest (for daily quests)

  @Column({ default: QuestStatus.ACTIVE })
  status: QuestStatus;

  @Column({ type: 'int', default: 0 })
  progress: number; // Current progress towards target

  @Column({ type: 'timestamp', nullable: true })
  completedAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  claimedAt: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

