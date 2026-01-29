import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { KnowledgeGraphService } from './knowledge-graph.service';
import { RagService } from './rag.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { NodeType } from './entities/knowledge-node.entity';
import { EdgeType } from './entities/knowledge-edge.entity';

@Controller('knowledge-graph')
@UseGuards(JwtAuthGuard)
export class KnowledgeGraphController {
  constructor(
    private readonly knowledgeGraphService: KnowledgeGraphService,
    private readonly ragService: RagService,
  ) {}

  /**
   * Get prerequisites for a node
   */
  @Get('nodes/:nodeId/prerequisites')
  async getPrerequisites(@Param('nodeId') nodeId: string) {
    return this.knowledgeGraphService.findPrerequisites(nodeId);
  }

  /**
   * Find learning path from node A to node B
   */
  @Get('path/:fromNodeId/:toNodeId')
  async findPath(
    @Param('fromNodeId') fromNodeId: string,
    @Param('toNodeId') toNodeId: string,
  ) {
    return this.knowledgeGraphService.findPath(fromNodeId, toNodeId);
  }

  /**
   * Get recommended next topics after completing a node
   */
  @Get('nodes/:nodeId/recommend-next')
  async recommendNext(
    @Param('nodeId') nodeId: string,
    @Query('limit') limit?: string,
  ) {
    const limitNum = limit ? parseInt(limit, 10) : 5;
    return this.knowledgeGraphService.recommendNext(nodeId, limitNum);
  }

  /**
   * Get related nodes
   */
  @Get('nodes/:nodeId/related')
  async getRelatedNodes(
    @Param('nodeId') nodeId: string,
    @Query('limit') limit?: string,
  ) {
    const limitNum = limit ? parseInt(limit, 10) : 10;
    return this.knowledgeGraphService.findRelatedNodes(nodeId, limitNum);
  }

  /**
   * Get node by entity ID and type
   */
  @Get('entity/:type/:entityId')
  async getNodeByEntity(
    @Param('type') type: NodeType,
    @Param('entityId') entityId: string,
  ) {
    return this.knowledgeGraphService.getNodeByEntity(entityId, type);
  }

  /**
   * Get all nodes of a specific type
   */
  @Get('nodes/type/:type')
  async getNodesByType(@Param('type') type: NodeType) {
    return this.knowledgeGraphService.getNodesByType(type);
  }

  /**
   * Create or update a node (Admin only - sẽ thêm AdminGuard sau)
   */
  @Post('nodes')
  async createNode(
    @Body()
    body: {
      name: string;
      type: NodeType;
      entityId: string;
      description?: string;
      metadata?: any;
    },
  ) {
    return this.knowledgeGraphService.createOrUpdateNode(
      body.name,
      body.type,
      body.entityId,
      {
        description: body.description,
        metadata: body.metadata,
      },
    );
  }

  /**
   * Create an edge (Admin only)
   */
  @Post('edges')
  async createEdge(
    @Body()
    body: {
      fromNodeId: string;
      toNodeId: string;
      type: EdgeType;
      weight?: number;
      description?: string;
    },
  ) {
    return this.knowledgeGraphService.createEdge(
      body.fromNodeId,
      body.toNodeId,
      body.type,
      {
        weight: body.weight,
        description: body.description,
      },
    );
  }

  /**
   * Semantic search: Find nodes similar to query
   */
  @Get('search')
  async semanticSearch(
    @Query('q') query: string,
    @Query('limit') limit?: string,
    @Query('types') types?: string,
    @Query('minSimilarity') minSimilarity?: string,
  ) {
    if (!query) {
      return { error: 'Query parameter "q" is required' };
    }

    const nodeTypes = types ? types.split(',') : undefined;
    const limitNum = limit ? parseInt(limit, 10) : 10;
    const minSim = minSimilarity ? parseFloat(minSimilarity) : 0.7;

    return this.ragService.semanticSearch(query, {
      limit: limitNum,
      nodeTypes,
      minSimilarity: minSim,
    });
  }

  /**
   * Retrieve relevant nodes for RAG context
   */
  @Get('retrieve')
  async retrieveRelevantNodes(
    @Query('q') query: string,
    @Query('topK') topK?: string,
    @Query('types') types?: string,
  ) {
    if (!query) {
      return { error: 'Query parameter "q" is required' };
    }

    const nodeTypes = types ? types.split(',') : undefined;
    const topKNum = topK ? parseInt(topK, 10) : 5;

    return this.ragService.retrieveRelevantNodes(query, topKNum, nodeTypes);
  }

  /**
   * Generate RAG context from query
   */
  @Get('context')
  async generateRAGContext(
    @Query('q') query: string,
    @Query('topK') topK?: string,
  ) {
    if (!query) {
      return { error: 'Query parameter "q" is required' };
    }

    const topKNum = topK ? parseInt(topK, 10) : 5;
    const context = await this.ragService.generateRAGContext(query, topKNum);
    return { context, query };
  }
}

