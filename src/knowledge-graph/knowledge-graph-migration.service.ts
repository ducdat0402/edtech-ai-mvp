import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { KnowledgeGraphService } from './knowledge-graph.service';
import { Subject } from '../subjects/entities/subject.entity';
import { Domain } from '../domains/entities/domain.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { NodeType } from './entities/knowledge-node.entity';
import { EdgeType } from './entities/knowledge-edge.entity';

@Injectable()
export class KnowledgeGraphMigrationService {
  private readonly logger = new Logger(KnowledgeGraphMigrationService.name);

  constructor(
    @InjectRepository(Subject)
    private subjectRepository: Repository<Subject>,
    @InjectRepository(Domain)
    private domainRepository: Repository<Domain>,
    @InjectRepository(LearningNode)
    private learningNodeRepository: Repository<LearningNode>,
    private knowledgeGraphService: KnowledgeGraphService,
  ) {}

  /**
   * Migrate tất cả existing data vào Knowledge Graph
   */
  async migrateAll(): Promise<void> {
    this.logger.log('🌱 Starting Knowledge Graph migration...');

    try {
      // 1. Migrate Subjects
      await this.migrateSubjects();

      // 2. Migrate Domains
      await this.migrateDomains();

      // 3. Migrate Learning Nodes
      await this.migrateLearningNodes();

      this.logger.log('✅ Knowledge Graph migration completed!');
    } catch (error) {
      this.logger.error('❌ Error during migration:', error);
      throw error;
    }
  }

  /**
   * Migrate Subjects → Knowledge Nodes
   */
  private async migrateSubjects(): Promise<void> {
    this.logger.log('📚 Migrating Subjects...');
    const subjects = await this.subjectRepository.find();

    for (const subject of subjects) {
      await this.knowledgeGraphService.createOrUpdateNode(
        subject.name,
        NodeType.SUBJECT,
        subject.id,
        {
          description: subject.description,
          metadata: {
            icon: subject.metadata?.icon,
            color: subject.metadata?.color,
            estimatedDays: subject.metadata?.estimatedDays,
          },
        },
      );
    }

    this.logger.log(`✅ Migrated ${subjects.length} subjects`);
  }

  /**
   * Migrate Domains → Knowledge Nodes và tạo PART_OF edges với Subjects
   */
  private async migrateDomains(): Promise<void> {
    this.logger.log('📖 Migrating Domains...');
    const domains = await this.domainRepository.find({
      relations: ['subject'],
    });

    for (const domain of domains) {
      // Create domain node
      const domainNode = await this.knowledgeGraphService.createOrUpdateNode(
        domain.name,
        NodeType.DOMAIN,
        domain.id,
        {
          description: domain.description,
          metadata: {
            icon: domain.metadata?.icon,
            estimatedDays: domain.metadata?.estimatedDays,
          },
        },
      );

      // Create PART_OF edge: Domain → Subject
      const subjectNode = await this.knowledgeGraphService.getNodeByEntity(
        domain.subjectId,
        NodeType.SUBJECT,
      );

      if (subjectNode) {
        await this.knowledgeGraphService.createEdge(
          domainNode.id,
          subjectNode.id,
          EdgeType.PART_OF,
          {
            weight: 1.0,
            description: `${domain.name} là một phần của ${subjectNode.name}`,
          },
        );
      }
    }

    this.logger.log(`✅ Migrated ${domains.length} domains`);
  }

  /**
   * Migrate Learning Nodes → Knowledge Nodes và tạo relationships
   */
  private async migrateLearningNodes(): Promise<void> {
    this.logger.log('🎓 Migrating Learning Nodes...');
    const nodes = await this.learningNodeRepository.find({
      relations: ['subject', 'domain'],
    });

    for (const node of nodes) {
      // Create learning node
      const learningNode = await this.knowledgeGraphService.createOrUpdateNode(
        node.title,
        NodeType.LEARNING_NODE,
        node.id,
        {
          description: node.description,
          metadata: {
            icon: node.metadata?.icon,
            // Note: difficulty and estimatedTime are not in LearningNode entity
            // They can be added later if needed
          },
        },
      );

      // Create PART_OF edge: Learning Node → Domain (if domain exists)
      if (node.domainId) {
        const domainNode = await this.knowledgeGraphService.getNodeByEntity(
          node.domainId,
          NodeType.DOMAIN,
        );

        if (domainNode) {
          await this.knowledgeGraphService.createEdge(
            learningNode.id,
            domainNode.id,
            EdgeType.PART_OF,
            {
              weight: 1.0,
              description: `${node.title} thuộc về ${domainNode.name}`,
            },
          );
        }
      } else {
        // If no domain, link directly to subject
        const subjectNode = await this.knowledgeGraphService.getNodeByEntity(
          node.subjectId,
          NodeType.SUBJECT,
        );

        if (subjectNode) {
          await this.knowledgeGraphService.createEdge(
            learningNode.id,
            subjectNode.id,
            EdgeType.PART_OF,
            {
              weight: 1.0,
              description: `${node.title} thuộc về ${subjectNode.name}`,
            },
          );
        }
      }

      // Create PREREQUISITE edges based on order
      // Nodes with lower order are prerequisites for nodes with higher order
      if (node.order > 0) {
        const previousNodes = await this.learningNodeRepository.find({
          where: {
            subjectId: node.subjectId,
            domainId: node.domainId || null,
            order: node.order - 1,
          },
        });

        for (const prevNode of previousNodes) {
          const prevKnowledgeNode =
            await this.knowledgeGraphService.getNodeByEntity(
              prevNode.id,
              NodeType.LEARNING_NODE,
            );

          if (prevKnowledgeNode) {
            await this.knowledgeGraphService.createEdge(
              prevKnowledgeNode.id,
              learningNode.id,
              EdgeType.PREREQUISITE,
              {
                weight: 0.8, // Slightly lower weight for order-based prerequisites
                description: `Cần hoàn thành ${prevNode.title} trước khi học ${node.title}`,
              },
            );
          }
        }
      }
    }

    this.logger.log(`✅ Migrated ${nodes.length} learning nodes`);
  }
}

