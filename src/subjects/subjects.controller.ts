import { Controller, Get, Post, Param, Body, UseGuards, Request } from '@nestjs/common';
import { SubjectsService } from './subjects.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { SubjectLearningGoalsService, LearningGoalsSession } from './subject-learning-goals.service';
import { GenerationProgressService } from '../learning-nodes/generation-progress.service';

@Controller('subjects')
export class SubjectsController {
  constructor(
    private readonly subjectsService: SubjectsService,
    private readonly learningGoalsService: SubjectLearningGoalsService,
    private readonly generationProgressService: GenerationProgressService,
  ) {}

  @Get('explorer')
  async getExplorerSubjects() {
    return this.subjectsService.findByTrack('explorer');
  }

  @Get('scholar')
  @UseGuards(JwtAuthGuard)
  async getScholarSubjects(@Request() req) {
    const subjects = await this.subjectsService.findByTrack('scholar');
    // Add unlock status for each subject
    const subjectsWithStatus = await Promise.all(
      subjects.map(async (subject) => {
        const status = await this.subjectsService.getSubjectForUser(
          req.user.id,
          subject.id,
        );
        return {
          ...subject,
          isUnlocked: status.isUnlocked,
          canUnlock: status.canUnlock,
          requiredCoins: status.requiredCoins,
          userCoins: status.userCoins,
        };
      }),
    );
    return subjectsWithStatus;
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  async getSubject(@Request() req, @Param('id') id: string) {
    return this.subjectsService.getSubjectForUser(req.user.id, id);
  }

  @Get(':id/nodes')
  @UseGuards(JwtAuthGuard)
  async getAvailableNodes(@Request() req, @Param('id') id: string) {
    // Fog of War: Chỉ trả về nodes đã unlock
    return this.subjectsService.getAvailableNodesForUser(req.user.id, id);
  }

  @Get(':id/intro')
  @UseGuards(JwtAuthGuard)
  async getSubjectIntro(@Request() req, @Param('id') id: string) {
    return this.subjectsService.getSubjectIntro(req.user.id, id);
  }

  /**
   * Start learning goals conversation for a subject
   */
  @Post(':id/learning-goals/start')
  @UseGuards(JwtAuthGuard)
  async startLearningGoals(
    @Request() req,
    @Param('id') subjectId: string,
  ) {
    return this.learningGoalsService.startConversation(req.user.id, subjectId);
  }

  /**
   * Send a message in learning goals conversation
   */
  @Post(':id/learning-goals/chat')
  @UseGuards(JwtAuthGuard)
  async chatLearningGoals(
    @Request() req,
    @Param('id') subjectId: string,
    @Body() body: { message: string },
  ) {
    return this.learningGoalsService.chat(req.user.id, subjectId, body.message);
  }

  /**
   * Get learning goals session
   */
  @Get(':id/learning-goals/session')
  @UseGuards(JwtAuthGuard)
  async getLearningGoalsSession(
    @Request() req,
    @Param('id') subjectId: string,
  ): Promise<LearningGoalsSession | null> {
    return this.learningGoalsService.getSession(req.user.id, subjectId);
  }

  /**
   * Generate skill tree with learning goals
   */
  @Post(':id/learning-goals/generate-skill-tree')
  @UseGuards(JwtAuthGuard)
  async generateSkillTreeWithLearningGoals(
    @Request() req,
    @Param('id') subjectId: string,
  ) {
    return this.learningGoalsService.generateSkillTreeWithGoals(
      req.user.id,
      subjectId,
    );
  }

  /**
   * Generate learning nodes from a topic node in the mind map
   */
  @Post(':id/mind-map/:topicNodeId/generate-learning-nodes')
  @UseGuards(JwtAuthGuard)
  async generateLearningNodesFromTopic(
    @Request() req,
    @Param('id') subjectId: string,
    @Param('topicNodeId') topicNodeId: string,
  ) {
    return this.subjectsService.generateLearningNodesFromTopic(
      subjectId,
      topicNodeId,
    );
  }

  /**
   * Get generation progress for a task
   */
  @Get(':id/generation-progress/:taskId')
  @UseGuards(JwtAuthGuard)
  async getGenerationProgress(
    @Param('taskId') taskId: string,
  ) {
    const progress = this.generationProgressService.getProgress(taskId);
    if (!progress) {
      return { error: 'Task not found' };
    }
    return progress;
  }
}

