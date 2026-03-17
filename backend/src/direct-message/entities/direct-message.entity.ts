import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('direct_messages')
@Index(['senderId', 'receiverId', 'createdAt'])
export class DirectMessage {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'senderId' })
  sender: User;

  @Column()
  senderId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'receiverId' })
  receiver: User;

  @Column()
  receiverId: string;

  @Column({ type: 'text' })
  content: string;

  @Column({ nullable: true })
  replyToId: string | null;

  @ManyToOne(() => DirectMessage, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'replyToId' })
  replyTo: DirectMessage | null;

  @Column({ type: 'timestamp', nullable: true })
  readAt: Date | null;

  @CreateDateColumn()
  createdAt: Date;
}
