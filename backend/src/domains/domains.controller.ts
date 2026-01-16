import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
import { DomainsService } from './domains.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';

@Controller('domains')
export class DomainsController {
  constructor(private readonly domainsService: DomainsService) {}

  /**
   * Lấy tất cả domains của một subject
   */
  @Get('subject/:subjectId')
  @UseGuards(JwtAuthGuard)
  async getDomainsBySubject(
    @Param('subjectId') subjectId: string,
    @Request() req: any,
  ) {
    // Optional: Include user progress
    if (req.query.includeProgress === 'true') {
      return this.domainsService.findBySubjectWithProgress(subjectId, req.user.id);
    }
    return this.domainsService.findBySubject(subjectId);
  }

  /**
   * Lấy domain theo ID
   */
  @Get(':id')
  @UseGuards(JwtAuthGuard)
  async getDomain(@Param('id') id: string) {
    return this.domainsService.findById(id);
  }

  /**
   * Tạo domain mới (Admin only)
   */
  @Post()
  @UseGuards(JwtAuthGuard, AdminGuard)
  async createDomain(@Body() body: { subjectId: string; name: string; description?: string; order?: number; metadata?: any }) {
    return this.domainsService.create(body.subjectId, {
      name: body.name,
      description: body.description,
      order: body.order,
      metadata: body.metadata,
    });
  }

  /**
   * Cập nhật domain (Admin only)
   */
  @Put(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async updateDomain(
    @Param('id') id: string,
    @Body() body: { name?: string; description?: string; order?: number; metadata?: any },
  ) {
    return this.domainsService.update(id, body);
  }

  /**
   * Xóa domain (Admin only)
   */
  @Delete(':id')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async deleteDomain(@Param('id') id: string) {
    await this.domainsService.delete(id);
    return { message: 'Domain deleted successfully' };
  }
}

