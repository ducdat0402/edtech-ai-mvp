import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
  Unique,
} from 'typeorm';

@Entity('user_opened_nodes')
@Unique(['userId', 'nodeId'])
@Index(['userId'])
export class UserOpenedNode {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  userId: string;

  @Column({ type: 'uuid' })
  nodeId: string;

  /** 0 = dùng suất miễn phí trong ngày; >0 = đã trừ kim cương (thường là DIAMOND_PER_LESSON_OPEN). */
  @Column({ type: 'int', default: 0 })
  diamondsPaid: number;

  /** 0 = không dùng xu; >0 = đã trừ xu (community có thể mở bằng xu). */
  @Column({ type: 'int', default: 0 })
  coinsPaid: number;

  /** Nguồn mở bài: free_daily | paid | onboarding_trial. Trial không đếm vào quota miễn phí. */
  @Column({ type: 'varchar', length: 30, default: 'free_daily' })
  source: string;

  @CreateDateColumn()
  openedAt: Date;
}
