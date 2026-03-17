import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { FriendsService } from './friends.service';

@Controller('friends')
@UseGuards(JwtAuthGuard)
export class FriendsController {
  constructor(private readonly friendsService: FriendsService) {}

  // ─── Friend Requests ────────────────────────────────────

  @Post('request/:userId')
  async sendRequest(@Request() req, @Param('userId') targetUserId: string) {
    return this.friendsService.sendRequest(req.user.id, targetUserId);
  }

  @Post('accept/:friendshipId')
  async acceptRequest(@Request() req, @Param('friendshipId') friendshipId: string) {
    return this.friendsService.acceptRequest(req.user.id, friendshipId);
  }

  @Post('reject/:friendshipId')
  async rejectRequest(@Request() req, @Param('friendshipId') friendshipId: string) {
    return this.friendsService.rejectRequest(req.user.id, friendshipId);
  }

  @Post('cancel/:friendshipId')
  async cancelRequest(@Request() req, @Param('friendshipId') friendshipId: string) {
    return this.friendsService.cancelRequest(req.user.id, friendshipId);
  }

  // ─── Friend Management ─────────────────────────────────

  @Get()
  async getFriends(@Request() req) {
    return this.friendsService.getFriends(req.user.id);
  }

  @Delete(':friendshipId')
  async unfriend(@Request() req, @Param('friendshipId') friendshipId: string) {
    await this.friendsService.unfriend(req.user.id, friendshipId);
    return { success: true };
  }

  @Post('block/:userId')
  async blockUser(@Request() req, @Param('userId') targetUserId: string) {
    await this.friendsService.blockUser(req.user.id, targetUserId);
    return { success: true };
  }

  @Delete('block/:userId')
  async unblockUser(@Request() req, @Param('userId') targetUserId: string) {
    await this.friendsService.unblockUser(req.user.id, targetUserId);
    return { success: true };
  }

  // ─── Requests & Info ────────────────────────────────────

  @Get('requests')
  async getRequests(@Request() req) {
    return this.friendsService.getRequests(req.user.id);
  }

  @Get('pending-count')
  async getPendingCount(@Request() req) {
    const count = await this.friendsService.getPendingCount(req.user.id);
    return { count };
  }

  // ─── Discovery ──────────────────────────────────────────

  @Get('search')
  async searchUsers(
    @Request() req,
    @Query('q') query: string,
    @Query('limit') limit?: string,
  ) {
    return this.friendsService.searchUsers(
      req.user.id,
      query,
      limit ? parseInt(limit, 10) : 20,
    );
  }

  @Get('suggestions')
  async getSuggestions(@Request() req, @Query('limit') limit?: string) {
    return this.friendsService.getSuggestions(
      req.user.id,
      limit ? parseInt(limit, 10) : 20,
    );
  }

  // ─── Activity Feed ──────────────────────────────────────

  @Get('activities')
  async getActivities(
    @Request() req,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.friendsService.getActivities(
      req.user.id,
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20,
    );
  }
}
