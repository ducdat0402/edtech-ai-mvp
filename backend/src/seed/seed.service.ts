import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Subject } from '../subjects/entities/subject.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { Question } from '../placement-test/entities/question.entity';
import { DifficultyLevel } from '../placement-test/entities/placement-test.entity';

@Injectable()
export class SeedService {
  constructor(
    @InjectRepository(Subject)
    private subjectRepository: Repository<Subject>,
    @InjectRepository(LearningNode)
    private nodeRepository: Repository<LearningNode>,
    @InjectRepository(Question)
    private questionRepository: Repository<Question>,
  ) {}

  async seed() {
    console.log('🌱 Starting seed...');

    // Clear existing data
    try {
      const nodes = await this.nodeRepository.find();
      if (nodes.length > 0) {
        await this.nodeRepository.remove(nodes);
      }

      const subjects = await this.subjectRepository.find();
      if (subjects.length > 0) {
        await this.subjectRepository.remove(subjects);
      }

      const questions = await this.questionRepository.find();
      if (questions.length > 0) {
        await this.questionRepository.remove(questions);
      }
    } catch (error) {
      console.log('⚠️  Some tables might be empty, continuing...');
    }

    // 1. Create Explorer Subject: IC3 GS6 - Cybersecurity Basics
    const explorerSubject = this.subjectRepository.create({
      name: 'IC3 GS6 - Cybersecurity Basics',
      description: 'Học bảo mật cơ bản một cách thú vị',
      track: 'explorer',
      metadata: {
        icon: '🛡️',
        color: '#4CAF50',
        estimatedDays: 7,
      },
      unlockConditions: {
        minCoin: 0,
      },
    });
    const savedExplorerSubject = await this.subjectRepository.save(explorerSubject);

    // 2. Create Scholar Subject: IC3 GS6 - Advanced Security
    const scholarSubject = this.subjectRepository.create({
      name: 'IC3 GS6 - Advanced Security',
      description: 'Khóa học chuyên sâu về bảo mật',
      track: 'scholar',
      price: 100000,
      metadata: {
        icon: '🔐',
        color: '#2196F3',
        estimatedDays: 30,
      },
      unlockConditions: {
        minCoin: 20,
      },
    });
    await this.subjectRepository.save(scholarSubject);

    // 3. Create Sample Learning Node
    const passwordNode = this.nodeRepository.create({
      subjectId: savedExplorerSubject.id,
      title: 'Vệ Sĩ Mật Khẩu',
      description: 'Học cách tạo và bảo vệ mật khẩu an toàn',
      order: 1,
      prerequisites: [],
      contentStructure: {
        concepts: 0,
        examples: 0,
        hiddenRewards: 0,
        bossQuiz: 0,
      },
      metadata: {
        icon: '🔑',
        position: { x: 0, y: 0 },
      },
    });
    await this.nodeRepository.save(passwordNode);

    // 4. Create Sample Questions for Placement Test
    const sampleQuestions = [
      {
        subjectId: savedExplorerSubject.id,
        question: 'Phishing là gì?',
        options: [
          'Một loại virus máy tính',
          'Kỹ thuật lừa đảo qua email/website giả mạo để đánh cắp thông tin',
          'Một loại phần mềm diệt virus',
          'Công nghệ mã hóa dữ liệu',
        ],
        correctAnswer: 1,
        difficulty: DifficultyLevel.BEGINNER,
        explanation: 'Phishing là kỹ thuật tấn công social engineering.',
        metadata: { category: 'Social Engineering', tags: ['phishing', 'security-basics'] },
      },
      {
        subjectId: savedExplorerSubject.id,
        question: 'Mật khẩu mạnh nên có đặc điểm gì?',
        options: [
          'Chỉ cần dài là đủ',
          'Dài, có chữ hoa, chữ thường, số và ký tự đặc biệt',
          'Dễ nhớ như tên người yêu',
          'Chỉ cần số là đủ',
        ],
        correctAnswer: 1,
        difficulty: DifficultyLevel.BEGINNER,
        explanation: 'Mật khẩu mạnh cần kết hợp nhiều yếu tố.',
        metadata: { category: 'Password Security', tags: ['password', 'authentication'] },
      },
    ];

    const savedQuestions = [];
    for (const q of sampleQuestions) {
      const question = this.questionRepository.create({
        subjectId: q.subjectId,
        question: q.question,
        options: q.options,
        correctAnswer: q.correctAnswer,
        difficulty: q.difficulty,
        explanation: q.explanation,
        metadata: q.metadata,
      });
      savedQuestions.push(await this.questionRepository.save(question));
    }

    console.log('✅ Seed completed!');
    console.log(`   - Created 2 subjects`);
    console.log(`   - Created 1 learning node`);
    console.log(`   - Created ${savedQuestions.length} sample questions`);
  }

  /**
   * Seed Learning Nodes cho một subject (simplified - no content items)
   */
  async seedLearningNodesForSubject(
    subjectId: string,
    nodesData: Array<{
      title: string;
      description: string;
      order: number;
      prerequisites?: string[];
      icon?: string;
    }>,
  ): Promise<void> {
    console.log(`🌱 Seeding Learning Nodes for subject: ${subjectId}`);

    const subject = await this.subjectRepository.findOne({
      where: { id: subjectId },
    });

    if (!subject) {
      throw new Error(`Subject with ID ${subjectId} not found`);
    }

    const savedNodes: LearningNode[] = [];

    for (const nodeData of nodesData) {
      const node = this.nodeRepository.create({
        subjectId,
        title: nodeData.title,
        description: nodeData.description,
        order: nodeData.order,
        prerequisites: nodeData.prerequisites || [],
        contentStructure: {
          concepts: 0,
          examples: 0,
          hiddenRewards: 0,
          bossQuiz: 0,
        },
        metadata: {
          icon: nodeData.icon || '📚',
          position: { x: (nodeData.order - 1) * 100, y: 0 },
        },
      });

      const savedNode = await this.nodeRepository.save(node);
      savedNodes.push(savedNode);

      if (savedNodes.length > 1 && !nodeData.prerequisites) {
        const prevNode = savedNodes[savedNodes.length - 2];
        savedNode.prerequisites = [prevNode.id];
        await this.nodeRepository.save(savedNode);
      }

      console.log(`✅ Created node: ${nodeData.title}`);
    }

    console.log(`✅ Successfully seeded ${savedNodes.length} Learning Nodes!`);
  }
}
