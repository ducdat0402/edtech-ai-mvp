import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CommunityService } from './community.service';
import { CreateCommunityStatusDto } from './dto/create-status.dto';
import { CreateCommunityCommentDto } from './dto/create-comment.dto';
import { ReactCommunityStatusDto } from './dto/react-status.dto';

@Controller('community')
@UseGuards(JwtAuthGuard)
export class CommunityController {
  constructor(private readonly communityService: CommunityService) {}

  @Get('statuses')
  async listStatuses(
    @Request() req,
    @Query('limit') limit?: string,
    @Query('before') before?: string,
  ) {
    return this.communityService.listStatuses(
      req.user.id,
      limit ? parseInt(limit, 10) : 20,
      before,
    );
  }

  @Post('statuses')
  async createStatus(@Request() req, @Body() dto: CreateCommunityStatusDto) {
    return this.communityService.createStatus(req.user.id, dto);
  }

  @Delete('statuses/:id')
  async deleteStatus(@Request() req, @Param('id') id: string) {
    return this.communityService.deleteStatus(req.user.id, id);
  }

  @Post('statuses/:id/react')
  async react(
    @Request() req,
    @Param('id') id: string,
    @Body() dto: ReactCommunityStatusDto,
  ) {
    return this.communityService.setReaction(req.user.id, id, dto.kind);
  }

  @Get('statuses/:id/comments')
  async listComments(
    @Request() req,
    @Param('id') id: string,
    @Query('limit') limit?: string,
  ) {
    return this.communityService.listComments(
      req.user.id,
      id,
      limit ? parseInt(limit, 10) : 50,
    );
  }

  @Post('statuses/:id/comments')
  async addComment(
    @Request() req,
    @Param('id') id: string,
    @Body() dto: CreateCommunityCommentDto,
  ) {
    return this.communityService.addComment(req.user.id, id, dto);
  }
}
