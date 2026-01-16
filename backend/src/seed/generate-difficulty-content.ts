/**
 * Script: Generate content at different difficulty levels for existing learning nodes
 * 
 * Mỗi learning node sẽ có content cho 3 mức độ khó:
 * - easy: Nội dung đơn giản, cơ bản
 * - medium: Nội dung chi tiết, cân bằng (mặc định)
 * - hard: Nội dung chuyên sâu, nâng cao
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { Repository } from 'typeorm';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { AiService } from '../ai/ai.service';
import { getRepositoryToken } from '@nestjs/typeorm';

interface DifficultyContent {
  title: string;
  content: string;
  difficulty: 'easy' | 'medium' | 'hard';
}

async function generateDifficultyContent() {
  console.log('🚀 Starting difficulty content generation...');

  const app = await NestFactory.createApplicationContext(AppModule);

  const nodeRepo = app.get<Repository<LearningNode>>(getRepositoryToken(LearningNode));
  const contentItemRepo = app.get<Repository<ContentItem>>(getRepositoryToken(ContentItem));
  const aiService = app.get(AiService);

  try {
    // Lấy tất cả learning nodes
    const nodes = await nodeRepo.find({
      relations: ['subject'],
      order: { createdAt: 'ASC' },
    });

    console.log(`📚 Found ${nodes.length} learning nodes`);

    let processedCount = 0;
    let skippedCount = 0;
    let errorCount = 0;

    for (const node of nodes) {
      console.log(`\n📖 Processing node: "${node.title}" (ID: ${node.id})`);

      // Lấy content items hiện tại của node
      const existingItems = await contentItemRepo.find({
        where: { nodeId: node.id },
        order: { order: 'ASC' },
      });

      // Kiểm tra xem đã có content ở các độ khó khác chưa
      const hasDifficulties = {
        easy: existingItems.some(item => item.difficulty === 'easy'),
        medium: existingItems.some(item => item.difficulty === 'medium'),
        hard: existingItems.some(item => item.difficulty === 'hard'),
      };

      const difficultiesToGenerate = ['easy', 'medium', 'hard'].filter(
        d => !hasDifficulties[d as keyof typeof hasDifficulties]
      ) as ('easy' | 'medium' | 'hard')[];

      if (difficultiesToGenerate.length === 0) {
        console.log(`  ✅ Already has all difficulty levels, skipping...`);
        skippedCount++;
        continue;
      }

      console.log(`  📝 Need to generate content for: ${difficultiesToGenerate.join(', ')}`);

      // Lấy concepts và examples hiện tại để làm base
      const baseConcepts = existingItems.filter(item => item.type === 'concept');
      const baseExamples = existingItems.filter(item => item.type === 'example');

      for (const difficulty of difficultiesToGenerate) {
        try {
          console.log(`  🎯 Generating ${difficulty} content...`);

          // Generate content cho từng difficulty
          const newContent = await generateContentForDifficulty(
            aiService,
            node,
            baseConcepts,
            baseExamples,
            difficulty,
          );

          // Lưu concepts mới
          let order = existingItems.filter(i => i.type === 'concept').length;
          for (const concept of newContent.concepts) {
            order++;
            const newConcept = contentItemRepo.create({
              nodeId: node.id,
              type: 'concept',
              difficulty: difficulty,
              title: concept.title,
              content: concept.content,
              order: order,
              rewards: { 
                xp: difficulty === 'easy' ? 8 : difficulty === 'hard' ? 15 : 10, 
                coin: difficulty === 'easy' ? 1 : difficulty === 'hard' ? 3 : 2 
              },
            });
            await contentItemRepo.save(newConcept);
          }

          // Lưu examples mới
          order = existingItems.filter(i => i.type === 'example').length;
          for (const example of newContent.examples) {
            order++;
            const newExample = contentItemRepo.create({
              nodeId: node.id,
              type: 'example',
              difficulty: difficulty,
              title: example.title,
              content: example.content,
              order: order,
              rewards: { 
                xp: difficulty === 'easy' ? 12 : difficulty === 'hard' ? 20 : 15, 
                coin: difficulty === 'easy' ? 1 : difficulty === 'hard' ? 4 : 2 
              },
            });
            await contentItemRepo.save(newExample);
          }

          console.log(`    ✅ Created ${newContent.concepts.length} concepts + ${newContent.examples.length} examples at ${difficulty} level`);

        } catch (error) {
          console.error(`    ❌ Error generating ${difficulty} content:`, error.message);
          errorCount++;
        }
      }

      processedCount++;
      
      // Rate limiting - đợi 2 giây giữa các nodes
      console.log(`  ⏳ Waiting 2s before next node...`);
      await new Promise(resolve => setTimeout(resolve, 2000));
    }

    console.log('\n' + '='.repeat(50));
    console.log('📊 Summary:');
    console.log(`  - Processed: ${processedCount} nodes`);
    console.log(`  - Skipped: ${skippedCount} nodes`);
    console.log(`  - Errors: ${errorCount}`);
    console.log('='.repeat(50));

  } catch (error) {
    console.error('❌ Script failed:', error);
  } finally {
    await app.close();
  }
}

async function generateContentForDifficulty(
  aiService: AiService,
  node: LearningNode,
  baseConcepts: ContentItem[],
  baseExamples: ContentItem[],
  difficulty: 'easy' | 'medium' | 'hard',
): Promise<{
  concepts: DifficultyContent[];
  examples: DifficultyContent[];
}> {
  const difficultyDescriptions = {
    easy: {
      label: 'ĐƠN GIẢN',
      description: 'Nội dung cơ bản, ngắn gọn, dễ hiểu, phù hợp người mới bắt đầu',
      wordCount: '300-500 từ',
      style: 'Giải thích đơn giản, ít thuật ngữ chuyên môn, nhiều ví dụ minh họa đời thường',
    },
    medium: {
      label: 'CHI TIẾT',
      description: 'Nội dung cân bằng, đầy đủ thông tin, phù hợp đa số người học',
      wordCount: '600-1000 từ',
      style: 'Giải thích đầy đủ, có thuật ngữ kèm giải nghĩa, ví dụ thực tế',
    },
    hard: {
      label: 'CHUYÊN SÂU',
      description: 'Nội dung nâng cao, chuyên sâu, phù hợp người đã có nền tảng',
      wordCount: '1000-2000 từ',
      style: 'Phân tích sâu, thuật ngữ chuyên ngành, case studies phức tạp, liên hệ lý thuyết nâng cao',
    },
  };

  const diffConfig = difficultyDescriptions[difficulty];

  // Lấy một số concepts/examples base để tham khảo
  const baseConceptTitles = baseConcepts.slice(0, 3).map(c => c.title).join(', ');
  const baseExampleTitles = baseExamples.slice(0, 3).map(e => e.title).join(', ');

  const prompt = `Bạn là chuyên gia giáo dục. Nhiệm vụ: Tạo nội dung học tập ở mức độ ${diffConfig.label} cho bài học "${node.title}".

THÔNG TIN BÀI HỌC:
- Tiêu đề: ${node.title}
- Mô tả: ${node.description || 'Không có mô tả'}
- Môn học: ${(node as any).subject?.name || 'Chưa xác định'}

CÁC KHÁI NIỆM ĐÃ CÓ (tham khảo):
${baseConceptTitles || 'Chưa có'}

CÁC VÍ DỤ ĐÃ CÓ (tham khảo):
${baseExampleTitles || 'Chưa có'}

YÊU CẦU MỨC ĐỘ ${diffConfig.label}:
- Mô tả: ${diffConfig.description}
- Số từ mỗi phần: ${diffConfig.wordCount}
- Phong cách: ${diffConfig.style}

TẠO NỘI DUNG MỚI:
1. concepts: 2-3 khái niệm ở mức ${diffConfig.label}
   - Mỗi concept có title và content (${diffConfig.wordCount})
   - Nội dung PHẢI phù hợp mức độ ${diffConfig.label}
   - Sử dụng markdown để format

2. examples: 2-3 ví dụ ở mức ${diffConfig.label}
   - Mỗi example có title và content (${diffConfig.wordCount})
   - Ví dụ PHẢI phù hợp mức độ ${diffConfig.label}
   - Sử dụng markdown để format

${difficulty === 'easy' ? `
LƯU Ý CHO MỨC ĐƠN GIẢN:
- Dùng ngôn ngữ đơn giản, không chuyên môn
- Giải thích từng bước, rõ ràng
- Sử dụng analogies (ví von) từ đời thường
- Tránh thuật ngữ phức tạp
` : difficulty === 'hard' ? `
LƯU Ý CHO MỨC CHUYÊN SÂU:
- Đi sâu vào lý thuyết nền tảng
- Sử dụng thuật ngữ chuyên ngành (có giải thích)
- Phân tích các edge cases, exceptions
- Liên hệ đến các khái niệm nâng cao
- Bao gồm best practices và anti-patterns
` : ''}

Trả về JSON:
{
  "concepts": [
    {
      "title": "Tên khái niệm",
      "content": "Nội dung markdown..."
    }
  ],
  "examples": [
    {
      "title": "Tên ví dụ",
      "content": "Nội dung markdown..."
    }
  ]
}`;

  const response = await aiService.chat([{ role: 'user', content: prompt }]);
  
  // Parse JSON response
  const cleanedResponse = response
    .replace(/```json\n?/g, '')
    .replace(/```\n?/g, '')
    .trim();

  const result = JSON.parse(cleanedResponse);

  return {
    concepts: (result.concepts || []).map((c: any) => ({
      title: c.title,
      content: c.content,
      difficulty: difficulty,
    })),
    examples: (result.examples || []).map((e: any) => ({
      title: e.title,
      content: e.content,
      difficulty: difficulty,
    })),
  };
}

// Run the script
generateDifficultyContent()
  .then(() => {
    console.log('\n✅ Script completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Script failed:', error);
    process.exit(1);
  });
