import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Roadmap, RoadmapStatus } from './entities/roadmap.entity';
import { RoadmapDay, DayStatus } from './entities/roadmap-day.entity';
import { UsersService } from '../users/users.service';
import { SubjectsService } from '../subjects/subjects.service';
import { LearningNodesService } from '../learning-nodes/learning-nodes.service';
import { PlacementTestService } from '../placement-test/placement-test.service';

@Injectable()
export class RoadmapService {
  constructor(
    @InjectRepository(Roadmap)
    private roadmapRepository: Repository<Roadmap>,
    @InjectRepository(RoadmapDay)
    private roadmapDayRepository: Repository<RoadmapDay>,
    private usersService: UsersService,
    private subjectsService: SubjectsService,
    private nodesService: LearningNodesService,
    private testService: PlacementTestService,
  ) {}

  async generateRoadmap(
    userId: string,
    subjectId: string,
  ): Promise<Roadmap> {
    // Check if user already has an active roadmap for this subject
    const existing = await this.roadmapRepository.findOne({
      where: {
        userId,
        subjectId,
        status: RoadmapStatus.ACTIVE,
      },
    });

    if (existing) {
      return existing;
    }

    // Get user data
    const user = await this.usersService.findById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Get subject
    const subject = await this.subjectsService.findById(subjectId);
    if (!subject) {
      throw new NotFoundException('Subject not found');
    }

    // Get placement test result
    const placementTestLevel = user.placementTestLevel || 'beginner';
    const onboardingData = user.onboardingData || {};

    // Get all nodes for this subject
    let nodes = await this.nodesService.findBySubject(subjectId);
    
    // ✅ Nếu chưa có nodes, tự động tạo bằng AI
    if (nodes.length === 0) {
      console.log(`⚠️  No learning nodes found for subject "${subject.name}". Auto-generating with AI...`);
      
      try {
        // Tự động tạo 10-15 nodes tùy theo subject
        const numberOfNodes = 12; // Có thể điều chỉnh dựa trên subject type
        
        // Lấy thông tin từ onboarding để tạo nodes phù hợp hơn
        const subjectName = subject.name;
        const subjectDescription = subject.description;
        
        // Nếu có topics từ metadata hoặc description, extract ra
        let topics: string[] | undefined;
        if (subject.metadata && (subject.metadata as any).topics) {
          topics = (subject.metadata as any).topics;
        }
        
        // Tự động tạo nodes bằng AI
        const generatedNodes = await this.nodesService.generateNodesFromRawData(
          subjectId,
          subjectName,
          subjectDescription,
          topics,
          numberOfNodes,
        );
        
        nodes = generatedNodes;
        console.log(`✅ Auto-generated ${nodes.length} Learning Nodes for "${subjectName}"`);
      } catch (error) {
        console.error('❌ Error auto-generating learning nodes:', error);
        throw new BadRequestException(
          `Failed to generate learning nodes for this subject. Please try again later. Error: ${error.message}`,
        );
      }
    }
    
    // Đảm bảo có ít nhất 1 node
    if (nodes.length === 0) {
      throw new BadRequestException('No learning nodes available for this subject');
    }

    // Create roadmap
    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + 30);

    const roadmap = this.roadmapRepository.create({
      userId,
      subjectId,
      status: RoadmapStatus.ACTIVE,
      totalDays: 30,
      currentDay: 1,
      startDate,
      endDate,
      metadata: {
        level: placementTestLevel,
        interests: onboardingData.interests || [],
        learningGoals: onboardingData.learningGoals,
        estimatedHoursPerDay: this.getEstimatedHours(placementTestLevel),
      },
    });

    const savedRoadmap = await this.roadmapRepository.save(roadmap);

    // Generate 30 days of learning
    await this.generateDays(savedRoadmap, nodes, placementTestLevel);

