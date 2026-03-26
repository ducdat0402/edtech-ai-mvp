import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';

@Entity('self_leadership_checkins')
@Index(['userId', 'weekStart'])
@Index(['userId', 'createdAt'])
export class SelfLeadershipCheckin {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  userId: string;

  @Column({ type: 'uuid', nullable: true })
  nodeId: string | null;

  @Column({ type: 'varchar', nullable: true })
  lessonType: string | null;

  @Column({ type: 'date' })
  weekStart: string;

  @Column({ type: 'boolean' })
  followedPlan: boolean;

  @Column({ type: 'varchar', nullable: true })
  deviationReason: string | null;

  @Column({ type: 'varchar', nullable: true })
  nextAction: string | null;

  @CreateDateColumn()
  createdAt: Date;
}

