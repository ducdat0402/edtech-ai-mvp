import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  VersionColumn,
  OneToOne,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('user_currencies')
export class UserCurrency {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @OneToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column({ unique: true })
  userId: string;

  @Column({ type: 'int', default: 0 })
  coins: number; // Kim cương (diamonds)

  @Column({ type: 'int', default: 0 })
  xp: number; // Total experience points

  @Column({ type: 'int', default: 1 })
  level: number; // Current level (starts at 1)

  @Column({ type: 'int', default: 0 })
  currentStreak: number;

  @Column({ type: 'date', nullable: true })
  lastActiveDate: Date;

  @Column({ type: 'jsonb', default: {} })
  shards: Record<string, number>; // { "ai-shard": 5, "security-shard": 3 }

  // Optimistic locking - prevents lost updates on concurrent modifications
  @VersionColumn()
  version: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

