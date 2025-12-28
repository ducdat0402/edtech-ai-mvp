import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { SkillTreeService } from './skill-tree.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('skill-tree')
@UseGuards(JwtAuthGuard)
export class SkillTreeController {
  constructor(private readonly skillTreeService: SkillTreeService) {}

  @Post('generate')
  async generateSkillTree(
    @Request() req,
    @Body() body: { subjectId: string },
  ) {
    return this.skillTreeService.generateSkillTree(req.user.id, body.subjectId);
  }

  @Get()
  async getSkillTree(@Request() req, @Body() body?: { subjectId?: string }) {
    return this.skillTreeService.getSkillTree(req.user.id, body?.subjectId);
  }

  @Post(':nodeId/unlock')
  async unlockNode(@Request() req, @Param('nodeId') nodeId: string) {
    return this.skillTreeService.unlockNode(req.user.id, nodeId);
  }

  @Post(':nodeId/complete')
  async completeNode(
    @Request() req,
    @Param('nodeId') nodeId: string,
    @Body() body?: { progressData?: any },
  ) {
    return this.skillTreeService.completeNode(
      req.user.id,
      nodeId,
      body?.progressData,
    );
  }
}

