/**
 * Script: Fill placeholder media for all content items
 * 
 * Mục đích: 
 * - Thêm placeholder image và video cho TẤT CẢ content items
 * - Giúp UI hiển thị đầy đủ các dạng nội dung (văn bản, hình ảnh, video)
 * - Placeholder sẽ hiển thị thông báo "Cần đóng góp" để người dùng biết cần upload nội dung thật
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { Repository, In } from 'typeorm';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { getRepositoryToken } from '@nestjs/typeorm';

// Placeholder URLs - sử dụng ảnh/video placeholder có sẵn
const PLACEHOLDER_IMAGE_URL = 'https://placehold.co/800x600/e2e8f0/64748b?text=C%E1%BA%A7n+%C4%90%C3%B3ng+G%C3%B3p+H%C3%ACnh+%E1%BA%A2nh&font=roboto';
const PLACEHOLDER_VIDEO_URL = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

// Placeholder config with contribution guides for each difficulty
const PLACEHOLDER_CONFIG = {
  easy: {
    imageUrl: 'https://placehold.co/800x600/dcfce7/166534?text=%F0%9F%8C%B1+C%E1%BA%A7n+%C4%90%C3%B3ng+G%C3%B3p+H%C3%ACnh+%E1%BA%A2nh%0A(M%E1%BB%A9c+%C4%90%C6%A1n+Gi%E1%BA%A3n)&font=roboto',
    imageDescription: '🎨 Hình ảnh minh họa cần được đóng góp cho bài học này (Mức độ: Đơn giản)',
    videoDescription: '🎬 Video hướng dẫn cần được đóng góp cho bài học này (Mức độ: Đơn giản)',
    videoDuration: '30-60 giây',
  },
  medium: {
    imageUrl: 'https://placehold.co/800x600/fef3c7/92400e?text=%F0%9F%93%9A+C%E1%BA%A7n+%C4%90%C3%B3ng+G%C3%B3p+H%C3%ACnh+%E1%BA%A2nh%0A(M%E1%BB%A9c+Chi+Ti%E1%BA%BFt)&font=roboto',
    imageDescription: '🎨 Hình ảnh minh họa cần được đóng góp cho bài học này (Mức độ: Chi tiết)',
    videoDescription: '🎬 Video hướng dẫn cần được đóng góp cho bài học này (Mức độ: Chi tiết)',
    videoDuration: '1-3 phút',
  },
  hard: {
    imageUrl: 'https://placehold.co/800x600/fce7f3/9d174d?text=%F0%9F%8E%93+C%E1%BA%A7n+%C4%90%C3%B3ng+G%C3%B3p+H%C3%ACnh+%E1%BA%A2nh%0A(M%E1%BB%A9c+Chuy%C3%AAn+S%C3%A2u)&font=roboto',
    imageDescription: '🎨 Hình ảnh minh họa cần được đóng góp cho bài học này (Mức độ: Chuyên sâu)',
    videoDescription: '🎬 Video hướng dẫn cần được đóng góp cho bài học này (Mức độ: Chuyên sâu)',
    videoDuration: '3-5 phút',
  },
};

/**
 * Generate default contribution guide based on content
 */
function generateDefaultImagePrompt(item: any): string {
  const title = item.title || 'Bài học';
  const difficulty = item.difficulty || 'medium';
  
  const difficultyGuide: Record<string, string> = {
    easy: 'Hình ảnh nên đơn giản, màu sắc tươi sáng, ít chi tiết, dễ hiểu ngay lập tức.',
    medium: 'Hình ảnh nên có độ chi tiết vừa phải, có thể thêm labels và chú thích để giải thích.',
    hard: 'Hình ảnh nên chi tiết và chuyên sâu, có thể bao gồm sơ đồ, biểu đồ hoặc infographic phức tạp.',
  };

  return `Tạo hình ảnh minh họa cho bài học "${title}".\n\n` +
    `Yêu cầu:\n` +
    `- ${difficultyGuide[difficulty] || difficultyGuide.medium}\n` +
    `- Hình ảnh phải liên quan trực tiếp đến nội dung bài học\n` +
    `- Sử dụng màu sắc hài hòa, dễ nhìn\n` +
    `- Kích thước tối thiểu 800x600 pixels\n` +
    `- Định dạng: JPG hoặc PNG`;
}

