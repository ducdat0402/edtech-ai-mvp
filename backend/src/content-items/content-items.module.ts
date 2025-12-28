import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ContentItemsService } from './content-items.service';
import { ContentItemsController } from './content-items.controller';
import { ContentItem } from './entities/content-item.entity';

@Module({
  imports: [TypeOrmModule.forFeature([ContentItem])],
  controllers: [ContentItemsController],
  providers: [ContentItemsService],
  exports: [ContentItemsService],
})
export class ContentItemsModule {}

