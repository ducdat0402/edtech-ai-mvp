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

  @CreateDateColumn()
  openedAt: Date;
}
