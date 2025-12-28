import { Controller, Get, Param } from '@nestjs/common';
import { ContentItemsService } from './content-items.service';

@Controller('content')
export class ContentItemsController {
  constructor(private readonly contentService: ContentItemsService) {}

  @Get('node/:nodeId')
  async getContentByNode(@Param('nodeId') nodeId: string) {
    return this.contentService.findByNode(nodeId);
  }

  @Get(':id')
  async getContentById(@Param('id') id: string) {
    return this.contentService.findById(id);
  }
}

