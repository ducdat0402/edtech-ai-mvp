import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { KnowledgeGraphService } from './knowledge-graph.service';
import { KnowledgeGraphController } from './knowledge-graph.controller';
import { KnowledgeGraphMigrationService } from './knowledge-graph-migration.service';
import { KnowledgeGraphTestService } from './knowledge-graph-test.service';
import { EmbeddingService } from './embedding.service';
import { RagService } from './rag.service';
import { GenerateEmbeddingsService } from './generate-embeddings.service';
import { KnowledgeNode } from './entities/knowledge-node.entity';
import { KnowledgeEdge } from './entities/knowledge-edge.entity';
import { Subject } from '../subjects/entities/subject.entity';
import { Domain } from '../domains/entities/domain.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { SubjectsModule } from '../subjects/subjects.module';
import { DomainsModule } from '../domains/domains.module';
import { LearningNodesModule } from '../learning-nodes/learning-nodes.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      KnowledgeNode,
      KnowledgeEdge,
      Subject,
      Domain,
      LearningNode,
    ]),
    forwardRef(() => SubjectsModule),
    forwardRef(() => DomainsModule),
    forwardRef(() => LearningNodesModule),
  ],
  controllers: [KnowledgeGraphController],
  providers: [
    KnowledgeGraphService,
    KnowledgeGraphMigrationService,
    KnowledgeGraphTestService,
    EmbeddingService,
    RagService,
    GenerateEmbeddingsService,
  ],
  exports: [
    KnowledgeGraphService,
    KnowledgeGraphMigrationService,
    KnowledgeGraphTestService,
    EmbeddingService,
    RagService,
  ],
})
export class KnowledgeGraphModule {}

