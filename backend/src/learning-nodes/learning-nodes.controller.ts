import { Controller, Get, Param, Post, Put, Body, UseGuards, NotFoundException } from '@nestjs/common';
import { LearningNodesService } from './learning-nodes.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('nodes')
export class LearningNodesController {
  constructor(private readonly nodesService: LearningNodesService) {}

  @Get('subject/:subjectId')
  async getNodesBySubject(@Param('subjectId') subjectId: string) {
    return this.nodesService.findBySubject(subjectId);
  }

  @Get(':id')
  async getNodeById(@Param('id') id: string) {
    return this.nodesService.findById(id);
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
}

