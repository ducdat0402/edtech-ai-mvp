import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { LearningNode } from './entities/learning-node.entity';
import { AiService } from '../ai/ai.service';
import { ContentItem } from '../content-items/entities/content-item.entity';

@Injectable()
export class LearningNodesService {
  constructor(
    @InjectRepository(LearningNode)
    private nodeRepository: Repository<LearningNode>,
    @InjectRepository(ContentItem)
    private contentItemRepository: Repository<ContentItem>,
    private aiService: AiService,
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

  /**
   * Tự động tạo Learning Nodes từ dữ liệu thô
   * Chỉ cần cung cấp: subject name, description, hoặc topics
   */
  async generateNodesFromRawData(
    subjectId: string,
    subjectName: string,
    subjectDescription?: string,
    topicsOrChapters?: string[],
    numberOfNodes: number = 10,
  ): Promise<LearningNode[]> {
    console.log(`🤖 Generating ${numberOfNodes} Learning Nodes for "${subjectName}" using AI...`);

    // 1. AI generate structure
    const nodesStructure = await this.aiService.generateLearningNodesStructure(
      subjectName,
      subjectDescription,
      topicsOrChapters,
      numberOfNodes,
    );

    // 2. Tạo Learning Nodes và Content Items
    const savedNodes: LearningNode[] = [];

    for (const nodeData of nodesStructure) {
      // Tạo Learning Node
      const node = this.nodeRepository.create({
        subjectId,
        title: nodeData.title,
        description: nodeData.description,
        order: nodeData.order,
        prerequisites: [], // Sẽ cập nhật sau
        contentStructure: {
          concepts: nodeData.concepts.length,
          examples: nodeData.examples?.length || 0,
          hiddenRewards: nodeData.hiddenRewards?.length || 0,
          bossQuiz: 1,
        },
        metadata: {
          icon: nodeData.icon,
          position: { x: (nodeData.order - 1) * 100, y: 0 },
        },
      });

      const savedNode = await this.nodeRepository.save(node);
      savedNodes.push(savedNode);

      // Cập nhật prerequisites: node sau phụ thuộc node trước
      if (savedNodes.length > 1) {
        const prevNode = savedNodes[savedNodes.length - 2];
        savedNode.prerequisites = [prevNode.id];
        await this.nodeRepository.save(savedNode);
      }

      // Tạo Concepts
      for (let i = 0; i < nodeData.concepts.length; i++) {
        const concept = this.contentItemRepository.create({
          nodeId: savedNode.id,
          type: 'concept',
          title: nodeData.concepts[i].title,
          content: nodeData.concepts[i].content,
          order: i + 1,
          rewards: { xp: 10, coin: 1 },
        });
        await this.contentItemRepository.save(concept);
      }

      // Tạo Examples (AI đã tạo sẵn)
      if (nodeData.examples && nodeData.examples.length > 0) {
        for (let i = 0; i < nodeData.examples.length; i++) {
          const example = this.contentItemRepository.create({
            nodeId: savedNode.id,
            type: 'example',
            title: nodeData.examples[i].title,
            content: nodeData.examples[i].content,
            order: i + 1,
            rewards: { xp: 15, coin: 2 },
          });
          await this.contentItemRepository.save(example);
        }
      }

      // Tạo Hidden Rewards (AI đã tạo sẵn)
      if (nodeData.hiddenRewards && nodeData.hiddenRewards.length > 0) {
        for (let i = 0; i < nodeData.hiddenRewards.length; i++) {
          const reward = this.contentItemRepository.create({
            nodeId: savedNode.id,
            type: 'hidden_reward',
            title: nodeData.hiddenRewards[i].title,
            content: nodeData.hiddenRewards[i].content,
            order: 50 + i, // Sau examples, trước boss quiz
            rewards: { xp: 5, coin: 5 },
          });
          await this.contentItemRepository.save(reward);
        }
      }

      // Tạo Boss Quiz (AI đã tạo sẵn với nội dung chất lượng)
      const bossQuiz = this.contentItemRepository.create({
        nodeId: savedNode.id,
        type: 'boss_quiz',
        title: `Boss Quiz: ${nodeData.title}`,
        content: `Kiểm tra kiến thức về ${nodeData.title}`,
        order: 100,
        quizData: {
          question: nodeData.bossQuiz.question,
          options: nodeData.bossQuiz.options,
          correctAnswer: nodeData.bossQuiz.correctAnswer,
          explanation: nodeData.bossQuiz.explanation,
        },
        rewards: { xp: 50, coin: 10 },
      });
      await this.contentItemRepository.save(bossQuiz);

      const totalItems = nodeData.concepts.length + 
                        (nodeData.examples?.length || 0) + 
                        (nodeData.hiddenRewards?.length || 0) + 
                        1; // boss quiz
      console.log(`✅ Created node: ${nodeData.title} (${nodeData.concepts.length} concepts, ${nodeData.examples?.length || 0} examples, ${nodeData.hiddenRewards?.length || 0} rewards, 1 quiz)`);
    }

    console.log(`\n✅ Successfully generated ${savedNodes.length} Learning Nodes with AI!`);
    return savedNodes;
  }
}

