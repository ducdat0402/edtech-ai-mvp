import { Injectable, Logger } from '@nestjs/common';
import { KnowledgeGraphService } from './knowledge-graph.service';
import { NodeType } from './entities/knowledge-node.entity';

@Injectable()
export class KnowledgeGraphTestService {
  private readonly logger = new Logger(KnowledgeGraphTestService.name);

  constructor(private knowledgeGraphService: KnowledgeGraphService) {}

  /**
   * Test Knowledge Graph functionality
   */
  async runTests(): Promise<void> {
    this.logger.log('🧪 Running Knowledge Graph tests...');

    try {
      // Test 1: Get all subjects
      const subjects = await this.knowledgeGraphService.getNodesByType(NodeType.SUBJECT);
      this.logger.log(`✅ Found ${subjects.length} subjects in Knowledge Graph`);

      if (subjects.length === 0) {
        this.logger.warn('⚠️  No subjects found. Migration may not have run.');
        return;
      }

      // Test 2: Get all domains
      const domains = await this.knowledgeGraphService.getNodesByType(NodeType.DOMAIN);
      this.logger.log(`✅ Found ${domains.length} domains in Knowledge Graph`);

      // Test 3: Get all learning nodes
      const learningNodes = await this.knowledgeGraphService.getNodesByType(NodeType.LEARNING_NODE);
      this.logger.log(`✅ Found ${learningNodes.length} learning nodes in Knowledge Graph`);

      // Test 4: Test prerequisites for a learning node
      if (learningNodes.length > 0) {
        const testNode = learningNodes[0];
        const prerequisites = await this.knowledgeGraphService.findPrerequisites(testNode.id);
        this.logger.log(`✅ Node "${testNode.name}" has ${prerequisites.length} prerequisites`);
      }

      // Test 5: Test recommend next
      if (learningNodes.length > 0) {
        const testNode = learningNodes[0];
        const recommended = await this.knowledgeGraphService.recommendNext(testNode.id, 3);
        this.logger.log(`✅ Recommended ${recommended.length} next topics for "${testNode.name}"`);
      }

      // Test 6: Test related nodes
      if (learningNodes.length > 0) {
        const testNode = learningNodes[0];
        const related = await this.knowledgeGraphService.findRelatedNodes(testNode.id, 5);
        this.logger.log(`✅ Found ${related.length} related nodes for "${testNode.name}"`);
      }

      this.logger.log('✅ All Knowledge Graph tests passed!');
    } catch (error) {
      this.logger.error('❌ Error during tests:', error);
      throw error;
    }
  }
}

