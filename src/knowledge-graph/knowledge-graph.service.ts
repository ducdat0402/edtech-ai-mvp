import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { KnowledgeNode, NodeType } from './entities/knowledge-node.entity';
import { KnowledgeEdge, EdgeType } from './entities/knowledge-edge.entity';

@Injectable()
export class KnowledgeGraphService {
  private readonly logger = new Logger(KnowledgeGraphService.name);

  constructor(
    @InjectRepository(KnowledgeNode)
    private nodeRepository: Repository<KnowledgeNode>,
    @InjectRepository(KnowledgeEdge)
    private edgeRepository: Repository<KnowledgeEdge>,
  ) {}

  /**
   * Tạo hoặc cập nhật một knowledge node
   */
  async createOrUpdateNode(
    name: string,
    type: NodeType,
    entityId: string,
    options?: {
      description?: string;
      metadata?: any;
    },
  ): Promise<KnowledgeNode> {
    let node = await this.nodeRepository.findOne({
      where: { entityId, type },
    });

    if (node) {
      // Update existing node
      node.name = name;
      if (options?.description) node.description = options.description;
      if (options?.metadata) node.metadata = options.metadata;
      return this.nodeRepository.save(node);
    }

    // Create new node
    node = this.nodeRepository.create({
      name,
      type,
      entityId,
      description: options?.description,
      metadata: options?.metadata,
    });

    return this.nodeRepository.save(node);
  }

  /**
   * Tạo một edge giữa hai nodes
   */
  async createEdge(
    fromNodeId: string,
    toNodeId: string,
    type: EdgeType,
    options?: {
      weight?: number;
      description?: string;
    },
  ): Promise<KnowledgeEdge> {
    // Check if edge already exists
    const existingEdge = await this.edgeRepository.findOne({
      where: {
        fromNodeId,
        toNodeId,
        type,
      },
    });

    if (existingEdge) {
      // Update existing edge
      if (options?.weight !== undefined) existingEdge.weight = options.weight;
      if (options?.description) existingEdge.description = options.description;
      return this.edgeRepository.save(existingEdge);
    }

    const edge = this.edgeRepository.create({
      fromNodeId,
      toNodeId,
      type,
      weight: options?.weight ?? 1.0,
      description: options?.description,
    });

    return this.edgeRepository.save(edge);
  }

  /**
   * Tìm tất cả prerequisites của một node (recursive)
   */
  async findPrerequisites(nodeId: string): Promise<KnowledgeNode[]> {
    const prerequisites = new Set<string>();
    const visited = new Set<string>();

    const traverse = async (currentNodeId: string) => {
      if (visited.has(currentNodeId)) return;
      visited.add(currentNodeId);

      const incomingEdges = await this.edgeRepository.find({
        where: {
          toNodeId: currentNodeId,
          type: EdgeType.PREREQUISITE,
        },
        relations: ['fromNode'],
      });

      for (const edge of incomingEdges) {
        prerequisites.add(edge.fromNodeId);
        await traverse(edge.fromNodeId);
      }
    };

    await traverse(nodeId);

    if (prerequisites.size === 0) return [];

    return this.nodeRepository.find({
      where: { id: In(Array.from(prerequisites)) },
    });
  }

  /**
   * Tìm learning path từ node A đến node B
   */
  async findPath(
    fromNodeId: string,
    toNodeId: string,
  ): Promise<KnowledgeNode[]> {
    // Simple BFS to find shortest path
    const queue: Array<{ nodeId: string; path: string[] }> = [
      { nodeId: fromNodeId, path: [fromNodeId] },
    ];
    const visited = new Set<string>();

    while (queue.length > 0) {
      const { nodeId, path } = queue.shift()!;

      if (nodeId === toNodeId) {
        // Found path
        return this.nodeRepository.find({
          where: { id: In(path) },
          order: {
            // Maintain order
          },
        });
      }

      if (visited.has(nodeId)) continue;
      visited.add(nodeId);

      // Get outgoing edges
      const edges = await this.edgeRepository.find({
        where: { fromNodeId: nodeId },
      });

      for (const edge of edges) {
        if (!visited.has(edge.toNodeId)) {
          queue.push({
            nodeId: edge.toNodeId,
            path: [...path, edge.toNodeId],
          });
        }
      }
    }

    return []; // No path found
  }

