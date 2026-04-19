import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
  Unique,
} from 'typeorm';

@Entity('user_owned_avatar_frames')
@Unique(['userId', 'frameId'])
export class UserOwnedAvatarFrame {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  @Index()
  userId: string;

  /** Mã khung trong catalog (`af_01` … `af_20`). */
  @Column({ type: 'varchar', length: 32 })
  frameId: string;

  @CreateDateColumn()
  createdAt: Date;
}
