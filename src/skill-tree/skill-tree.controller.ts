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
    @Body() body: { 
      subjectId: string;
      learningGoalsData?: {
        currentLevel?: 'beginner' | 'intermediate' | 'advanced';
        interestedTopics?: string[];
        learningGoals?: string;
      };
    },
  ) {
    return this.skillTreeService.generateSkillTree(
      req.user.id,
      body.subjectId,
      body.learningGoalsData,
    );
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

  @Post('unlock-next')
  async unlockNextNode(
    @Request() req,
    @Body() body: { subjectId: string },
  ) {
    // Get skill tree for subject
    const skillTree = await this.skillTreeService.getSkillTree(
      req.user.id,
      body.subjectId,
    );

    if (!skillTree) {
      throw new Error('Skill tree not found');
    }

    return this.skillTreeService.unlockNextNode(req.user.id, skillTree.id);
  }

  @Get('next-unlockable')
  async getNextUnlockableNodes(
    @Request() req,
    @Query('subjectId') subjectId: string,
  ) {
    console.log(`🔍 [API] getNextUnlockableNodes called for user ${req.user.id}, subjectId: ${subjectId}`);
    
    // Get skill tree for subject
    const skillTree = await this.skillTreeService.getSkillTree(
      req.user.id,
      subjectId,
    );

    if (!skillTree) {
      console.log(`⚠️  [API] No skill tree found for subjectId: ${subjectId}`);
      return { nodes: [], hasNext: false };
    }

    console.log(`✅ [API] Found skill tree ${skillTree.id}`);
    console.log(`📊 [API] Skill tree stats: ${skillTree.completedNodes}/${skillTree.totalNodes} completed, ${skillTree.unlockedNodes} unlocked`);
    
    // Log all nodes and their status
    for (const node of skillTree.nodes) {
      const progress = (node as any).userProgress as any[] | undefined;
      const status = progress && progress.length > 0 ? progress[0].status : 'no progress';
      console.log(`📋 [API] Node ${node.order}: ${node.title} - Status: ${status}, Prerequisites: ${node.prerequisites?.join(', ') || 'none'}`);
    }
    
    console.log(`🔍 [API] Checking unlockable nodes...`);
    const unlockableNodes = await this.skillTreeService.getNextUnlockableNodes(
      req.user.id,
      skillTree.id,
    );

    console.log(`📊 [API] Found ${unlockableNodes.length} unlockable nodes: ${unlockableNodes.map(n => `${n.title} (order: ${n.order})`).join(', ')}`);
    return {
      nodes: unlockableNodes.map((n) => ({
        id: n.id,
        title: n.title,
        order: n.order,
      })),
      hasNext: unlockableNodes.length > 0,
    };
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

