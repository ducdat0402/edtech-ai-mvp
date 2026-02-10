import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import { TopicsService } from './topics.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';

@Controller('topics')
export class TopicsController {
  constructor(private readonly topicsService: TopicsService) {}

  /**
   * Lấy tất cả topics của một domain
   */
  @Get('domain/:domainId')
  @UseGuards(JwtAuthGuard)
  async getTopicsByDomain(@Param('domainId') domainId: string) {
    return this.topicsService.findByDomain(domainId);
  }

  /**
   * Lấy topic theo ID (kèm learning nodes)
   */
  @Get(':id')
  @UseGuards(JwtAuthGuard)
  async getTopic(@Param('id') id: string) {
    return this.topicsService.findById(id);
  }

  /**
   * Tạo topic mới (Admin only)
   */
  @Post()
  @UseGuards(JwtAuthGuard, AdminGuard)
  async createTopic(
    @Body()
    body: {
      domainId: string;
      name: string;
      description?: string;
      order?: number;
      metadata?: any;
    },
  ) {
    return this.topicsService.create(body.domainId, {
      name: body.name,
      description: body.description,
      order: body.order,
      metadata: body.metadata,
    });
  }

  /**
   * Cập nhật topic (Admin only)
   */
  @Put(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async updateTopic(
    @Param('id') id: string,
    @Body()
    body: { name?: string; description?: string; order?: number; metadata?: any },
  ) {
    return this.topicsService.update(id, body);
  }

  /**
   * Xóa topic (Admin only)
   */
  @Delete(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async deleteTopic(@Param('id') id: string) {
    await this.topicsService.delete(id);
    return { message: 'Topic deleted successfully' };
  }
}
