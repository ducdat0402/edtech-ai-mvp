/**
 * Script: Generate image + video descriptions for each content item
 * 
 * Logic mới:
 * - Mỗi bài học (content item) sẽ có 3 dạng nội dung:
 *   1. Văn bản (text) - đã có
 *   2. Hình ảnh (imageUrl) - cần AI generate prompt
 *   3. Video (videoUrl) - cần AI generate script
 * 
 * Script này sẽ:
 * - Đọc từng content item
 * - AI tạo image prompt và video script dựa trên nội dung bài học
 * - Lưu prompts vào media field để sử dụng sau này
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { Repository, IsNull, Not } from 'typeorm';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { AiService } from '../ai/ai.service';
import { getRepositoryToken } from '@nestjs/typeorm';

interface MediaPrompts {
  imagePrompt: string;          // Prompt để generate hình ảnh với AI (DALL-E, Midjourney, etc.)
  imageDescription: string;     // Mô tả hình ảnh cho người dùng
  videoScript: string;          // Script cho video (narration)
  videoDescription: string;     // Mô tả video
  videoDuration: string;        // Độ dài video gợi ý
}

async function generateMediaForDifficulty(
  aiService: AiService,
  contentItem: ContentItem,
  node: LearningNode,
  difficulty: string,
): Promise<MediaPrompts> {
  const difficultyDescriptions: Record<string, any> = {
    easy: {
      label: 'ĐƠN GIẢN',
      imageStyle: 'Hình ảnh đơn giản, màu sắc tươi sáng, ít chi tiết, dễ hiểu ngay',
      videoStyle: 'Video ngắn (30-60s), ngôn ngữ đơn giản, nhiều animation vui nhộn',
    },
    medium: {
      label: 'TRUNG BÌNH',
      imageStyle: 'Hình ảnh chi tiết vừa phải, có labels và annotations',
      videoStyle: 'Video trung bình (1-3 phút), giải thích từng bước, có ví dụ thực tế',
    },
    hard: {
      label: 'NÂNG CAO',
      imageStyle: 'Hình ảnh chuyên sâu, biểu đồ phức tạp, nhiều chi tiết kỹ thuật',
      videoStyle: 'Video dài (3-5 phút), phân tích sâu, case studies phức tạp',
    },
  };

  const config = difficultyDescriptions[difficulty] || difficultyDescriptions.medium;

  // Lấy content text để AI hiểu nội dung bài học
  const contentText = contentItem.content || contentItem.title;

  const prompt = `Bạn là chuyên gia tạo nội dung giáo dục đa phương tiện. 
Nhiệm vụ: Tạo IMAGE PROMPT và VIDEO SCRIPT cho bài học sau.

BÀI HỌC:
- Tiêu đề: ${contentItem.title}
- Loại: ${contentItem.type === 'concept' ? 'Khái niệm' : 'Ví dụ'}
- Mức độ: ${config.label}
- Node: ${node.title}
- Môn học: ${(node as any).subject?.name || 'Chưa xác định'}

NỘI DUNG BÀI HỌC:
${contentText.substring(0, 2000)}

YÊU CẦU MỨC ĐỘ ${config.label}:
- Image: ${config.imageStyle}
- Video: ${config.videoStyle}

TẠO NỘI DUNG:

1. IMAGE PROMPT (để dùng với DALL-E, Midjourney):
   - Prompt tiếng Anh, chi tiết, mô tả rõ phong cách và nội dung
   - Phù hợp với mức độ ${config.label}
   - Educational, professional style

2. IMAGE DESCRIPTION (mô tả cho người dùng):
   - Tiếng Việt, 1-2 câu
   - Giải thích hình ảnh minh họa điều gì

3. VIDEO SCRIPT (kịch bản narration):
   - Tiếng Việt
   - Phù hợp độ dài video theo mức độ
   - Viết script cho người đọc/AI voice

4. VIDEO DESCRIPTION (mô tả video):
   - Tiếng Việt, 1-2 câu
   - Tóm tắt nội dung video

5. VIDEO DURATION (độ dài gợi ý):
   - Ví dụ: "30-60 giây", "1-2 phút", "3-5 phút"

Trả về JSON:
{
  "imagePrompt": "English prompt for image generation...",
  "imageDescription": "Mô tả hình ảnh bằng tiếng Việt...",
  "videoScript": "Script video tiếng Việt...",
  "videoDescription": "Mô tả video bằng tiếng Việt...",
  "videoDuration": "Độ dài gợi ý..."
}`;

  const response = await aiService.chat([{ role: 'user', content: prompt }]);
  
  // Parse JSON response
  const cleanedResponse = response
    .replace(/```json\n?/g, '')
    .replace(/```\n?/g, '')
    .trim();

  try {
    return JSON.parse(cleanedResponse) as MediaPrompts;
  } catch (e) {
    // Fallback nếu AI không trả về JSON hợp lệ
    return {
      imagePrompt: `Educational illustration for "${contentItem.title}", ${config.imageStyle.toLowerCase()}, clean modern design, educational content`,
      imageDescription: `Hình ảnh minh họa cho bài học "${contentItem.title}"`,
      videoScript: `Chào mừng bạn đến với bài học "${contentItem.title}". ${contentText.substring(0, 500)}...`,
      videoDescription: `Video hướng dẫn về ${contentItem.title}`,
      videoDuration: difficulty === 'easy' ? '30-60 giây' : difficulty === 'hard' ? '3-5 phút' : '1-2 phút',
    };
  }
}

async function generateLessonMedia() {
  console.log('🎬 Starting lesson media generation...');
  console.log('');
  console.log('Logic mới: Mỗi bài học sẽ có 3 dạng - TEXT + IMAGE + VIDEO');
  console.log('Script này sẽ tạo image prompt và video script cho từng bài học');
  console.log('');

  const app = await NestFactory.createApplicationContext(AppModule);

  const nodeRepo = app.get<Repository<LearningNode>>(getRepositoryToken(LearningNode));
  const contentItemRepo = app.get<Repository<ContentItem>>(getRepositoryToken(ContentItem));
  const aiService = app.get(AiService);

  try {
    // Lấy tất cả content items cần generate media
    // Chỉ lấy những item có content text (đã có nội dung)
    const contentItems = await contentItemRepo.find({
      where: [
        { type: 'concept', content: Not(IsNull()) },
        { type: 'example', content: Not(IsNull()) },
      ],
      relations: ['node'],
      order: { nodeId: 'ASC', order: 'ASC' },
    });

    console.log(`📚 Found ${contentItems.length} content items to process`);

    // Nhóm theo node để xử lý
    const itemsByNode = new Map<string, ContentItem[]>();
    for (const item of contentItems) {
      const nodeId = item.nodeId;
      if (!itemsByNode.has(nodeId)) {
        itemsByNode.set(nodeId, []);
      }
      itemsByNode.get(nodeId)!.push(item);
    }

    console.log(`📖 Grouped into ${itemsByNode.size} nodes`);

    let processedCount = 0;
    let skippedCount = 0;
    let errorCount = 0;

    // Xử lý từng node
    for (const [nodeId, items] of itemsByNode) {
      // Lấy node info
      const node = await nodeRepo.findOne({
        where: { id: nodeId },
        relations: ['subject'],
      });

      if (!node) {
        console.log(`  ⚠️ Node ${nodeId} not found, skipping...`);
        skippedCount += items.length;
        continue;
      }

      console.log(`\n📖 Processing node: "${node.title}" (${items.length} items)`);

      for (const item of items) {
        // Skip nếu đã có media prompts
        if (item.media?.imagePrompt || item.media?.videoScript) {
          console.log(`  ⏭️ "${item.title}" already has media prompts, skipping...`);
          skippedCount++;
          continue;
        }

        try {
          console.log(`  🎨 Generating media for: "${item.title}" (${item.difficulty || 'medium'})...`);

          const mediaPrompts = await generateMediaForDifficulty(
            aiService,
            item,
            node,
            item.difficulty || 'medium',
          );

          // Cập nhật media field
          item.media = {
            ...item.media,
            imagePrompt: mediaPrompts.imagePrompt,
            imageDescription: mediaPrompts.imageDescription,
            videoScript: mediaPrompts.videoScript,
            videoDescription: mediaPrompts.videoDescription,
            videoDuration: mediaPrompts.videoDuration,
          };

          // Cập nhật format thành 'mixed' vì sẽ có text + media
          item.format = 'mixed' as any;

          await contentItemRepo.save(item);

          console.log(`    ✅ Generated: Image prompt (${mediaPrompts.imagePrompt.length} chars), Video script (${mediaPrompts.videoScript.length} chars)`);
          processedCount++;

          // Rate limiting - đợi 1.5 giây giữa các items
          await new Promise(resolve => setTimeout(resolve, 1500));

        } catch (error: any) {
          console.error(`    ❌ Error: ${error.message}`);
          errorCount++;
        }
      }
    }

    console.log('\n' + '='.repeat(50));
    console.log('📊 SUMMARY:');
    console.log(`  - Processed: ${processedCount} content items`);
    console.log(`  - Skipped: ${skippedCount} items`);
    console.log(`  - Errors: ${errorCount}`);
    console.log('='.repeat(50));
    console.log('');
    console.log('💡 Next steps:');
    console.log('  1. Use imagePrompt to generate images with DALL-E/Midjourney');
    console.log('  2. Use videoScript to create videos with AI video tools');
    console.log('  3. Upload generated media and update imageUrl/videoUrl fields');

  } catch (error) {
    console.error('❌ Script failed:', error);
  } finally {
    await app.close();
  }
}

// Run the script
generateLessonMedia()
  .then(() => {
    console.log('\n✅ Script completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Script failed:', error);
    process.exit(1);
  });
