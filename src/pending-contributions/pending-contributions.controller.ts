import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from '../auth/guards/admin.guard';
import { ContributorGuard } from '../auth/guards/contributor.guard';
import { PendingContributionsService } from './pending-contributions.service';
import {
  ContributionType,
  ContributionStatus,
} from './entities/pending-contribution.entity';

@Controller('pending-contributions')
@UseGuards(JwtAuthGuard)
export class PendingContributionsController {
  constructor(
    private readonly service: PendingContributionsService,
  ) {}

  // =====================
  // Contributor Endpoints
  // =====================

  @Post('subject')
  @UseGuards(ContributorGuard)
  async createSubjectContribution(
    @Request() req,
    @Body() body: { name: string; description?: string; track?: 'explorer' | 'scholar' },
  ) {
    return this.service.createSubjectContribution(req.user.id, body);
  }

  @Post('domain')
  @UseGuards(ContributorGuard)
  async createDomainContribution(
    @Request() req,
    @Body() body: {
      name: string;
      description?: string;
      subjectId: string;
      difficulty?: 'easy' | 'medium' | 'hard';
      afterEntityId?: string;
      expReward?: number;
      coinReward?: number;
    },
  ) {
    return this.service.createDomainContribution(req.user.id, body);
  }

  @Post('topic')
  @UseGuards(ContributorGuard)
  async createTopicContribution(
    @Request() req,
    @Body()
    body: {
      name: string;
      description?: string;
      domainId: string;
      subjectId: string;
      difficulty?: 'easy' | 'medium' | 'hard';
      afterEntityId?: string;
      expReward?: number;
      coinReward?: number;
    },
  ) {
    return this.service.createTopicContribution(req.user.id, body);
  }

  @Post('lesson')
  @UseGuards(ContributorGuard)
  async createLessonContribution(
    @Request() req,
    @Body()
    body: {
      title: string;
      content?: string;
      richContent?: any;
      nodeId?: string;
      subjectId: string;
      domainId?: string;
      topicId?: string;
      description?: string;
      // New lesson type fields
      lessonType?: 'image_quiz' | 'image_gallery' | 'video' | 'text';
      lessonData?: Record<string, any>;
      endQuiz?: Record<string, any>;
      topicName?: string;
      // Ordering & rewards
      difficulty?: 'easy' | 'medium' | 'hard';
      afterEntityId?: string;
      expReward?: number;
      coinReward?: number;
    },
  ) {
    return this.service.createLessonContribution(req.user.id, body);
  }

  // Propose editing lesson type content
  @Post('lesson-content-edit')
  @UseGuards(ContributorGuard)
  async createLessonContentEditContribution(
    @Request() req,
    @Body()
    body: {
      nodeId: string;
      lessonType: 'image_quiz' | 'image_gallery' | 'video' | 'text';
      lessonData: Record<string, any>;
      endQuiz?: Record<string, any>;
      reason?: string;
    },
  ) {
    return this.service.createLessonContentEditContribution(req.user.id, body);
  }

  // Propose editing (renaming) an existing entity
  @Post('edit')
  @UseGuards(ContributorGuard)
  async createEditContribution(
    @Request() req,
    @Body()
    body: {
      type: ContributionType; // subject, domain, topic, lesson
      entityId: string;
      newName: string;
      newDescription?: string;
      reason?: string;
    },
  ) {
    return this.service.createEditContribution(req.user.id, body);
  }

  // Propose deleting an existing entity
  @Post('delete')
  @UseGuards(ContributorGuard)
  async createDeleteContribution(
    @Request() req,
    @Body()
    body: {
      type: ContributionType; // subject, domain, topic, lesson
      entityId: string;
      reason?: string;
    },
  ) {
    return this.service.createDeleteContribution(req.user.id, body);
  }

  // Get my contributions
  @Get('my')
  async getMyContributions(@Request() req) {
    return this.service.findMyContributions(req.user.id);
  }

  // Get contribution by id
  @Get(':id')
  async getContribution(@Param('id') id: string) {
    return this.service.findById(id);
  }

  // Update my contribution (only pending)
  @Put(':id')
  @UseGuards(ContributorGuard)
  async updateContribution(
    @Request() req,
    @Param('id') id: string,
    @Body()
    body: { title?: string; description?: string; data?: Record<string, any> },
  ) {
    return this.service.updateContribution(id, req.user.id, body);
  }

  // Delete my contribution (only pending)
  @Delete(':id')
  @UseGuards(ContributorGuard)
  async deleteContribution(@Request() req, @Param('id') id: string) {
    await this.service.deleteContribution(id, req.user.id);
    return { message: 'Contribution deleted' };
  }

  // =====================
  // Admin Endpoints
  // =====================

  // Get all contributions (with filters)
  @Get()
  @UseGuards(AdminGuard)
  async getAllContributions(
    @Query('type') type?: ContributionType,
    @Query('status') status?: ContributionStatus,
  ) {
    return this.service.findAll({ type, status });
  }

  // Get all pending contributions
  @Get('admin/pending')
  @UseGuards(AdminGuard)
  async getPendingContributions() {
    return this.service.findPending();
  }

  // Approve contribution
  @Put(':id/approve')
  @UseGuards(AdminGuard)
  async approveContribution(
    @Request() req,
    @Param('id') id: string,
    @Body() body?: { note?: string },
  ) {
    return this.service.approveContribution(id, req.user.id, body?.note);
  }

  // Reject contribution
  @Put(':id/reject')
  @UseGuards(AdminGuard)
  async rejectContribution(
    @Request() req,
    @Param('id') id: string,
    @Body() body?: { note?: string },
  ) {
    return this.service.rejectContribution(id, req.user.id, body?.note);
  }
}
