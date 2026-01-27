import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum QuestType {
  COMPLETE_ITEMS = 'complete_items', // Hoàn thành N content items
  MAINTAIN_STREAK = 'maintain_streak', // Duy trì streak
  EARN_COINS = 'earn_coins', // Kiếm N coins
  EARN_XP = 'earn_xp', // Kiếm N XP
  COMPLETE_NODE = 'complete_node', // Hoàn thành 1 node
  COMPLETE_DAILY_LESSON = 'complete_daily_lesson', // Hoàn thành bài học hôm nay
}

export enum QuestStatus {
  ACTIVE = 'active',
  COMPLETED = 'completed',
  CLAIMED = 'claimed',
  EXPIRED = 'expired',
}

@Entity('quests')
export class Quest {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  title: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column()
  type: QuestType;

  @Column({ type: 'jsonb' })
  requirements: {
    target: number; // Target value (e.g., complete 3 items)
    current?: number; // Current progress (calculated)
  };

  @Column({ type: 'jsonb' })
  rewards: {
    xp: number;
    coin: number;
    shard?: string;
    shardAmount?: number;
  };

  @Column({ type: 'jsonb', nullable: true })
  metadata: {
    icon?: string;
    category?: string;
    priority?: number; // 1-5, higher = more important
  };

  @Column({ default: true })
  isDaily: boolean; // Daily quest or permanent quest

  @Column({ default: true })
  isActive: boolean; // Quest is available

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

