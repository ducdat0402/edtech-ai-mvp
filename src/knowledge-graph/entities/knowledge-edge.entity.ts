import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  Index,
} from 'typeorm';
import { KnowledgeNode } from './knowledge-node.entity';

export enum EdgeType {
  PREREQUISITE = 'prerequisite', // A phải học trước B
  RELATED = 'related', // A liên quan đến B
  PART_OF = 'part_of', // A là phần của B
  REQUIRES = 'requires', // A yêu cầu B
  LEADS_TO = 'leads_to', // A dẫn đến B
}

@Entity('knowledge_edges')
@Index(['fromNodeId', 'toNodeId', 'type'], { unique: true })
export class KnowledgeEdge {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => KnowledgeNode, (node) => node.outgoingEdges)
  @JoinColumn({ name: 'fromNodeId' })
  fromNode: KnowledgeNode;

  @Column()
  fromNodeId: string;

  @ManyToOne(() => KnowledgeNode, (node) => node.incomingEdges)
  @JoinColumn({ name: 'toNodeId' })
  toNode: KnowledgeNode;

  @Column()
  toNodeId: string;

  @Column({
    type: 'enum',
    enum: EdgeType,
  })
  type: EdgeType;

  @Column({ type: 'float', default: 1.0 })
  weight: number; // Độ quan trọng của relationship (1.0 = required, 0.5 = recommended)

  @Column({ type: 'text', nullable: true })
  description: string; // Mô tả về relationship

  @CreateDateColumn()
  createdAt: Date;
}

