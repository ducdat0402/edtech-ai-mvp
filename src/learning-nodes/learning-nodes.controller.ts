import { Controller, Get, Param, Post, Put, Delete, Body, UseGuards, NotFoundException, Request, ForbiddenException, BadRequestException } from '@nestjs/common';
import { LearningNodesService } from './learning-nodes.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../auth/guards/optional-jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';

@Controller('nodes')
export class LearningNodesController {
  constructor(private readonly nodesService: LearningNodesService) {}

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

  // ============ ADMIN ENDPOINTS ============

  /**
   * Tạo Learning Node mới (Admin only)
   */
  @Post()
  @UseGuards(JwtAuthGuard, AdminGuard)
  async createNode(
    @Body() body: {
      subjectId: string;
      domainId?: string;
      title: string;
      description?: string;
      order?: number;
      type?: 'theory' | 'practice' | 'assessment';
      difficulty?: 'easy' | 'medium' | 'hard';
      prerequisites?: string[];
      metadata?: { icon?: string; position?: { x: number; y: number } };
    },
  ) {
    if (!body.subjectId || !body.title) {
      throw new BadRequestException('subjectId and title are required');
    }
    return this.nodesService.createNode(body);
  }

  /**
   * Xóa Learning Node (Admin only)
   * Cũng xóa tất cả content items thuộc node này
   */
  @Delete(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async deleteNode(@Param('id') id: string) {
    const node = await this.nodesService.findById(id);
    if (!node) {
      throw new NotFoundException('Learning node not found');
    }
    await this.nodesService.deleteNode(id);
    return { success: true, message: 'Learning node deleted successfully' };
  }
}

