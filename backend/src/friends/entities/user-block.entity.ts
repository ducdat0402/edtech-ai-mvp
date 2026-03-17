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

@Entity('user_blocks')
@Index(['blockerId', 'blockedId'], { unique: true })
export class UserBlock {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'blockerId' })
  blocker: User;

  @Column()
  blockerId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'blockedId' })
  blocked: User;

  @Column()
  blockedId: string;

  @CreateDateColumn()
  createdAt: Date;
}
