import { Controller, Get, Param, UseGuards, Request } from '@nestjs/common';
import { SubjectsService } from './subjects.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('subjects')
export class SubjectsController {
  constructor(private readonly subjectsService: SubjectsService) {}

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
}

