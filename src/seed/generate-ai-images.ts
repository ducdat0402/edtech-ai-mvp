/**
 * Script: Generate AI images for content items using DALL-E
 * 
 * Quy trình:
 * 1. Đọc các content items có imagePrompt trong media field
 * 2. Sử dụng DALL-E để generate hình ảnh từ imagePrompt
 * 3. Upload hình ảnh lên Cloudinary
 * 4. Cập nhật imageUrl trong database
 * 
 * Lưu ý:
 * - DALL-E có rate limit, nên script sẽ có delay giữa các requests
 * - Chi phí: ~$0.04/image (standard) hoặc ~$0.08/image (HD) với DALL-E 3
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { Repository, IsNull, Not } from 'typeorm';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { AiService } from '../ai/ai.service';
import { CloudinaryStorageService } from '../content-edits/cloudinary-storage.service';
import { getRepositoryToken } from '@nestjs/typeorm';

interface GenerationResult {
  contentItemId: string;
  title: string;
  success: boolean;
  imageUrl?: string;
  error?: string;
}

async function generateAiImages() {
  console.log('🎨 Starting AI image generation with DALL-E...');
  console.log('');
  console.log('⚠️  Chi phí ước tính: ~$0.04/image (standard quality)');
  console.log('');

  const app = await NestFactory.createApplicationContext(AppModule);

  const contentItemRepo = app.get<Repository<ContentItem>>(getRepositoryToken(ContentItem));
  const aiService = app.get(AiService);
  const cloudinaryService = app.get(CloudinaryStorageService);

  // Check if Cloudinary is configured
  if (!cloudinaryService.isEnabled()) {
    console.error('❌ Cloudinary is not configured. Please set CLOUDINARY_* env variables.');
    await app.close();
    process.exit(1);
  }

  try {
    // Lấy các content items có imagePrompt nhưng chưa có imageUrl
    const contentItems = await contentItemRepo
      .createQueryBuilder('item')
      .where("item.media->>'imagePrompt' IS NOT NULL")
      .andWhere("(item.media->>'imageUrl' IS NULL OR item.media->>'imageUrl' = '')")
      .orderBy('item.updatedAt', 'DESC')
      .take(10) // Giới hạn 10 items mỗi lần chạy để kiểm soát chi phí
      .getMany();

    console.log(`📚 Found ${contentItems.length} content items with imagePrompt but no imageUrl`);

    if (contentItems.length === 0) {
      console.log('✅ No items need image generation');
      await app.close();
      return;
    }

    const results: GenerationResult[] = [];
    let successCount = 0;
    let errorCount = 0;

    for (const item of contentItems) {
      const imagePrompt = item.media?.imagePrompt;
      
      if (!imagePrompt) {
        console.log(`  ⏭️ Skipping "${item.title}" - no imagePrompt`);
        continue;
      }

      console.log(`\n🖼️ Generating image for: "${item.title}"`);
      console.log(`   Prompt: ${imagePrompt.substring(0, 100)}...`);

      try {
        // Step 1: Generate image with DALL-E
        console.log('   📤 Calling DALL-E API...');
        const dalleResult = await aiService.generateImage(imagePrompt, {
          size: '1024x1024',
          quality: 'standard',
          style: 'natural',
        });

        console.log(`   ✅ DALL-E generated image`);
        console.log(`   📝 Revised prompt: ${dalleResult.revisedPrompt.substring(0, 80)}...`);

        // Step 2: Upload to Cloudinary
        console.log('   ☁️ Uploading to Cloudinary...');
        const cloudinaryResult = await cloudinaryService.uploadImageFromUrl(
          dalleResult.url,
          'edtech/ai-generated-images',
        );

        // Step 3: Update database
        console.log('   💾 Updating database...');
        item.media = {
          ...item.media,
          imageUrl: cloudinaryResult.url,
          imageGeneratedAt: new Date().toISOString(),
        };
        item.format = 'mixed' as any; // Update format since we now have image

        await contentItemRepo.save(item);

        console.log(`   ✅ Success! Image URL: ${cloudinaryResult.url.substring(0, 60)}...`);

        results.push({
          contentItemId: item.id,
          title: item.title,
          success: true,
          imageUrl: cloudinaryResult.url,
        });
        successCount++;

      } catch (error: any) {
        console.error(`   ❌ Error: ${error.message}`);
        results.push({
          contentItemId: item.id,
          title: item.title,
          success: false,
          error: error.message,
        });
        errorCount++;
      }

      // Rate limiting - đợi 3 giây giữa các requests
      console.log('   ⏳ Waiting 3s before next request...');
      await new Promise(resolve => setTimeout(resolve, 3000));
    }

    // Summary
    console.log('\n' + '='.repeat(50));
    console.log('📊 GENERATION SUMMARY:');
    console.log(`   ✅ Success: ${successCount}`);
    console.log(`   ❌ Errors: ${errorCount}`);
    console.log(`   💰 Estimated cost: ~$${(successCount * 0.04).toFixed(2)}`);
    console.log('='.repeat(50));

    // Show results
    console.log('\n📋 Results:');
    for (const result of results) {
      if (result.success) {
        console.log(`   ✅ ${result.title.substring(0, 40)}... → ${result.imageUrl?.substring(0, 50)}...`);
      } else {
        console.log(`   ❌ ${result.title.substring(0, 40)}... → Error: ${result.error}`);
      }
    }

  } catch (error) {
    console.error('❌ Script failed:', error);
  } finally {
    await app.close();
  }
}

// Run the script
generateAiImages()
  .then(() => {
    console.log('\n✅ Script completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Script failed:', error);
    process.exit(1);
  });