function generateDefaultVideoScript(item: any): string {
  const title = item.title || 'Bài học';
  const difficulty = item.difficulty || 'medium';
  const content = item.content?.substring(0, 300) || '';
  
  const durationGuide: Record<string, string> = {
    easy: '30-60 giây',
    medium: '1-3 phút',
    hard: '3-5 phút',
  };

  const styleGuide: Record<string, string> = {
    easy: 'Ngôn ngữ đơn giản, dễ hiểu. Có thể thêm animation vui nhộn.',
    medium: 'Giải thích từng bước, có ví dụ thực tế. Tốc độ vừa phải.',
    hard: 'Phân tích chuyên sâu, có thể so sánh nhiều góc độ. Chi tiết và đầy đủ.',
  };

  return `Tạo video hướng dẫn cho bài học "${title}".\n\n` +
    `📌 Thời lượng gợi ý: ${durationGuide[difficulty] || '1-3 phút'}\n\n` +
    `📌 Phong cách: ${styleGuide[difficulty] || styleGuide.medium}\n\n` +
    `📌 Nội dung cần đề cập:\n` +
    `${content ? content + '...\n\n' : ''}` +
    `📌 Gợi ý cấu trúc video:\n` +
    `1. Giới thiệu chủ đề (5-10s)\n` +
    `2. Nội dung chính - giải thích khái niệm\n` +
    `3. Ví dụ minh họa (nếu có)\n` +
    `4. Tóm tắt và kết luận`;
}

async function fillPlaceholderMedia() {
  console.log('🎬 Starting to fill placeholder media for all content items...');
  console.log('');

  const app = await NestFactory.createApplicationContext(AppModule);
  const contentItemRepo = app.get<Repository<ContentItem>>(getRepositoryToken(ContentItem));

  try {
    // Lấy tất cả content items (concept và example)
    const contentItems = await contentItemRepo.find({
      where: {
        type: In(['concept', 'example']),
      },
    });

    console.log(`📚 Found ${contentItems.length} content items to update`);

    let updatedCount = 0;
    let skippedCount = 0;

    for (const item of contentItems) {
      const difficulty = item.difficulty || 'medium';
      const config = PLACEHOLDER_CONFIG[difficulty as keyof typeof PLACEHOLDER_CONFIG] || PLACEHOLDER_CONFIG.medium;

      // Check if already has real media (not placeholder)
      // Real media can be: Cloudinary URLs OR local uploads (/uploads/...)
      const imageUrl = item.media?.imageUrl || '';
      const videoUrl = item.media?.videoUrl || '';
      
      const hasRealImage = imageUrl && 
        !imageUrl.includes('placehold.co') && 
        (imageUrl.includes('cloudinary') || imageUrl.includes('/uploads/'));
      
      const hasRealVideo = videoUrl && 
        !videoUrl.includes('sample/BigBuckBunny') &&
        !videoUrl.includes('gtv-videos-bucket') &&
        (videoUrl.includes('cloudinary') || videoUrl.includes('/uploads/'));

      if (hasRealImage && hasRealVideo) {
        skippedCount++;
        continue;
      }

      // Update media field with placeholders and default contribution guides
      item.media = {
        ...item.media,
        // Only set placeholder if no real media exists
        imageUrl: hasRealImage ? item.media?.imageUrl : config.imageUrl,
        imageDescription: item.media?.imageDescription || config.imageDescription,
        videoUrl: hasRealVideo ? item.media?.videoUrl : PLACEHOLDER_VIDEO_URL,
        videoDescription: item.media?.videoDescription || config.videoDescription,
        videoDuration: item.media?.videoDuration || config.videoDuration,
        // Generate default prompts if not exists
        imagePrompt: item.media?.imagePrompt || generateDefaultImagePrompt(item),
        videoScript: item.media?.videoScript || generateDefaultVideoScript(item),
      };

      // Update format to mixed since we now have all types
      item.format = 'mixed' as any;

      await contentItemRepo.save(item);
      updatedCount++;

      if (updatedCount % 50 === 0) {
        console.log(`  📝 Updated ${updatedCount} items...`);
      }
    }

    console.log('');
    console.log('='.repeat(50));
    console.log('📊 SUMMARY:');
    console.log(`   ✅ Updated: ${updatedCount} items`);
    console.log(`   ⏭️ Skipped (has real media): ${skippedCount} items`);
    console.log('='.repeat(50));

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await app.close();
  }
}

// Run the script
fillPlaceholderMedia()
  .then(() => {
    console.log('\n✅ Script completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Script failed:', error);
    process.exit(1);
  });
