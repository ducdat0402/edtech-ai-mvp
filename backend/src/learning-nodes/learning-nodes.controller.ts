import { Controller, Get, Param } from '@nestjs/common';
import { LearningNodesService } from './learning-nodes.service';

@Controller('nodes')
export class LearningNodesController {
  constructor(private readonly nodesService: LearningNodesService) {}

  @Get('subject/:subjectId')
  async getNodesBySubject(@Param('subjectId') subjectId: string) {
    return this.nodesService.findBySubject(subjectId);
  }

  @Get(':id')
  async getNodeById(@Param('id') id: string) {
    return this.nodesService.findById(id);
  }
}

