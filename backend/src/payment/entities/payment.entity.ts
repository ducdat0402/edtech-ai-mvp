import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

export type PaymentStatus = 'pending' | 'paid' | 'expired' | 'cancelled';

@Entity('payments')
@Index(['userId', 'status'])
export class Payment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  userId: string;

  // Unique payment code for bank transfer content
  @Column({ unique: true })
  paymentCode: string;

  // Package info
  @Column()
  packageName: string;

  @Column('decimal', { precision: 12, scale: 0 })
  amount: number;

  @Column({ nullable: true })
  description: string;

  // Number of diamonds (coins) purchased
  @Column({ default: 0 })
  diamondAmount: number;

  // Duration in days (legacy - for old premium subscription records)
  @Column({ default: 0 })
  durationDays: number;

  // Status
  @Column({ default: 'pending' })
  status: PaymentStatus;

  // Bank transfer info (filled when paid)
  // Unique constraint prevents duplicate webhook processing (idempotency)
  @Column({ nullable: true, unique: true })
  transactionId: string;

  @Column({ nullable: true })
  bankReference: string;

  @Column({ type: 'timestamp', nullable: true })
  paidAt: Date;

  // Expiry for pending payment (e.g., 24 hours)
  @Column({ type: 'timestamp' })
  expiresAt: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
