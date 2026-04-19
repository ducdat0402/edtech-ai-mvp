import { Body, Controller, Get, Post, Request, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AvatarFramesService } from './avatar-frames.service';
import { PurchaseAvatarFrameDto } from './dto/purchase-avatar-frame.dto';

@Controller('avatar-frames')
@UseGuards(JwtAuthGuard)
export class AvatarFramesController {
  constructor(private readonly avatarFramesService: AvatarFramesService) {}

  @Get()
  async catalog(@Request() req: { user: { id: string } }) {
    return this.avatarFramesService.getCatalog(req.user.id);
  }

  @Post('purchase')
  async purchase(
    @Request() req: { user: { id: string } },
    @Body() body: PurchaseAvatarFrameDto,
  ) {
    return this.avatarFramesService.purchase(
      req.user.id,
      body.frameId,
      body.currency,
    );
  }

  @Post('equip')
  async equip(
    @Request() req: { user: { id: string } },
    @Body() body: { frameId?: string | null },
  ) {
    const raw = body?.frameId;
    const frameId =
      raw === undefined || raw === null || raw === '' ? null : String(raw);
    return this.avatarFramesService.equip(req.user.id, frameId);
  }
}
