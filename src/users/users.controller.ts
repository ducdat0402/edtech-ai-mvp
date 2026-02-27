import {
  Controller,
  Get,
  Patch,
  Body,
  UseGuards,
  Request,
  BadRequestException,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('profile')
  async getProfile(@Request() req) {
    const user = await this.usersService.findById(req.user.id);
    const { password, ...result } = user;
    return result;
  }

  @Patch('switch-role')
  async switchRole(
    @Request() req,
    @Body() body: { role: 'user' | 'contributor' },
  ) {
    if (!body.role || !['user', 'contributor'].includes(body.role)) {
      throw new BadRequestException(
        'Invalid role. Must be "user" or "contributor".',
      );
    }
    try {
      const user = await this.usersService.switchRole(req.user.id, body.role);
      const { password, ...result } = user;
      return result;
    } catch (e) {
      throw new BadRequestException(e.message);
    }
  }
}

