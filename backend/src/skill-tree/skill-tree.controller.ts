import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
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
  async getSkillTree(
    @Request() req,
    @Query('subjectId') subjectId?: string,
  ) {
    // If subjectId provided, try to get or generate skill tree
    if (subjectId) {
      // Check if skill tree exists
      const existing = await this.skillTreeService.getSkillTree(req.user.id, subjectId);
      
      if (!existing) {
        // Skill tree doesn't exist, generate it
        // This will return with generatingMessage if it's a new subject
        return this.skillTreeService.generateSkillTree(req.user.id, subjectId);
      }
      
      return existing;
    }
    
    // No subjectId, return user's skill trees
    return this.skillTreeService.getSkillTree(req.user.id);
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

