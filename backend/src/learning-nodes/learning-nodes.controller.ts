import { Controller, Get, Param, Post, Put, Body, UseGuards, NotFoundException, Request, ForbiddenException } from '@nestjs/common';
import { LearningNodesService } from './learning-nodes.service';
import { LessonContentService } from './lesson-content.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../auth/guards/optional-jwt-auth.guard';
import { UpdateLessonContentDto } from './dto/lesson-content.dto';

@Controller('nodes')
export class LearningNodesController {
  constructor(
    private readonly nodesService: LearningNodesService,
    private readonly lessonContentService: LessonContentService,
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
        message: 'Bạn cần nâng cấp Premium để truy cập bài học này',
        requiresPremium: true,
      });
    }
    
    return this.nodesService.findById(id);
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
  @UseGuards(OptionalJwtAuthGuard)
  async getLessonData(@Param('id') id: string) {
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
    @Param('id') id: string,
    @Body() body: { answers: number[] },
  ) {
    return this.lessonContentService.submitEndQuiz(id, body.answers);
  }

  /**
   * Submit end quiz for a specific lesson type (from lesson_type_contents)
   */
  @Post(':id/submit-quiz/:lessonType')
  @UseGuards(JwtAuthGuard)
  async submitEndQuizForType(
    @Param('id') id: string,
    @Param('lessonType') lessonType: string,
    @Body() body: { answers: number[] },
  ) {
    return this.lessonContentService.submitEndQuizForType(id, lessonType, body.answers);
  }

  /**
   * Get lesson data for a specific type (from lesson_type_contents)
   */
  @Get(':id/lesson/:lessonType')
  @UseGuards(OptionalJwtAuthGuard)
  async getLessonDataByType(
    @Param('id') id: string,
    @Param('lessonType') lessonType: string,
  ) {
    return this.lessonContentService.getLessonDataByType(id, lessonType);
  }
}

