import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  UpdateDateColumn,
  JoinColumn,
} from 'typeorm';
import { LearningNode } from '../../learning-nodes/entities/learning-node.entity';

@Entity('content_items')
export class ContentItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => LearningNode, (node) => node.contentItems)
  @JoinColumn({ name: 'nodeId' })
  node: LearningNode;

  @Column()
  nodeId: string;

  @Column()
  type: 'concept' | 'example' | 'hidden_reward' | 'boss_quiz';

  @Column({
    type: 'varchar',
    length: 20,
    nullable: true,
    default: 'text',
  })
  format: 'text' | 'mixed' | 'quiz' | null; // Content format: text (default), mixed (text + media), quiz

  @Column({
    type: 'varchar',
    length: 20,
    nullable: true,
    default: 'medium',
  })
  difficulty: 'easy' | 'medium' | 'hard' | 'expert'; // Difficulty level

  @Column({
    type: 'varchar',
    length: 20,
    nullable: true,
    default: 'published',
  })
  status: 'published' | 'placeholder' | 'awaiting_review' | 'draft'; // Content status

  @Column()
  title: string;

  @Column({ type: 'text', nullable: true })
  content: string; // JSON hoặc markdown (default/detailed version)

  @Column({ type: 'jsonb', nullable: true })
  richContent: any; // Rich text content (JSON from flutter_quill)

  // Text variants for different learning preferences
  // Only applies to text-based content (concept, example)
  @Column({ type: 'jsonb', nullable: true })
  textVariants: {
    simple?: string; // Đơn giản - tóm tắt ngắn gọn, dễ hiểu
    detailed?: string; // Chi tiết - giải thích đầy đủ (default = content)
    comprehensive?: string; // Chuyên sâu - bao gồm cả kiến thức mở rộng, liên hệ thực tế
    simpleRichContent?: any; // Rich text version
    comprehensiveRichContent?: any; // Rich text version
  };

  @Column({ type: 'jsonb', nullable: true })
  media: {
    // Actual media URLs
    videoUrl?: string;
    imageUrl?: string;
    imageUrls?: string[]; // Multiple images
    interactiveUrl?: string;
    
    // AI-generated prompts for media creation
    imagePrompt?: string;        // Prompt để generate hình ảnh với AI (DALL-E, Midjourney)
    imageDescription?: string;   // Mô tả hình ảnh cho người dùng
    videoScript?: string;        // Script cho video (narration)
    videoDescription?: string;   // Mô tả video
    videoDuration?: string;      // Độ dài video gợi ý
    
    // Generation metadata
    imageGeneratedAt?: string;   // Thời điểm generate image
    videoGeneratedAt?: string;   // Thời điểm generate video
  };

  @Column({ type: 'int', default: 0 })
  order: number;

  @Column({ type: 'jsonb', nullable: true })
  rewards: {
    xp?: number;
    coin?: number;
    shard?: string; // Shard type ID
    shardAmount?: number;
  };

  @Column({ type: 'jsonb', nullable: true })
  quizData: {
    question?: string;
    options?: string[];
    correctAnswer?: number;
    explanation?: string;
  };

  @Column({ type: 'jsonb', nullable: true })
  contributionGuide: {
    suggestedContent?: string; // Mô tả chi tiết nội dung cần tạo
    requirements?: string[]; // Yêu cầu kỹ thuật (độ dài, chất lượng, định dạng...)
    examples?: string[]; // Links đến ví dụ tham khảo
    difficulty?: 'easy' | 'medium' | 'hard'; // Độ khó để tạo content này
    estimatedTime?: string; // Thời gian ước tính để tạo
    tags?: string[]; // Tags để phân loại (piano, guitar, theory...)
  };

  @Column({ type: 'uuid', nullable: true })
  contributorId: string; // ID của người đóng góp (nếu có)

  @Column({ type: 'timestamp', nullable: true })
  contributedAt: Date; // Thời điểm đóng góp

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

