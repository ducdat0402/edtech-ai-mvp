/**
 * Migrate local media files to Cloudinary
 * This script finds all content items with local URLs (/uploads/...) 
 * and uploads them to Cloudinary, then updates the database
 */
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { Repository } from 'typeorm';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { ContentEdit } from '../content-edits/entities/content-edit.entity';
import { getRepositoryToken } from '@nestjs/typeorm';
import { CloudinaryStorageService } from '../content-edits/cloudinary-storage.service';
import * as fs from 'fs';
import * as path from 'path';

async function migrateToCloudinary() {
  console.log('🚀 Starting migration from local storage to Cloudinary...\n');

  const app = await NestFactory.createApplicationContext(AppModule);
  const contentItemRepo = app.get<Repository<ContentItem>>(getRepositoryToken(ContentItem));
  const contentEditRepo = app.get<Repository<ContentEdit>>(getRepositoryToken(ContentEdit));
  const cloudinaryService = app.get(CloudinaryStorageService);

  // Check if Cloudinary is enabled
  if (!cloudinaryService.isEnabled()) {
    console.error('❌ Cloudinary is not configured! Please set CLOUDINARY_* env vars.');
    await app.close();
    process.exit(1);
  }

  console.log('✅ Cloudinary is configured and ready.\n');

  const uploadsDir = path.join(process.cwd(), 'uploads');
  let migratedImages = 0;
  let migratedVideos = 0;
  let errors = 0;

  try {
    // 1. Find all content items with local image URLs
    console.log('📋 Finding content items with local image URLs...');
    const itemsWithLocalImages = await contentItemRepo
      .createQueryBuilder('item')
      .where("item.media->>'imageUrl' LIKE '/uploads/%'")
      .getMany();

    console.log(`   Found ${itemsWithLocalImages.length} items with local images\n`);

    for (const item of itemsWithLocalImages) {
      const localUrl = item.media?.imageUrl;
      if (!localUrl) continue;

      const localPath = path.join(process.cwd(), localUrl);
      
      if (!fs.existsSync(localPath)) {
        console.log(`⚠️ File not found: ${localPath}`);
        continue;
      }

      console.log(`📤 Uploading image: ${localUrl}`);
      
      try {
        // Read file and create a mock Multer file object
        const buffer = fs.readFileSync(localPath);
        const ext = path.extname(localPath).toLowerCase();
        const mimeTypes: Record<string, string> = {
          '.jpg': 'image/jpeg',
          '.jpeg': 'image/jpeg',
          '.png': 'image/png',
          '.gif': 'image/gif',
          '.webp': 'image/webp',
        };

        const mockFile: Express.Multer.File = {
          fieldname: 'image',
          originalname: path.basename(localPath),
          encoding: '7bit',
          mimetype: mimeTypes[ext] || 'image/jpeg',
          buffer: buffer,
          size: buffer.length,
          destination: '',
          filename: '',
          path: localPath,
          stream: null as any,
        };

        const result = await cloudinaryService.uploadImage(mockFile, 'content-edits/migrated');
        
        // Update content item with new Cloudinary URL
        item.media = {
          ...item.media,
          imageUrl: result.url,
        };
        await contentItemRepo.save(item);

        console.log(`   ✅ Migrated to: ${result.url}`);
        migratedImages++;
      } catch (error: any) {
        console.error(`   ❌ Failed: ${error.message}`);
        errors++;
      }
    }

    // 2. Find all content items with local video URLs
    console.log('\n📋 Finding content items with local video URLs...');
    const itemsWithLocalVideos = await contentItemRepo
      .createQueryBuilder('item')
      .where("item.media->>'videoUrl' LIKE '/uploads/%'")
      .getMany();

    console.log(`   Found ${itemsWithLocalVideos.length} items with local videos\n`);

    for (const item of itemsWithLocalVideos) {
      const localUrl = item.media?.videoUrl;
      if (!localUrl) continue;

      const localPath = path.join(process.cwd(), localUrl);
      
      if (!fs.existsSync(localPath)) {
        console.log(`⚠️ File not found: ${localPath}`);
        continue;
      }

      console.log(`📤 Uploading video: ${localUrl}`);
      
      try {
        const buffer = fs.readFileSync(localPath);
        const ext = path.extname(localPath).toLowerCase();
        const mimeTypes: Record<string, string> = {
          '.mp4': 'video/mp4',
          '.mov': 'video/quicktime',
          '.webm': 'video/webm',
          '.avi': 'video/x-msvideo',
        };

        const mockFile: Express.Multer.File = {
          fieldname: 'video',
          originalname: path.basename(localPath),
          encoding: '7bit',
          mimetype: mimeTypes[ext] || 'video/mp4',
          buffer: buffer,
          size: buffer.length,
          destination: '',
          filename: '',
          path: localPath,
          stream: null as any,
        };

        const result = await cloudinaryService.uploadVideo(mockFile, 'content-edits/migrated');
        
        // Update content item with new Cloudinary URL
        item.media = {
          ...item.media,
          videoUrl: result.url,
        };
        await contentItemRepo.save(item);

        console.log(`   ✅ Migrated to: ${result.url}`);
        migratedVideos++;
      } catch (error: any) {
        console.error(`   ❌ Failed: ${error.message}`);
        errors++;
      }
    }

    // 3. Also update content_edits table
    console.log('\n📋 Updating content_edits table...');
    const editsWithLocalImages = await contentEditRepo
      .createQueryBuilder('edit')
      .where("edit.media->>'imageUrl' LIKE '/uploads/%'")
      .getMany();

    for (const edit of editsWithLocalImages) {
      // Find the corresponding content item to get the new URL
      const contentItem = await contentItemRepo.findOne({
        where: { id: edit.contentItemId },
      });
      
      if (contentItem?.media?.imageUrl && contentItem.media.imageUrl.includes('cloudinary')) {
        edit.media = {
          ...edit.media,
          imageUrl: contentItem.media.imageUrl,
        };
        await contentEditRepo.save(edit);
        console.log(`   ✅ Updated edit ${edit.id} with Cloudinary URL`);
      }
    }

    const editsWithLocalVideos = await contentEditRepo
      .createQueryBuilder('edit')
      .where("edit.media->>'videoUrl' LIKE '/uploads/%'")
      .getMany();

    for (const edit of editsWithLocalVideos) {
      const contentItem = await contentItemRepo.findOne({
        where: { id: edit.contentItemId },
      });
      
      if (contentItem?.media?.videoUrl && contentItem.media.videoUrl.includes('cloudinary')) {
        edit.media = {
          ...edit.media,
          videoUrl: contentItem.media.videoUrl,
        };
        await contentEditRepo.save(edit);
        console.log(`   ✅ Updated edit ${edit.id} with Cloudinary URL`);
      }
    }

    // Summary
    console.log('\n' + '='.repeat(50));
    console.log('📊 Migration Summary:');
    console.log(`   Images migrated: ${migratedImages}`);
    console.log(`   Videos migrated: ${migratedVideos}`);
    console.log(`   Errors: ${errors}`);
    console.log('='.repeat(50));

  } finally {
    await app.close();
  }
}

migrateToCloudinary()
  .then(() => process.exit(0))
  .catch(e => { console.error(e); process.exit(1); });
