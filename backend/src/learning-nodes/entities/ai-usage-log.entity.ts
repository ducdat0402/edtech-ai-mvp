import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('ai_usage_logs')
@Index(['userId', 'buttonType', 'date'], { unique: true })
export class AiUsageLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar' })
  userId: string;

  @Column({ type: 'varchar' })
  buttonType: string; // e.g. 'simplify_text'

  /** Calendar date in Asia/Ho_Chi_Minh (YYYY-MM-DD) */
  @Column({ type: 'varchar', length: 10 })
  date: string;

  @Column({ type: 'int', default: 0 })
  usedCount: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

