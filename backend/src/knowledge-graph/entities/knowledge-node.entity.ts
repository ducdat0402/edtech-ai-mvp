import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { KnowledgeEdge } from './knowledge-edge.entity';

export enum NodeType {
  SUBJECT = 'subject',
  DOMAIN = 'domain',
  LEARNING_NODE = 'learning_node',
  CONCEPT = 'concept',
  LESSON = 'lesson',
}

@Entity('knowledge_nodes')
export class KnowledgeNode {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string; // Tên node (e.g., "VLOOKUP", "Excel Basics")

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({
    type: 'enum',
    enum: NodeType,
  })
  type: NodeType;

  @Column({ nullable: true })
  entityId: string; // ID của entity gốc (subjectId, domainId, nodeId, contentId)

  @Column({ type: 'jsonb', nullable: true })
  metadata: {
    icon?: string;
    color?: string;
    difficulty?: 'easy' | 'medium' | 'hard' | 'expert';
    estimatedTime?: number; // minutes
    tags?: string[];
  };

  @Column({
    type: 'jsonb',
    nullable: true,
  })
  embedding: number[]; // Vector embedding cho semantic search (stored as JSONB array, similarity calculated in application layer)

  @OneToMany(() => KnowledgeEdge, (edge) => edge.fromNode)
  outgoingEdges: KnowledgeEdge[];

  @OneToMany(() => KnowledgeEdge, (edge) => edge.toNode)
  incomingEdges: KnowledgeEdge[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