  /**
   * Recommend next topics để học sau khi hoàn thành một node
   */
  async recommendNext(
    completedNodeId: string,
    limit: number = 5,
  ): Promise<KnowledgeNode[]> {
    // Get nodes that this node leads to
    const outgoingEdges = await this.edgeRepository.find({
      where: {
        fromNodeId: completedNodeId,
        type: In([EdgeType.LEADS_TO, EdgeType.REQUIRES]),
      },
      order: { weight: 'DESC' },
      take: limit,
    });

    if (outgoingEdges.length === 0) return [];

    const nextNodeIds = outgoingEdges.map((e) => e.toNodeId);

    // Check if user has completed prerequisites for these nodes
    const recommendedNodes = await this.nodeRepository.find({
      where: { id: In(nextNodeIds) },
    });

    // Filter nodes where all prerequisites are met (simplified - assume prerequisites are met)
    return recommendedNodes;
  }

  /**
   * Tìm tất cả nodes liên quan đến một node
   */
  async findRelatedNodes(
    nodeId: string,
    limit: number = 10,
  ): Promise<KnowledgeNode[]> {
    const edges = await this.edgeRepository.find({
      where: [
        { fromNodeId: nodeId, type: EdgeType.RELATED },
        { toNodeId: nodeId, type: EdgeType.RELATED },
      ],
      take: limit,
    });

    const relatedNodeIds = new Set<string>();
    edges.forEach((edge) => {
      if (edge.fromNodeId !== nodeId) relatedNodeIds.add(edge.fromNodeId);
      if (edge.toNodeId !== nodeId) relatedNodeIds.add(edge.toNodeId);
    });

    if (relatedNodeIds.size === 0) return [];

    return this.nodeRepository.find({
      where: { id: In(Array.from(relatedNodeIds)) },
    });
  }

  /**
   * Get node by entity ID and type
   */
  async getNodeByEntity(
    entityId: string,
    type: NodeType,
  ): Promise<KnowledgeNode | null> {
    return this.nodeRepository.findOne({
      where: { entityId, type },
      relations: ['outgoingEdges', 'incomingEdges'],
    });
  }

  /**
   * Get node by ID
   */
  async getNodeById(nodeId: string): Promise<KnowledgeNode | null> {
    return this.nodeRepository.findOne({
      where: { id: nodeId },
      relations: ['outgoingEdges', 'incomingEdges'],
    });
  }

  /**
   * Get all nodes of a specific type
   */
  async getNodesByType(type: NodeType): Promise<KnowledgeNode[]> {
    return this.nodeRepository.find({
      where: { type },
    });
  }

  /**
   * Get nodes by entityId (for a specific subject/domain/etc)
   */
  async getNodesByEntityId(entityId: string): Promise<KnowledgeNode[]> {
    return this.nodeRepository.find({
      where: { entityId },
    });
  }

  /**
   * Get nodes by entityId pattern (for subjects with composite entityIds)
   */
  async getNodesByEntityIdPattern(pattern: string): Promise<KnowledgeNode[]> {
    return this.nodeRepository
      .createQueryBuilder('node')
      .where('node.entityId LIKE :pattern', { pattern: `%${pattern}%` })
      .getMany();
  }

  /**
   * Get mind map for a subject (nodes and edges)
   */
  async getMindMapForSubject(subjectId: string): Promise<{
    nodes: KnowledgeNode[];
    edges: KnowledgeEdge[];
  }> {
    // Get all nodes related to this subject
    const nodes = await this.getNodesByEntityIdPattern(subjectId);
    
    if (nodes.length === 0) {
      return { nodes: [], edges: [] };
    }

    const nodeIds = nodes.map(n => n.id);
    
    // Get all edges between these nodes
    const edges = await this.edgeRepository.find({
      where: [
        { fromNodeId: In(nodeIds) },
        { toNodeId: In(nodeIds) },
      ],
    });

    return { nodes, edges };
  }
}

