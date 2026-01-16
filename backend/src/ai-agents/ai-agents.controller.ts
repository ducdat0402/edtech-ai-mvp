import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  UseGuards,
  Request,
  Query,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UserBehaviorService } from './user-behavior.service';
import { DrlService } from './drl.service';
import { ItsService } from './its.service';
import { LangChainService } from './langchain.service';

@Controller('ai-agents')
@UseGuards(JwtAuthGuard)
export class AiAgentsController {
  constructor(
    private behaviorService: UserBehaviorService,
    private drlService: DrlService,
    private itsService: ItsService,
    private langChainService: LangChainService,
  ) {}

  /**
   * Track user behavior
   * POST /ai-agents/behavior/track
   */
  @Post('behavior/track')
  async trackBehavior(
    @Request() req: any,
    @Body()
    body: {
      nodeId: string;
      action: string;
      metrics?: any;
      context?: any;
      contentItemId?: string;
    },
  ) {
    return this.behaviorService.trackBehavior(
      req.user.id,
      body.nodeId,
      body.action,
      body.metrics,
      body.context,
      body.contentItemId,
    );
  }

  /**
   * Get user behavior for a node
   * GET /ai-agents/behavior/node/:nodeId
   */
  @Get('behavior/node/:nodeId')
  async getNodeBehavior(
    @Request() req: any,
    @Param('nodeId') nodeId: string,
    @Query('limit') limit?: string,
  ) {
    return this.behaviorService.getNodeBehavior(
      req.user.id,
      nodeId,
      limit ? parseInt(limit, 10) : 50,
    );
  }

  /**
   * Get mastery level for a node
   * GET /ai-agents/mastery/:nodeId
   */
  @Get('mastery/:nodeId')
  async getMastery(
    @Request() req: any,
    @Param('nodeId') nodeId: string,
  ) {
    const mastery = await this.behaviorService.calculateMastery(
      req.user.id,
      nodeId,
    );
    return { nodeId, mastery, masteryPercentage: Math.round(mastery * 100) };
  }

  /**
   * Get optimal next node using DRL
   * GET /ai-agents/drl/next-node
   */
  @Get('drl/next-node')
  async getOptimalNextNode(
    @Request() req: any,
    @Query('currentNodeId') currentNodeId: string,
    @Query('subjectId') subjectId: string,
  ) {
    return this.drlService.getOptimalNextNode(
      req.user.id,
      currentNodeId,
      subjectId,
    );
  }

  /**
   * Adjust difficulty using ITS
   * GET /ai-agents/its/adjust-difficulty
   */
  @Get('its/adjust-difficulty')
  async adjustDifficulty(
    @Request() req: any,
    @Query('nodeId') nodeId: string,
    @Query('currentDifficulty') currentDifficulty: 'easy' | 'medium' | 'hard' | 'expert',
  ) {
    return this.itsService.adjustDifficulty(
      req.user.id,
      nodeId,
      currentDifficulty,
    );
  }

  /**
   * Generate hint using ITS
   * POST /ai-agents/its/hint
   */
  @Post('its/hint')
  async generateHint(
    @Request() req: any,
    @Body()
    body: {
      nodeId: string;
      contentItemId: string;
      question?: string;
      userAnswer?: string;
    },
  ) {
    return this.itsService.generateHint(
      req.user.id,
      body.nodeId,
      body.contentItemId,
      body.question,
      body.userAnswer,
    );
  }

  /**
   * Check if topic should be skipped
   * GET /ai-agents/its/should-skip/:nodeId
   */
  @Get('its/should-skip/:nodeId')
  async shouldSkipTopic(
    @Request() req: any,
    @Param('nodeId') nodeId: string,
  ) {
    return this.itsService.shouldSkipTopic(req.user.id, nodeId);
  }

  /**
   * Get personalized recommendations
   * GET /ai-agents/its/recommendations
   */
  @Get('its/recommendations')
  async getPersonalizedRecommendations(@Request() req: any) {
    return this.itsService.getPersonalizedRecommendations(req.user.id);
  }

  /**
   * Generate personalized roadmap using LangChain
   * POST /ai-agents/langchain/roadmap
   */
  @Post('langchain/roadmap')
  async generatePersonalizedRoadmap(
    @Request() req: any,
    @Body()
    body: {
      query: string;
      subjectId: string;
      days?: number;
    },
  ) {
    return this.langChainService.generatePersonalizedRoadmap(
      req.user.id,
      body.query,
      body.subjectId,
      body.days || 30,
    );
  }

  /**
   * Get error patterns
   * GET /ai-agents/behavior/error-patterns
   */
  @Get('behavior/error-patterns')
  async getErrorPatterns(
    @Request() req: any,
    @Query('nodeId') nodeId?: string,
  ) {
    return this.behaviorService.getErrorPatterns(req.user.id, nodeId);
  }

  /**
   * Get strengths and weaknesses
   * GET /ai-agents/behavior/strengths-weaknesses
   */
  @Get('behavior/strengths-weaknesses')
  async getStrengthsAndWeaknesses(@Request() req: any) {
    return this.behaviorService.getStrengthsAndWeaknesses(req.user.id);
  }
}

