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

@Entity('chat_messages')
export class ChatMessage {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  userId: string;

  @Column()
  username: string;

  @Column({ type: 'text' })
  message: string;

  @Column({ type: 'int', default: 0 })
  userLevel: number;

  @Column({ nullable: true })
  replyToId: string | null;

  @ManyToOne(() => ChatMessage, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'replyToId' })
  replyTo: ChatMessage | null;

  @Index()
  @CreateDateColumn()
  createdAt: Date;
}
