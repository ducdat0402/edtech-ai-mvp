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

  /** Ảnh đại diện: `/uploads/images/...` hoặc URL đầy đủ. */
  @Column({ type: 'text', nullable: true })
  avatarUrl: string | null;

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
  role: 'user' | 'contributor' | 'admin';

  @Column({ type: 'varchar', default: 'local' })
  authProvider: 'local' | 'google';

  @Column({ type: 'varchar', nullable: true })
  resetPasswordToken: string | null;

  @Column({ type: 'timestamptz', nullable: true })
  resetPasswordExpires: Date | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

