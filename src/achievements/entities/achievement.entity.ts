import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum AchievementType {
  MILESTONE = 'milestone', // Reach certain XP/level milestones
  STREAK = 'streak', // Streak milestones (7 days, 30 days, etc.)
  COMPLETION = 'completion', // Complete nodes/subjects
  PERFECT_SCORE = 'perfect_score', // Perfect quiz scores
  COLLECTION = 'collection', // Collect shards/items
  SOCIAL = 'social', // Leaderboard rankings
  QUEST_MASTER = 'quest_master', // Complete quests
}

export enum AchievementRarity {
  COMMON = 'common',
  UNCOMMON = 'uncommon',
  RARE = 'rare',
  EPIC = 'epic',
  LEGENDARY = 'legendary',
}

@Entity('achievements')
export class Achievement {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  code: string; // Unique code like "first_steps", "week_warrior", etc.

  @Column()
  name: string; // Display name

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({
    type: 'enum',
    enum: AchievementType,
  })
  type: AchievementType;

  @Column({
    type: 'enum',
    enum: AchievementRarity,
    default: AchievementRarity.COMMON,
  })
  rarity: AchievementRarity;

  @Column({ type: 'jsonb' })
  requirements: {
    // Flexible requirements based on type
    xp?: number;
    level?: number;
    streak?: number;
    completedNodes?: number;
    completedSubjects?: number;
    perfectScores?: number;
    shardCount?: number;
    leaderboardRank?: number;
    questsCompleted?: number;
    [key: string]: any; // Allow other custom requirements
  };

  @Column({ type: 'jsonb', nullable: true })
  rewards: {
    xp?: number;
    coins?: number;
    shards?: Record<string, number>;
  };

  @Column({ nullable: true })
  iconUrl: string; // Icon URL for the badge

  @Column({ nullable: true })
  imageUrl: string; // Full image URL

  @Column({ default: 0 })
  order: number; // Display order

  @Column({ default: true })
  isActive: boolean; // Whether achievement is active

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

