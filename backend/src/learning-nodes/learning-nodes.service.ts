import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { LearningNode } from './entities/learning-node.entity';

@Injectable()
export class LearningNodesService {
  constructor(
    @InjectRepository(LearningNode)
    private nodeRepository: Repository<LearningNode>,
  ) {}

  async findBySubject(subjectId: string): Promise<LearningNode[]> {
    return this.nodeRepository.find({
      where: { subjectId },
      order: { order: 'ASC' },
    });
  }

  async findById(id: string): Promise<LearningNode | null> {
    return this.nodeRepository.findOne({
      where: { id },
      relations: ['subject', 'contentItems'],
    });
  }

  async getAvailableNodes(
    subjectId: string,
    completedNodeIds: string[],
  ): Promise<LearningNode[]> {
    const allNodes = await this.findBySubject(subjectId);

    return allNodes.filter((node) => {
      // Root node (no prerequisites) is always available
      if (!node.prerequisites || node.prerequisites.length === 0) {
        return true;
      }

      // Check if all prerequisites are completed
      return node.prerequisites.every((prereqId) =>
        completedNodeIds.includes(prereqId),
      );
    });
  }
}

