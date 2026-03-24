import { Controller, Get, UseGuards, Request } from '@nestjs/common';
import { DashboardService } from './dashboard.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('dashboard')
@UseGuards(JwtAuthGuard)
export class DashboardController {
  constructor(private readonly dashboardService: DashboardService) {}

  /** Thống kê nhẹ (không quét toàn bộ nodes) — ưu tiên cho Profile. */
  @Get('summary')
  async getDashboardSummary(@Request() req) {
    return this.dashboardService.getDashboardSummary(req.user.id);
  }

  @Get()
  async getDashboard(@Request() req) {
    return this.dashboardService.getDashboard(req.user.id);
  }
}

