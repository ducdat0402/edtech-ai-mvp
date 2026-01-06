import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { ContentEditsService } from './content-edits.service';
import { ContentEditsController } from './content-edits.controller';
import { FileStorageService } from './file-storage.service';
import { CloudinaryStorageService } from './cloudinary-storage.service';
import { AdminGuard } from '../auth/guards/admin.guard';
import { ContentEdit } from './entities/content-edit.entity';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([ContentEdit, ContentItem]),
    ConfigModule,
    UsersModule,
  ],
  controllers: [ContentEditsController],
  providers: [
    ContentEditsService,
    FileStorageService,
    CloudinaryStorageService,
    AdminGuard,
  ],
  exports: [ContentEditsService, FileStorageService],
})
export class ContentEditsModule {}

