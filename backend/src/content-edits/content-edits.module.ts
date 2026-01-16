import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { ContentEditsService } from './content-edits.service';
import { ContentEditsController } from './content-edits.controller';
import { FileStorageService } from './file-storage.service';
import { CloudinaryStorageService } from './cloudinary-storage.service';
import { MediaNormalizationService } from './media-normalization.service';
import { AdminGuard } from '../auth/guards/admin.guard';
import { ContentEdit } from './entities/content-edit.entity';
import { EditHistory } from './entities/edit-history.entity';
import { ContentVersion } from './entities/content-version.entity';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { UsersModule } from '../users/users.module';
import { EditHistoryService } from './edit-history.service';
import { ContentVersionService } from './content-version.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([ContentEdit, EditHistory, ContentVersion, ContentItem]),
    ConfigModule,
    UsersModule,
  ],
  controllers: [ContentEditsController],
  providers: [
    ContentEditsService,
    EditHistoryService,
    ContentVersionService,
    FileStorageService,
    MediaNormalizationService,
    CloudinaryStorageService,
    AdminGuard,
  ],
  exports: [ContentEditsService, EditHistoryService, ContentVersionService, FileStorageService],
})
export class ContentEditsModule {}

