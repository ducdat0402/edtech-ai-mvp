import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  JoinColumn,
  Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('user_unlocks')
@Index(['userId', 'unlockLevel', 'subjectId'], { unique: false })
@Index(['userId', 'unlockLevel', 'domainId'], { unique: false })
@Index(['userId', 'unlockLevel', 'topicId'], { unique: false })
export class UserUnlock {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  userId: string;

  @Column({ type: 'varchar', length: 20 })
  unlockLevel: 'subject' | 'domain' | 'topic';

  @Column({ type: 'uuid', nullable: true })
  subjectId: string;

  @Column({ type: 'uuid', nullable: true })
  domainId: string;

  @Column({ type: 'uuid', nullable: true })
  topicId: string;

  @Column({ type: 'int' })
  diamondsCost: number; // Số kim cương đã trừ

  @Column({ type: 'int' })
  lessonsCount: number; // Số bài học đã mở khóa

  @Column({ type: 'int', default: 0 })
  discountPercent: number; // 0, 15, 30

  @CreateDateColumn()
  createdAt: Date;
}
