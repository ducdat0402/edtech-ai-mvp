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

@Entity('unlock_transactions')
export class UnlockTransaction {
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

  @Column()
  unlockType: 'coin_only' | 'coin_plus_payment';

  @Column({ type: 'int' })
  coinsUsed: number;

  @Column({ type: 'int', nullable: true })
  paymentAmount: number; // VND

  @Column({ default: 'pending' })
  status: 'pending' | 'completed' | 'failed';

  @Column({ type: 'text', nullable: true })
  paymentReference: string; // Mã tham chiếu thanh toán

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

