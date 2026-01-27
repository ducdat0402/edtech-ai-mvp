/**
 * Script để fix các bài đóng góp đã được duyệt nhưng ContentItem vẫn còn status='placeholder'
 * 
 * Run: npx ts-node src/seed/fix-approved-contributions.ts
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { DataSource } from 'typeorm';

async function bootstrap() {
  console.log('🔧 Fix Approved Contributions - Starting...\n');

  const app = await NestFactory.createApplicationContext(AppModule);
  const dataSource = app.get(DataSource);

  try {
    // Find all approved content edits
    const approvedEdits = await dataSource.query(`
      SELECT ce.*, ci.status as content_status, ci.title as content_title
      FROM content_edits ce
      JOIN content_items ci ON ce."contentItemId" = ci.id
      WHERE ce.status = 'approved'
      AND (ci.status = 'placeholder' OR ci.status = 'awaiting_review')
    `);

    console.log(`📋 Found ${approvedEdits.length} approved edits with placeholder/awaiting_review content items\n`);

    if (approvedEdits.length === 0) {
      console.log('✅ No content items need fixing!\n');
      await app.close();
      process.exit(0);
    }

    for (const edit of approvedEdits) {
      console.log(`🔄 Fixing content item: ${edit.content_title}`);
      console.log(`   Edit ID: ${edit.id}`);
      console.log(`   Edit Type: ${edit.type}`);
      console.log(`   Current Status: ${edit.content_status}`);

      // Update content item
      let mediaUpdate = '';
      if (edit.type === 'add_video' && edit.media?.videoUrl) {
        mediaUpdate = `, media = media || '{}' || jsonb_build_object('videoUrl', '${edit.media.videoUrl}')`;
      } else if (edit.type === 'add_image' && edit.media?.imageUrl) {
        mediaUpdate = `, media = media || '{}' || jsonb_build_object('imageUrl', '${edit.media.imageUrl}')`;
      }

      // Clean title (remove emoji prefix)
      const cleanTitle = edit.content_title?.replace(/^(🎬|🖼️)\s*/, '') || edit.content_title;

      await dataSource.query(`
        UPDATE content_items
        SET 
          status = 'published',
          title = $1,
          "contributorId" = $2,
          "contributedAt" = NOW(),
          "updatedAt" = NOW()
        WHERE id = $3
      `, [cleanTitle, edit.userId, edit.contentItemId]);

      // Update media separately if needed
      if (edit.type === 'add_video' && edit.media?.videoUrl) {
        await dataSource.query(`
          UPDATE content_items
          SET media = COALESCE(media, '{}'::jsonb) || $1::jsonb
          WHERE id = $2
        `, [JSON.stringify({ videoUrl: edit.media.videoUrl }), edit.contentItemId]);
      } else if (edit.type === 'add_image' && edit.media?.imageUrl) {
        await dataSource.query(`
          UPDATE content_items
          SET media = COALESCE(media, '{}'::jsonb) || $1::jsonb
          WHERE id = $2
        `, [JSON.stringify({ imageUrl: edit.media.imageUrl }), edit.contentItemId]);
      }

      console.log(`   ✅ Updated to 'published'\n`);
    }

    console.log(`\n🎉 Successfully fixed ${approvedEdits.length} content items!`);

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await app.close();
    process.exit(0);
  }
}

bootstrap();
