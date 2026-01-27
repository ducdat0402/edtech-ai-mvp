/**
 * Script: Regenerate All Content Items
 * 
 * Xóa tất cả content items và tạo lại với cấu trúc mới:
 * - Mỗi node có số bài học nhất định (concepts + examples)
 * - Mỗi bài học có: văn bản (3 dạng), video placeholder, hình ảnh placeholder
 * 
 * Usage: npx ts-node src/seed/regenerate-all-content.ts
 * 
 * Options:
 *   --node-id=<id>     Regenerate for specific node only
 *   --subject-id=<id>  Regenerate for all nodes in a subject
 *   --dry-run          Preview what would be generated without saving
 *   --skip-delete      Don't delete existing content (add new only)
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { AiService } from '../ai/ai.service';
import { Repository } from 'typeorm';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { getRepositoryToken } from '@nestjs/typeorm';

// Configuration
const LESSONS_PER_NODE = 5;  // Số bài học (khái niệm) mỗi node

interface GeneratedLesson {
  title: string;
  textVariants: {
    simple: string;
    detailed: string;
    comprehensive: string;
  };
  media: {
    imagePrompt: string;
    imageDescription: string;
    videoScript: string;
    videoDescription: string;
  };
}

async function bootstrap() {
  console.log('🚀 Starting Content Regeneration Script...\n');
  console.log('📋 Configuration:');
  console.log(`   - Lessons per node: ${LESSONS_PER_NODE}`);
  console.log(`   - Each lesson has: Text (3 variants) + Image + Video\n`);

  // Parse command line arguments
  const args = process.argv.slice(2);
  const nodeId = args.find(a => a.startsWith('--node-id='))?.split('=')[1];
  const subjectId = args.find(a => a.startsWith('--subject-id='))?.split('=')[1];
  const dryRun = args.includes('--dry-run');
  const skipDelete = args.includes('--skip-delete');

  if (dryRun) {
    console.log('📋 DRY RUN MODE - No changes will be saved\n');
  }

  // Initialize NestJS app
  const app = await NestFactory.createApplicationContext(AppModule);
  const aiService = app.get(AiService);
  const contentRepo = app.get<Repository<ContentItem>>(getRepositoryToken(ContentItem));
  const nodeRepo = app.get<Repository<LearningNode>>(getRepositoryToken(LearningNode));

  try {
    // Get nodes to process
    let nodes: LearningNode[] = [];

    if (nodeId) {
      console.log(`📍 Processing specific node: ${nodeId}\n`);
      const node = await nodeRepo.findOne({
        where: { id: nodeId },
        relations: ['subject'],
      });
      if (node) nodes = [node];
    } else if (subjectId) {
      console.log(`📍 Processing all nodes in subject: ${subjectId}\n`);
      nodes = await nodeRepo.find({
        where: { subjectId },
        relations: ['subject'],
        order: { order: 'ASC' },
      });
    } else {
      console.log('📍 Processing ALL nodes\n');
      nodes = await nodeRepo.find({
        relations: ['subject'],
        order: { subjectId: 'ASC', order: 'ASC' },
      });
    }

    console.log(`📊 Found ${nodes.length} nodes to process\n`);

    if (nodes.length === 0) {
      console.log('⚠️  No nodes to process');
      await app.close();
      return;
    }

    // Statistics
    let totalDeleted = 0;
    let totalCreated = 0;
    let nodesFailed = 0;

    // Process each node
    for (let i = 0; i < nodes.length; i++) {
      const node = nodes[i];
      const progress = `[${i + 1}/${nodes.length}]`;
      
      console.log(`${progress} 🔄 Processing node: "${node.title}"`);
      console.log(`     Subject: ${node.subject?.name || 'Unknown'}`);

      if (dryRun) {
        console.log(`     [DRY RUN] Would generate ${LESSONS_PER_NODE} lessons\n`);
        continue;
      }

      // Step 1: Generate new content using AI FIRST (before deleting!)
      try {
        const lessons = await generateLessonsForNode(
          aiService,
          node.title,
          node.description || '',
          node.subject?.name || 'Không xác định',
        );

        if (!lessons || lessons.length === 0) {
          throw new Error('AI returned no lessons');
        }

        console.log(`     📝 AI generated ${lessons.length} lessons`);

        // Step 2: Only delete AFTER successful generation
        if (!skipDelete) {
          const deleteResult = await contentRepo.delete({ nodeId: node.id });
          const deleted = deleteResult.affected || 0;
          totalDeleted += deleted;
          console.log(`     🗑️  Deleted ${deleted} existing content items`);
        } else {
          console.log(`     ⏭️  Skipping delete (--skip-delete)`);
        }

        // Step 3: Save new content items
        let order = 0;
        for (const lesson of lessons) {
          const contentItem = contentRepo.create({
            nodeId: node.id,
            type: 'concept', // All lessons are concepts now
            title: lesson.title,
            content: lesson.textVariants?.detailed || '', // Default content
            textVariants: lesson.textVariants || {},
            format: 'text', // Will become 'mixed' when media is added
            difficulty: 'medium',
            status: 'published',
            order: order++,
            media: {
              imagePrompt: lesson.media?.imagePrompt || '',
              imageDescription: lesson.media?.imageDescription || '',
              videoScript: lesson.media?.videoScript || '',
              videoDescription: lesson.media?.videoDescription || '',
              // Placeholder URLs (community will contribute real ones)
              imageUrl: 'https://placehold.co/800x600/1a1a2e/ffffff?text=Cần+hình+ảnh',
              videoUrl: '',
            },
            rewards: {
              xp: 15,
              coin: 3,
            },
          });

          await contentRepo.save(contentItem);
          totalCreated++;
        }

        console.log(`     ✅ Created ${lessons.length} content items\n`);

        // Rate limiting
        if (i < nodes.length - 1) {
          await sleep(2000); // 2 seconds between nodes
        }

      } catch (error) {
        console.log(`     ❌ Failed: ${error.message}`);
        console.log(`     ⚠️  Content NOT deleted (safe mode)\n`);
        nodesFailed++;
      }
    }

    // Print summary
    console.log('\n' + '='.repeat(60));
    console.log('📊 REGENERATION SUMMARY');
    console.log('='.repeat(60));
    console.log(`Nodes processed:        ${nodes.length}`);
    console.log(`🗑️  Content deleted:     ${totalDeleted}`);
    console.log(`✅ Content created:      ${totalCreated}`);
    console.log(`❌ Nodes failed:         ${nodesFailed}`);
    console.log('='.repeat(60));

    if (dryRun) {
      console.log('\n📋 This was a DRY RUN. Run without --dry-run to apply changes.');
    }

  } catch (error) {
    console.error('❌ Script failed:', error);
  } finally {
    await app.close();
    console.log('\n✅ Script completed');
  }
}

/**
 * Fix common JSON issues from AI responses
 */
