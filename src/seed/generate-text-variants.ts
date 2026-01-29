/**
 * Script: Generate Text Variants for All Content Items
 * 
 * Tự động tạo 3 phiên bản text (simple, detailed, comprehensive) cho mỗi bài học
 * Chỉ áp dụng cho content type: 'concept' và 'example'
 * 
 * Usage: npx ts-node src/seed/generate-text-variants.ts
 * 
 * Options:
 *   --node-id=<id>     Generate for specific node only
 *   --subject-id=<id>  Generate for all nodes in a subject
 *   --force            Regenerate even if variants already exist
 *   --dry-run          Preview what would be generated without saving
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { ContentItemsService } from '../content-items/content-items.service';
import { LearningNodesService } from '../learning-nodes/learning-nodes.service';
import { Repository } from 'typeorm';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { getRepositoryToken } from '@nestjs/typeorm';

async function bootstrap() {
  console.log('🚀 Starting Text Variants Generation Script...\n');

  // Parse command line arguments
  const args = process.argv.slice(2);
  const nodeId = args.find(a => a.startsWith('--node-id='))?.split('=')[1];
  const subjectId = args.find(a => a.startsWith('--subject-id='))?.split('=')[1];
  const force = args.includes('--force');
  const dryRun = args.includes('--dry-run');

  if (dryRun) {
    console.log('📋 DRY RUN MODE - No changes will be saved\n');
  }

  if (force) {
    console.log('⚠️  FORCE MODE - Will regenerate existing variants\n');
  }

  // Initialize NestJS app
  const app = await NestFactory.createApplicationContext(AppModule);
  const contentService = app.get(ContentItemsService);
  const nodesService = app.get(LearningNodesService);
  const contentRepo = app.get<Repository<ContentItem>>(getRepositoryToken(ContentItem));

  try {
    let contentItems: ContentItem[] = [];

    // Get content items based on options
    if (nodeId) {
      console.log(`📍 Generating for node: ${nodeId}\n`);
      contentItems = await contentRepo.find({
        where: { nodeId },
        relations: ['node', 'node.subject'],
        order: { order: 'ASC' },
      });
    } else if (subjectId) {
      console.log(`📍 Generating for subject: ${subjectId}\n`);
      const nodes = await nodesService.findBySubject(subjectId);
      for (const node of nodes) {
        const items = await contentRepo.find({
          where: { nodeId: node.id },
          relations: ['node', 'node.subject'],
          order: { order: 'ASC' },
        });
        contentItems.push(...items);
      }
    } else {
      console.log('📍 Generating for ALL content items\n');
      contentItems = await contentRepo.find({
        relations: ['node', 'node.subject'],
        order: { createdAt: 'ASC' },
      });
    }

    // Filter to only concept and example types
    const textContents = contentItems.filter(
      c => c.type === 'concept' || c.type === 'example'
    );

    console.log(`📊 Found ${textContents.length} text-based content items\n`);

    if (textContents.length === 0) {
      console.log('⚠️  No content items to process');
      await app.close();
      return;
    }

    // Statistics
    let processed = 0;
    let skipped = 0;
    let failed = 0;
    let alreadyHasVariants = 0;

    // Process each content item
    for (let i = 0; i < textContents.length; i++) {
      const content = textContents[i];
      const progress = `[${i + 1}/${textContents.length}]`;

      // Check if already has variants
      if (!force && content.textVariants?.simple && content.textVariants?.comprehensive) {
        console.log(`${progress} ⏭️  Skipping "${content.title}" - already has variants`);
        alreadyHasVariants++;
        continue;
      }

      // Check if has content to process
      if (!content.content || content.content.trim().length < 50) {
        console.log(`${progress} ⏭️  Skipping "${content.title}" - content too short or empty`);
        skipped++;
        continue;
      }

      console.log(`${progress} 🔄 Processing: "${content.title}"`);
      console.log(`     Type: ${content.type} | Node: ${content.node?.title || 'Unknown'}`);

      if (dryRun) {
        console.log(`     [DRY RUN] Would generate 3 variants\n`);
        processed++;
        continue;
      }

      try {
        // Generate variants
        const result = await contentService.generateTextVariants(content.id);
        
        console.log(`     ✅ Generated 3 variants:`);
        console.log(`        - Simple: ${result.textVariants?.simple?.length || 0} chars`);
        console.log(`        - Detailed: ${result.textVariants?.detailed?.length || 0} chars`);
        console.log(`        - Comprehensive: ${result.textVariants?.comprehensive?.length || 0} chars\n`);
        
        processed++;

        // Rate limiting - wait 1 second between API calls
        if (i < textContents.length - 1) {
          await sleep(1000);
        }
      } catch (error) {
        console.log(`     ❌ Failed: ${error.message}\n`);
        failed++;
      }
    }

    // Print summary
    console.log('\n' + '='.repeat(60));
    console.log('📊 GENERATION SUMMARY');
    console.log('='.repeat(60));
    console.log(`Total content items:     ${textContents.length}`);
    console.log(`✅ Successfully processed: ${processed}`);
    console.log(`⏭️  Already had variants:  ${alreadyHasVariants}`);
    console.log(`⏭️  Skipped (no content):  ${skipped}`);
    console.log(`❌ Failed:                 ${failed}`);
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

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Run the script
bootstrap().catch(console.error);
