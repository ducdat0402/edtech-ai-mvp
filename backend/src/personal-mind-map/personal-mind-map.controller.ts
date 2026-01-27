import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
  UseGuards,
  Request,
  Patch,
} from '@nestjs/common';
import { PersonalMindMapService } from './personal-mind-map.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('personal-mind-map')
@UseGuards(JwtAuthGuard)
export class PersonalMindMapController {
  constructor(
    private readonly personalMindMapService: PersonalMindMapService,
  ) {}

  // ============ CHAT API - HỎI DỰA TRÊN NỘI DUNG MÔN HỌC ============

  /**
   * Bắt đầu chat session để tạo lộ trình cá nhân
   * AI sẽ hỏi dựa trên domains, topics, bài học của môn học
   */
  @Post(':subjectId/chat/start')
  async startChat(@Request() req, @Param('subjectId') subjectId: string) {
    const userId = req.user.id;
    return this.personalMindMapService.startSubjectChat(userId, subjectId);
  }

  /**
   * Tiếp tục chat với AI
   */
  @Post(':subjectId/chat')
  async chat(
    @Request() req,
    @Param('subjectId') subjectId: string,
    @Body() body: { message: string },
  ) {
    const userId = req.user.id;
    return this.personalMindMapService.continueSubjectChat(userId, subjectId, body.message);
  }

  /**
   * Lấy thông tin chat session hiện tại
   */
  @Get(':subjectId/chat/session')
  async getChatSession(@Request() req, @Param('subjectId') subjectId: string) {
    const userId = req.user.id;
    return this.personalMindMapService.getChatSession(userId, subjectId);
  }

  /**
   * Tạo lộ trình từ chat đã hoàn thành
   */
  @Post(':subjectId/chat/generate')
  async generateFromChat(@Request() req, @Param('subjectId') subjectId: string) {
    const userId = req.user.id;
    return this.personalMindMapService.generateFromSubjectChat(userId, subjectId);
  }

  /**
   * Reset chat session để bắt đầu lại
   */
  @Post(':subjectId/chat/reset')
  async resetChat(@Request() req, @Param('subjectId') subjectId: string) {
    const userId = req.user.id;
    await this.personalMindMapService.resetChatSession(userId, subjectId);
    return { success: true, message: 'Đã reset chat session' };
  }

  // ============ MIND MAP API ============

  /**
   * Kiểm tra xem user đã có personal mind map cho subject chưa
   */
  @Get('check/:subjectId')
  async checkExists(@Request() req, @Param('subjectId') subjectId: string) {
    const userId = req.user.id;
    return this.personalMindMapService.checkExists(userId, subjectId);
  }

  /**
   * Lấy personal mind map của user cho subject (with premium lock status)
   */
  @Get(':subjectId')
  async getPersonalMindMap(
    @Request() req,
    @Param('subjectId') subjectId: string,
  ) {
    const userId = req.user.id;
    const result = await this.personalMindMapService.getPersonalMindMapWithPremiumStatus(
      userId,
      subjectId,
    );

    if (!result.mindMap) {
      return { exists: false, mindMap: null, isPremium: false };
    }

    // Return mindMap with nodes replaced by nodesWithLockStatus
    return {
      exists: true,
      mindMap: {
        ...result.mindMap,
        nodes: result.nodesWithLockStatus,
      },
      isPremium: result.isPremium,
    };
  }

  /**
   * Tạo personal mind map mới
   */
  @Post(':subjectId')
  async createPersonalMindMap(
    @Request() req,
    @Param('subjectId') subjectId: string,
    @Body() body: { learningGoal: string },
  ) {
    const userId = req.user.id;
    const mindMap = await this.personalMindMapService.createPersonalMindMap(
      userId,
      subjectId,
      body.learningGoal,
    );

    return {
      success: true,
      message: 'Đã tạo lộ trình học tập cá nhân!',
      mindMap,
    };
  }

  /**
   * Cập nhật trạng thái node
   */
  @Patch(':subjectId/nodes/:nodeId')
  async updateNodeStatus(
    @Request() req,
    @Param('subjectId') subjectId: string,
    @Param('nodeId') nodeId: string,
    @Body() body: { status: 'not_started' | 'in_progress' | 'completed' },
  ) {
    const userId = req.user.id;
    const mindMap = await this.personalMindMapService.updateNodeStatus(
      userId,
      subjectId,
      nodeId,
      body.status,
    );

    return {
      success: true,
      mindMap,
    };
  }

  /**
   * Xóa personal mind map
   */
  @Delete(':subjectId')
  async deletePersonalMindMap(
    @Request() req,
    @Param('subjectId') subjectId: string,
  ) {
    const userId = req.user.id;
    await this.personalMindMapService.deletePersonalMindMap(userId, subjectId);

    return {
      success: true,
      message: 'Đã xóa lộ trình học tập cá nhân',
    };
  }
}
