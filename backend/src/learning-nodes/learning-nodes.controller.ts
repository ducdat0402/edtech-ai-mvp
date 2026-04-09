import {
  Controller,
  Get,
  Param,
  Post,
  Put,
  Body,
  UseGuards,
  NotFoundException,
  Request,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { instanceToPlain } from 'class-transformer';
import { LearningNodesService } from './learning-nodes.service';
import { LessonContentService } from './lesson-content.service';
import { AiService } from '../ai/ai.service';
import { UserCurrencyService } from '../user-currency/user-currency.service';
import { UsersService } from '../users/users.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../auth/guards/optional-jwt-auth.guard';
import { UpdateLessonContentDto } from './dto/lesson-content.dto';
import { AiUsageService } from './ai-usage.service';
import { UnlockTransactionsService } from '../unlock-transactions/unlock-transactions.service';

// Diamond costs for AI features
const AI_COST = {
  GENERATE_EXAMPLE: 10,
  GENERATE_QUIZ_EXPLANATIONS: 5,
};

@Controller('nodes')
export class LearningNodesController {
  constructor(
    private readonly nodesService: LearningNodesService,
    private readonly lessonContentService: LessonContentService,
    private readonly aiService: AiService,
    private readonly userCurrencyService: UserCurrencyService,
    private readonly usersService: UsersService,
    private readonly aiUsageService: AiUsageService,
    private readonly unlockService: UnlockTransactionsService,
  ) {}

  /**
   * Get nodes by subject with premium lock status
   */
  @Get('subject/:subjectId')
  @UseGuards(OptionalJwtAuthGuard)
  async getNodesBySubject(
    @Param('subjectId') subjectId: string,
    @Request() req,
  ) {
    const userId = req.user?.id;
    return this.nodesService.findBySubjectWithPremiumStatus(subjectId, userId);
  }

  /**
   * Get nodes by topic
   */
  @Get('topic/:topicId')
  async getNodesByTopic(@Param('topicId') topicId: string) {
    return this.nodesService.findByTopic(topicId);
  }

  /**
   * Get node by ID with access check
   */
  @Get(':id')
  @UseGuards(OptionalJwtAuthGuard)
  async getNodeById(@Param('id') id: string, @Request() req) {
    const userId = req.user?.id;
    
    // Check if user can access this node
    const accessCheck = await this.nodesService.canAccessNode(id, userId);
    
    if (!accessCheck.canAccess) {
      throw new ForbiddenException({
        message:
          'Mỗi ngày có 2 bài miễn phí (mọi môn). Hết suất miễn phí: 50 💎/bài — hoặc mở khóa cả chủ đề/chương/môn.',
        requiresUnlock: true,
        remainingFreeLessonsToday: accessCheck.remainingFreeLessonsToday,
        diamondCost: accessCheck.diamondCost,
        userDiamonds: accessCheck.userDiamonds,
      });
    }

    const node = await this.nodesService.findById(id);
    if (!node) {
      throw new NotFoundException('Learning node not found');
    }
    const plain = instanceToPlain(node) as Record<string, unknown>;
    let contributor: {
      id: string;
      fullName: string;
      avatarUrl: string | null;
    } | null = null;
    if (node.contributorId) {
      const u = await this.usersService.findById(node.contributorId);
      if (u) {
        contributor = {
          id: u.id,
          fullName: (u.fullName && u.fullName.trim()) || 'Thành viên',
          avatarUrl: u.avatarUrl ?? null,
        };
      }
    }
    return { ...plain, contributor };
  }

  /**
   * Check if user can access a node
   */
  @Get(':id/access-check')
  @UseGuards(OptionalJwtAuthGuard)
  async checkNodeAccess(@Param('id') id: string, @Request() req) {
    const userId = req.user?.id;
    return this.nodesService.canAccessNode(id, userId);
  }

  /**
   * Tự động tạo Learning Nodes từ dữ liệu thô
   * AI tự động tạo đầy đủ: concepts, examples, hidden rewards, boss quiz
   * Không cần import thêm, user có thể chỉnh sửa sau nếu cần
   */
  @Post('generate-from-raw')
  @UseGuards(JwtAuthGuard)
  async generateNodesFromRaw(
    @Body() body: {
      subjectId: string;
      subjectName: string;
      subjectDescription?: string;
      topicsOrChapters?: string[];
      numberOfNodes?: number;
    },
  ) {
    return this.nodesService.generateNodesFromRawData(
      body.subjectId,
      body.subjectName,
      body.subjectDescription,
      body.topicsOrChapters,
      body.numberOfNodes || 10,
    );
  }

  /**
   * Cập nhật Learning Node (title, description, order, etc.)
   * User có thể chỉnh sửa nếu không phù hợp
   */
  @Put(':id')
  @UseGuards(JwtAuthGuard)
  async updateNode(
    @Param('id') id: string,
    @Body() body: {
      title?: string;
      description?: string;
      order?: number;
      prerequisites?: string[];
      metadata?: { icon?: string; position?: { x: number; y: number } };
    },
  ) {
    const node = await this.nodesService.findById(id);
    if (!node) {
      throw new NotFoundException('Learning node not found');
    }

    if (body.title) node.title = body.title;
    if (body.description !== undefined) node.description = body.description;
    if (body.order !== undefined) node.order = body.order;
    if (body.prerequisites) node.prerequisites = body.prerequisites;
    if (body.metadata) node.metadata = { ...node.metadata, ...body.metadata };

    return this.nodesService['nodeRepository'].save(node);
  }

  // === Lesson Content APIs ===

  /**
   * Get full lesson data (viewer)
   */
  @Get(':id/lesson')
  @UseGuards(JwtAuthGuard)
  async getLessonData(@Request() req, @Param('id') id: string) {
    const access = await this.unlockService.canAccessNode(req.user.id, id);
    if (!access.canAccess) {
      throw new ForbiddenException({
        message: 'Bài học đang bị khóa. Vui lòng mở khóa để xem nội dung.',
        ...access,
      });
    }
    return this.lessonContentService.getLessonData(id);
  }

  /**
   * Update lesson content (contributor/admin)
   */
  @Put(':id/lesson-content')
  @UseGuards(JwtAuthGuard)
  async updateLessonContent(
    @Param('id') id: string,
    @Body() body: UpdateLessonContentDto,
  ) {
    return this.lessonContentService.updateLessonContent(id, body);
  }

  /**
   * AI generate end quiz suggestions
   */
  @Post(':id/end-quiz/generate')
  @UseGuards(JwtAuthGuard)
  async generateEndQuiz(@Param('id') id: string) {
    return this.lessonContentService.generateEndQuiz(id);
  }

  /**
   * Submit end quiz answers (legacy - reads from node's endQuiz)
   */
  @Post(':id/submit-quiz')
  @UseGuards(JwtAuthGuard)
  async submitEndQuiz(
    @Request() req,
    @Param('id') id: string,
    @Body()
    body: {
      answers: number[];
      responseTimesMs?: number[];
      confidencePercent?: number;
    },
  ) {
    return this.lessonContentService.submitEndQuiz(
      id,
      body.answers,
      req.user.id,
      body.confidencePercent,
      body.responseTimesMs,
    );
  }

  /**
   * Submit end quiz for a specific lesson type (from lesson_type_contents)
   */
  @Post(':id/submit-quiz/:lessonType')
  @UseGuards(JwtAuthGuard)
  async submitEndQuizForType(
    @Request() req,
    @Param('id') id: string,
    @Param('lessonType') lessonType: string,
    @Body()
    body: {
      answers: number[];
      responseTimesMs?: number[];
      confidencePercent?: number;
    },
  ) {
    return this.lessonContentService.submitEndQuizForType(
      id,
      lessonType,
      body.answers,
      req.user.id,
      body.confidencePercent,
      body.responseTimesMs,
    );
  }

  /**
   * Submit communication reflection (voluntary)
   */
  @Post(':id/communication-attempt')
  @UseGuards(JwtAuthGuard)
  async submitCommunicationAttempt(
    @Request() req,
    @Param('id') id: string,
    @Body()
    body: {
      responseText: string;
      lessonType?: string;
    },
  ) {
    return this.lessonContentService.submitCommunicationAttempt({
      nodeId: id,
      userId: req.user.id,
      responseText: body.responseText,
      lessonType: body.lessonType,
    });
  }

  /**
   * Get lesson data for a specific type (from lesson_type_contents)
   */
  @Get(':id/lesson/:lessonType')
  @UseGuards(JwtAuthGuard)
  async getLessonDataByType(
    @Request() req,
    @Param('id') id: string,
    @Param('lessonType') lessonType: string,
  ) {
    const access = await this.unlockService.canAccessNode(req.user.id, id);
    if (!access.canAccess) {
      throw new ForbiddenException({
        message: 'Bài học đang bị khóa. Vui lòng mở khóa để xem nội dung.',
        ...access,
      });
    }
    return this.lessonContentService.getLessonDataByType(id, lessonType);
  }

  /**
   * AI generate example for a lesson
   */
  /**
   * Get AI feature costs (diamond prices)
   */
  @Get('ai-costs')
  getAICosts() {
    return {
      generateExample: AI_COST.GENERATE_EXAMPLE,
      generateQuizExplanations: AI_COST.GENERATE_QUIZ_EXPLANATIONS,
    };
  }

  @Post('generate-example')
  @UseGuards(JwtAuthGuard)
  async generateExample(
    @Request() req,
    @Body() body: { title: string; content: string; exampleType: string },
  ) {
    const { title, content, exampleType } = body;
    const userId = req.user.id;

    if (!title || title.trim().length < 5) {
      throw new BadRequestException(
        'Tiêu đề bài học quá ngắn. Vui lòng nhập tiêu đề ít nhất 5 ký tự.',
      );
    }
    if (!content || content.trim().length < 20) {
      throw new BadRequestException(
        'Nội dung bài học quá ngắn hoặc mơ hồ. Vui lòng bổ sung nội dung ít nhất 20 ký tự để AI tạo ví dụ chính xác hơn.',
      );
    }

    const validTypes = [
      'real_world_scenario',
      'everyday_analogy',
      'hypothetical_situation',
      'technical_implementation',
      'step_by_step',
      'comparison',
      'story_narrative',
    ];
    if (!validTypes.includes(exampleType)) {
      throw new BadRequestException(
        `Loại ví dụ không hợp lệ. Chọn một trong: ${validTypes.join(', ')}`,
      );
    }

    // Check and deduct diamonds
    const hasEnough = await this.userCurrencyService.hasEnoughDiamonds(userId, AI_COST.GENERATE_EXAMPLE);
    if (!hasEnough) {
      throw new BadRequestException(
        `Không đủ kim cương. Cần ${AI_COST.GENERATE_EXAMPLE} 💎 để sử dụng tính năng này.`,
      );
    }
    await this.userCurrencyService.deductDiamonds(userId, AI_COST.GENERATE_EXAMPLE);

    return this.aiService.generateExample(title.trim(), content.trim(), exampleType);
  }

  @Post('generate-quiz-explanations')
  @UseGuards(JwtAuthGuard)
  async generateQuizExplanations(
    @Request() req,
    @Body()
    body: {
      question: string;
      options: Array<{ text: string }>;
      correctAnswer: number;
      context?: string;
    },
  ) {
    const { question, options, correctAnswer, context } = body;
    const userId = req.user.id;

    if (!question || question.trim().length < 5) {
      throw new BadRequestException(
        'Câu hỏi quá ngắn. Vui lòng nhập câu hỏi ít nhất 5 ký tự.',
      );
    }

    if (!Array.isArray(options) || options.length !== 4) {
      throw new BadRequestException('Cần đúng 4 đáp án (A, B, C, D).');
    }

    for (let i = 0; i < options.length; i++) {
      if (!options[i]?.text || options[i].text.trim().length === 0) {
        throw new BadRequestException(
          `Đáp án ${['A', 'B', 'C', 'D'][i]} không được để trống.`,
        );
      }
    }

    if (
      typeof correctAnswer !== 'number' ||
      correctAnswer < 0 ||
      correctAnswer > 3
    ) {
      throw new BadRequestException(
        'Đáp án đúng phải là số từ 0 đến 3 (tương ứng A-D).',
      );
    }

    // Check and deduct diamonds
    const hasEnough = await this.userCurrencyService.hasEnoughDiamonds(userId, AI_COST.GENERATE_QUIZ_EXPLANATIONS);
    if (!hasEnough) {
      throw new BadRequestException(
        `Không đủ kim cương. Cần ${AI_COST.GENERATE_QUIZ_EXPLANATIONS} 💎 để sử dụng tính năng này.`,
      );
    }
    await this.userCurrencyService.deductDiamonds(userId, AI_COST.GENERATE_QUIZ_EXPLANATIONS);

    return this.aiService.generateQuizExplanations(
      question.trim(),
      options.map((o) => ({ text: o.text.trim() })),
      correctAnswer,
      context?.trim() || undefined,
    );
  }

  @Post('simplify-text')
  @UseGuards(JwtAuthGuard)
  async simplifyTextLesson(
    @Request() req,
    @Body() body: { nodeId: string; title?: string; content: string },
  ) {
    const userId = req.user.id;
    const nodeId = (body.nodeId || '').toString().trim();
    const title = (body.title || '').toString().trim();
    const content = (body.content || '').toString().trim();

    if (!nodeId) {
      throw new BadRequestException('Thiếu nodeId.');
    }
    if (!content) {
      throw new BadRequestException('Thiếu nội dung bài học.');
    }

    const wordCount = content.split(/\s+/).filter(Boolean).length;
    if (wordCount < 50) {
      throw new BadRequestException(
        'Bài học quá ngắn, không thể đơn giản hóa hơn được nữa.',
      );
    }

    const FREE_LIMIT = 5;
    const usage = await this.aiUsageService.consumeFreeOrThrow({
      userId,
      buttonType: 'simplify_text',
      freeLimit: FREE_LIMIT,
    });

    const simplifiedText = await this.aiService.simplifyTextLesson({
      title: title || `Node ${nodeId}`,
      content,
    });

    return {
      simplifiedText,
      remainingFreeUsesToday: usage.remainingFreeUsesToday,
      freeLimit: FREE_LIMIT,
    };
  }
}

