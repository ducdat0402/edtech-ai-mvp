import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { KnowledgeNode } from './entities/knowledge-node.entity';
import { EmbeddingService } from './embedding.service';

@Injectable()
export class RagService {
  private readonly logger = new Logger(RagService.name);

  constructor(
    @InjectRepository(KnowledgeNode)
    private nodeRepository: Repository<KnowledgeNode>,
    private embeddingService: EmbeddingService,
  ) {}

  /**
   * Semantic search: Find nodes similar to query text
   * Uses cosine similarity on embeddings
   */
  async semanticSearch(
    query: string,
    options?: {
      limit?: number;
      nodeTypes?: string[];
      minSimilarity?: number;
    },
  ): Promise<Array<{ node: KnowledgeNode; similarity: number }>> {
    const limit = options?.limit || 10;
    const minSimilarity = options?.minSimilarity || 0.7;

    try {
      // Generate embedding for query
      const queryEmbedding = await this.embeddingService.generateEmbedding(query);

      // Use JSONB and calculate similarity in application layer
      let sql = `
        SELECT 
          id,
          name,
          description,
          type,
          "entityId",
          metadata,
          embedding,
          "createdAt",
          "updatedAt"
        FROM knowledge_nodes
        WHERE embedding IS NOT NULL
      `;

      const params: any[] = [];

      // Filter by node types if specified
      if (options?.nodeTypes && options.nodeTypes.length > 0) {
        sql += ` AND type = ANY($${params.length + 1}::text[])`;
        params.push(options.nodeTypes);
      }

      const results = await this.nodeRepository.query(sql, params);

      // Calculate cosine similarity for each result
      const nodesWithSimilarity = results
        .map((result: any) => {
          if (!result.embedding || !Array.isArray(result.embedding)) {
            return null;
          }

          const nodeEmbedding = result.embedding;
          const similarity = this.cosineSimilarity(queryEmbedding, nodeEmbedding);

          if (similarity < minSimilarity) {
            return null;
          }

          const node = new KnowledgeNode();
          Object.assign(node, {
            id: result.id,
            name: result.name,
            description: result.description,
            type: result.type,
            entityId: result.entityId,
            metadata: result.metadata,
            embedding: result.embedding,
            createdAt: result.createdAt,
            updatedAt: result.updatedAt,
          });

          return {
            node,
            similarity,
          };
        })
        .filter((item) => item !== null)
        .sort((a, b) => b!.similarity - a!.similarity)
        .slice(0, limit) as Array<{ node: KnowledgeNode; similarity: number }>;

      this.logger.log(`Found ${nodesWithSimilarity.length} similar nodes for query: "${query}"`);
      return nodesWithSimilarity;
    } catch (error) {
      this.logger.error(`Semantic search error: ${error.message}`, error.stack);
      throw error;
    }
  }

  /**
   * Retrieve relevant nodes for RAG context
   * Returns top-k most relevant nodes based on semantic similarity
   */
  async retrieveRelevantNodes(
    query: string,
    topK: number = 5,
    nodeTypes?: string[],
  ): Promise<KnowledgeNode[]> {
    const results = await this.semanticSearch(query, {
      limit: topK,
      nodeTypes,
      minSimilarity: 0.6, // Lower threshold for retrieval
    });

    return results.map((r) => r.node);
  }

  /**
   * Find learning path using semantic search
   * Combines graph structure with semantic similarity
   */
  async findSemanticLearningPath(
    startNodeId: string,
    goalQuery: string,
    maxDepth: number = 5,
  ): Promise<KnowledgeNode[]> {
    try {
      // Find goal node using semantic search
      const goalResults = await this.semanticSearch(goalQuery, {
        limit: 1,
        nodeTypes: ['learning_node'],
      });

      if (goalResults.length === 0) {
        this.logger.warn(`No goal node found for query: "${goalQuery}"`);
        return [];
      }

      const goalNodeId = goalResults[0].node.id;

      // Use graph-based path finding (already implemented in KnowledgeGraphService)
      // This would require injecting KnowledgeGraphService
      // For now, return semantic search results
      return goalResults.map((r) => r.node);
    } catch (error) {
      this.logger.error(`Semantic learning path error: ${error.message}`, error.stack);
      throw error;
    }
  }

  /**
   * Generate context for AI from retrieved nodes
   */
  async generateRAGContext(query: string, topK: number = 5): Promise<string> {
    const nodes = await this.retrieveRelevantNodes(query, topK);

    if (nodes.length === 0) {
      return 'No relevant content found.';
    }

    const contextParts = nodes.map((node, index) => {
      return `[${index + 1}] ${node.name} (${node.type})
${node.description || 'No description'}
${node.metadata?.difficulty ? `Difficulty: ${node.metadata.difficulty}` : ''}
`;
    });

    return `Relevant Learning Content:\n${contextParts.join('\n')}`;
  }

  /**
   * Calculate cosine similarity between two vectors
   */
  private cosineSimilarity(vecA: number[], vecB: number[]): number {
    if (vecA.length !== vecB.length) {
      throw new Error('Vectors must have the same length');
    }

    let dotProduct = 0;
    let normA = 0;
    let normB = 0;

    for (let i = 0; i < vecA.length; i++) {
      dotProduct += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }

    const denominator = Math.sqrt(normA) * Math.sqrt(normB);
    if (denominator === 0) {
      return 0;
    }

    return dotProduct / denominator;
  }
}