function fixJsonString(jsonStr: string): string {
  let fixed = jsonStr;
  
  // Remove markdown code blocks
  fixed = fixed.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
  
  // Fix newlines inside strings (convert to \n)
  // This is tricky - we need to handle multi-line strings properly
  fixed = fixed.replace(/\n/g, '\\n');
  
  // But restore newlines that should be between JSON elements
  fixed = fixed.replace(/\\n\s*"/g, '\n"');
  fixed = fixed.replace(/\\n\s*}/g, '\n}');
  fixed = fixed.replace(/\\n\s*]/g, '\n]');
  fixed = fixed.replace(/\\n\s*{/g, '\n{');
  fixed = fixed.replace(/\\n\s*\[/g, '\n[');
  fixed = fixed.replace(/,\\n/g, ',\n');
  
  // Remove trailing commas before } or ]
  fixed = fixed.replace(/,(\s*[}\]])/g, '$1');
  
  // Fix unescaped quotes inside strings (very common issue)
  // This regex looks for quotes that are likely inside string values
  fixed = fixed.replace(/"([^"]*)"([^":,}\]]*)"([^"]*)"/g, '"$1\\"$2\\"$3"');
  
  // Fix control characters
  fixed = fixed.replace(/[\x00-\x1F\x7F]/g, (char) => {
    if (char === '\n' || char === '\r' || char === '\t') return char;
    return '';
  });
  
  return fixed;
}

/**
 * Parse JSON with multiple fallback strategies
 */
function parseJsonSafe(jsonStr: string): any {
  // Strategy 1: Direct parse
  try {
    return JSON.parse(jsonStr);
  } catch (e) {
    // Continue to next strategy
  }
  
  // Strategy 2: Fix and parse
  try {
    const fixed = fixJsonString(jsonStr);
    return JSON.parse(fixed);
  } catch (e) {
    // Continue to next strategy
  }
  
  // Strategy 3: Extract JSON object/array with regex
  try {
    const jsonMatch = jsonStr.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      return JSON.parse(fixJsonString(jsonMatch[0]));
    }
  } catch (e) {
    // Continue to next strategy
  }
  
  // Strategy 4: Try to find and parse lessons array directly
  try {
    const lessonsMatch = jsonStr.match(/"lessons"\s*:\s*\[([\s\S]*)\]/);
    if (lessonsMatch) {
      return { lessons: JSON.parse('[' + fixJsonString(lessonsMatch[1]) + ']') };
    }
  } catch (e) {
    // All strategies failed
  }
  
  throw new Error('Unable to parse JSON response');
}

/**
 * Generate lessons for a node using AI with JSON mode
 */
async function generateLessonsForNode(
  aiService: AiService,
  nodeTitle: string,
  nodeDescription: string,
  subjectName: string,
  retryCount = 0,
): Promise<GeneratedLesson[]> {
  
  const prompt = `Tạo ${LESSONS_PER_NODE} bài học JSON cho chủ đề "${nodeTitle}" (${subjectName}).

Mỗi bài cần: title, textVariants (simple/detailed/comprehensive), media (imagePrompt/imageDescription/videoScript/videoDescription).

Trả về: {"lessons":[...]}`;

  try {
    // Use chatWithJsonMode for guaranteed valid JSON
    const response = await aiService.chatWithJsonMode([{ role: 'user', content: prompt }]);
    
    // Try to parse
    let result: any;
    try {
      result = JSON.parse(response);
    } catch (e) {
      // Try with fixes
      result = parseJsonSafe(response);
    }
    
    if (!result.lessons || result.lessons.length === 0) {
      throw new Error('No lessons in response');
    }
    
    return result.lessons;
    
  } catch (error) {
    // Retry up to 2 times
    if (retryCount < 2) {
      console.log(`     ⚠️  Parse failed (${error.message}), retrying (${retryCount + 1}/2)...`);
      await sleep(2000);
      return generateLessonsForNode(aiService, nodeTitle, nodeDescription, subjectName, retryCount + 1);
    }
    
    // Log error details for debugging
    console.log(`     📋 Error details: ${error.message}`);
    throw error;
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Run the script
bootstrap().catch(console.error);
