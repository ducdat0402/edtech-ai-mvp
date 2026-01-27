import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;

  @Column()
  password: string;

  @Column({ nullable: true })
  fullName: string;

  @Column({ nullable: true })
  phone: string;

  @Column({ default: 0 })
  currentStreak: number;

  @Column({ default: 0 })
  totalXP: number;

  @Column({ type: 'jsonb', nullable: true })
  onboardingData: Record<string, any>;

  @Column({ nullable: true })
  placementTestScore: number;

  @Column({ nullable: true })
  placementTestLevel: string;

  @Column({ type: 'varchar', default: 'user' })
  role: 'user' | 'admin'; // Role: user (default) hoặc admin

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

