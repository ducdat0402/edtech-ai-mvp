import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('user_premium')
export class UserPremium {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column({ unique: true })
  userId: string;

  // Premium status
  @Column({ default: false })
  isPremium: boolean;

  // When premium expires
  @Column({ type: 'timestamp', nullable: true })
  premiumExpiresAt: Date;

  // Total days purchased
  @Column({ default: 0 })
  totalDaysPurchased: number;

  // Last payment reference
  @Column({ nullable: true })
  lastPaymentId: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
