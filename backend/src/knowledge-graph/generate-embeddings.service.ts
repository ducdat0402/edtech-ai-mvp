import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { KnowledgeNode } from './entities/knowledge-node.entity';
import { EmbeddingService } from './embedding.service';

@Injectable()
export class GenerateEmbeddingsService {
  private readonly logger = new Logger(GenerateEmbeddingsService.name);

  constructor(
    @InjectRepository(KnowledgeNode)
    private nodeRepository: Repository<KnowledgeNode>,
    private embeddingService: EmbeddingService,
  ) {}

  /**
   * Generate embedding for a single node
   */
  async generateEmbeddingForNode(nodeId: string): Promise<void> {
    const node = await this.nodeRepository.findOne({ where: { id: nodeId } });
    if (!node) {
      throw new Error(`Node ${nodeId} not found`);
    }

    const text = this.buildTextForEmbedding(node);
    const embedding = await this.embeddingService.generateEmbedding(text);

    node.embedding = embedding;
    await this.nodeRepository.save(node);

    this.logger.log(`✅ Generated embedding for node: ${node.name}`);
  }

  /**
   * Generate embeddings for all nodes without embeddings
   */
  async generateEmbeddingsForAllNodes(): Promise<void> {
    const nodes = await this.nodeRepository.find({
      where: { embedding: null as any },
    });

    this.logger.log(`Found ${nodes.length} nodes without embeddings`);

    let successCount = 0;
    let errorCount = 0;

    for (const node of nodes) {
      try {
        const text = this.buildTextForEmbedding(node);
        const embedding = await this.embeddingService.generateEmbedding(text);

        node.embedding = embedding;
        await this.nodeRepository.save(node);

        successCount++;
        this.logger.log(`✅ [${successCount}/${nodes.length}] Generated embedding for: ${node.name}`);

        // Small delay to avoid rate limits
        await new Promise((resolve) => setTimeout(resolve, 200));
      } catch (error) {
        errorCount++;
        this.logger.error(`❌ Error generating embedding for ${node.name}: ${error.message}`);
      }
    }

    this.logger.log(`✅ Completed: ${successCount} success, ${errorCount} errors`);
  }

  /**
   * Regenerate embeddings for all nodes (force update)
   */
  async regenerateAllEmbeddings(): Promise<void> {
    const nodes = await this.nodeRepository.find();

    this.logger.log(`Regenerating embeddings for ${nodes.length} nodes`);

    let successCount = 0;
    let errorCount = 0;

    for (const node of nodes) {
      try {
        const text = this.buildTextForEmbedding(node);
        const embedding = await this.embeddingService.generateEmbedding(text);

        node.embedding = embedding;
        await this.nodeRepository.save(node);

        successCount++;
        this.logger.log(`✅ [${successCount}/${nodes.length}] Regenerated embedding for: ${node.name}`);

        // Small delay to avoid rate limits
        await new Promise((resolve) => setTimeout(resolve, 200));
      } catch (error) {
        errorCount++;
        this.logger.error(`❌ Error regenerating embedding for ${node.name}: ${error.message}`);
      }
    }

    this.logger.log(`✅ Completed: ${successCount} success, ${errorCount} errors`);
  }

  /**
   * Build text representation of node for embedding
   */
  private buildTextForEmbedding(node: KnowledgeNode): string {
    const parts: string[] = [];

    // Add name
    if (node.name) {
      parts.push(node.name);
    }

    // Add description
    if (node.description) {
      parts.push(node.description);
    }

    // Add type
    parts.push(`Type: ${node.type}`);

    // Add metadata
    if (node.metadata) {
      if (node.metadata.difficulty) {
        parts.push(`Difficulty: ${node.metadata.difficulty}`);
      }
      if (node.metadata.tags && node.metadata.tags.length > 0) {
        parts.push(`Tags: ${node.metadata.tags.join(', ')}`);
      }
    }

    return parts.join('. ');
  }
}