    return savedRoadmap;
  }

  private async generateDays(
    roadmap: Roadmap,
    nodes: any[],
    level: string,
  ): Promise<void> {
    const days: RoadmapDay[] = [];
    const startDate = new Date(roadmap.startDate);

    // Distribute nodes across 30 days
    // Days 1-10: Beginner nodes (20% of content)
    // Days 11-20: Intermediate nodes (50% of content)
    // Days 21-30: Advanced nodes + Review (30% of content)

    const beginnerNodes = nodes.slice(0, Math.ceil(nodes.length * 0.2));
    const intermediateNodes = nodes.slice(
      Math.ceil(nodes.length * 0.2),
      Math.ceil(nodes.length * 0.7),
    );
    const advancedNodes = nodes.slice(Math.ceil(nodes.length * 0.7));

    for (let day = 1; day <= 30; day++) {
      const scheduledDate = new Date(startDate);
      scheduledDate.setDate(startDate.getDate() + day - 1);

      let node: any = null;
      let content: any = null;

      if (day <= 10) {
        // Beginner phase
        if (beginnerNodes.length > 0) {
          const nodeIndex = Math.min(
            Math.floor((day - 1) / Math.max(10 / beginnerNodes.length, 1)),
            beginnerNodes.length - 1,
          );
          node = beginnerNodes[nodeIndex];
        } else if (nodes.length > 0) {
          node = nodes[0];
        }
        if (node) {
          content = {
            title: `Ngày ${day}: ${node.title}`,
            description: `Học các khái niệm cơ bản về ${node.title}`,
            estimatedMinutes: 15,
            type: 'video',
          };
        }
      } else if (day <= 20) {
        // Intermediate phase
        if (intermediateNodes.length > 0) {
          const nodeIndex = Math.min(
            Math.floor((day - 11) / Math.max(10 / intermediateNodes.length, 1)),
            intermediateNodes.length - 1,
          );
          node = intermediateNodes[nodeIndex];
        } else if (nodes.length > 0) {
          node = nodes[0];
        }
        content = {
          title: `Ngày ${day}: ${node.title}`,
          description: `Thực hành và áp dụng ${node.title}`,
          estimatedMinutes: 20,
          type: 'quiz',
        };
      } else if (day <= 25) {
        // Advanced phase
        const nodeIndex = Math.floor((day - 21) / (5 / advancedNodes.length));
        node = advancedNodes[nodeIndex] || advancedNodes[0];
        content = {
          title: `Ngày ${day}: ${node.title}`,
          description: `Học chuyên sâu về ${node.title}`,
          estimatedMinutes: 25,
          type: 'simulation',
        };
      } else {
        // Review phase (days 26-30)
        // Spaced repetition: Review nodes from days 1-15
        const reviewDay = day - 25; // 1-5
        const reviewNodeIndex = (reviewDay - 1) * 3; // Review 3 nodes per day
        const reviewNodes = [...beginnerNodes, ...intermediateNodes].slice(
          reviewNodeIndex,
          reviewNodeIndex + 3,
        );

        content = {
          title: `Ngày ${day}: Ôn tập`,
          description: `Ôn lại các bài đã học`,
          estimatedMinutes: 20,
          type: 'review',
          reviewItems: reviewNodes.map((n) => n.id),
        };
      }

      const roadmapDay = this.roadmapDayRepository.create({
        roadmapId: roadmap.id,
        dayNumber: day,
        scheduledDate,
        status: DayStatus.PENDING,
        nodeId: node?.id || null,
        content,
      });

      days.push(roadmapDay);
    }

    await this.roadmapDayRepository.save(days);
  }

  async getRoadmap(userId: string, subjectId?: string): Promise<Roadmap | null> {
    const where: any = { userId, status: RoadmapStatus.ACTIVE };
    if (subjectId) {
      where.subjectId = subjectId;
    }

    return this.roadmapRepository.findOne({
      where,
      relations: ['days', 'subject'],
      order: { createdAt: 'DESC' },
    });
  }

  async getTodayLesson(userId: string, roadmapId: string): Promise<{
    roadmap: Roadmap;
    today: RoadmapDay | null;
    progress: { completed: number; total: number; percentage: number };
  }> {
    const roadmap = await this.roadmapRepository.findOne({
      where: { id: roadmapId, userId },
      relations: ['days'],
    });

    if (!roadmap) {
      throw new NotFoundException('Roadmap not found');
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const todayDay = roadmap.days.find((day) => {
      const dayDate = new Date(day.scheduledDate);
      dayDate.setHours(0, 0, 0, 0);
      return dayDate.getTime() === today.getTime();
    });

    // If no exact match, get current day based on roadmap progress
    const currentDay = todayDay || roadmap.days.find((d) => d.dayNumber === roadmap.currentDay);

    const completedDays = roadmap.days.filter(
      (d) => d.status === DayStatus.COMPLETED,
    ).length;

    return {
      roadmap,
      today: currentDay || null,
      progress: {
        completed: completedDays,
        total: roadmap.totalDays,
        percentage: Math.round((completedDays / roadmap.totalDays) * 100),
      },
    };
  }

  async completeDay(userId: string, roadmapId: string, dayNumber: number): Promise<RoadmapDay> {
    const roadmap = await this.roadmapRepository.findOne({
      where: { id: roadmapId, userId },
    });

    if (!roadmap) {
      throw new NotFoundException('Roadmap not found');
    }

    const day = await this.roadmapDayRepository.findOne({
      where: { roadmapId, dayNumber },
    });

    if (!day) {
      throw new NotFoundException('Day not found');
    }

    day.status = DayStatus.COMPLETED;
    day.completedAt = new Date();

    // Update roadmap current day
    if (dayNumber >= roadmap.currentDay) {
      roadmap.currentDay = dayNumber + 1;
    }

    // Check if roadmap is completed
    const completedDays = await this.roadmapDayRepository.count({
      where: { roadmapId, status: DayStatus.COMPLETED },
    });

    if (completedDays >= roadmap.totalDays) {
      roadmap.status = RoadmapStatus.COMPLETED;
    }

    await this.roadmapRepository.save(roadmap);
    return this.roadmapDayRepository.save(day);
  }

  private getEstimatedHours(level: string): number {
    switch (level) {
      case 'beginner':
        return 15; // 15 phút/ngày
      case 'intermediate':
        return 20; // 20 phút/ngày
      case 'advanced':
        return 30; // 30 phút/ngày
      default:
        return 15;
    }
  }
}

