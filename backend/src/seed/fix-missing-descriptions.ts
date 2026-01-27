/**
 * Script để fix các video/image contributions đã được approved nhưng thiếu description trong media
 * Chạy: npx ts-node src/seed/fix-missing-descriptions.ts
 */

import { DataSource } from 'typeorm';
import { config } from 'dotenv';
config();

async function fixMissingDescriptions() {
  const dataSource = new DataSource({
    type: 'postgres',
    url: process.env.DATABASE_URL,
    synchronize: false,
  });

  await dataSource.initialize();
  console.log('✅ Connected to database');

  const queryRunner = dataSource.createQueryRunner();

  try {
    // Find all approved edits that have descriptions
    const approvedEditsWithDescription = await queryRunner.query(`
      SELECT 
        ce.id as edit_id,
        ce."contentItemId",
        ce.type,
        ce.description,
        ce.media,
        ci.title as content_title,
        ci.media as content_media
      FROM content_edits ce
      JOIN content_items ci ON ci.id = ce."contentItemId"
      WHERE ce.status = 'approved'
        AND ce.type IN ('add_video', 'add_image')
        AND ce.description IS NOT NULL
        AND ce.description != ''
    `);

    console.log(`\n📋 Tìm thấy ${approvedEditsWithDescription.length} edits có description cần kiểm tra:\n`);

    let fixedCount = 0;
    for (const edit of approvedEditsWithDescription) {
      const currentMedia = edit.content_media || {};
      const hasDescription = currentMedia.description && currentMedia.description.trim() !== '';

      console.log(`\n📝 Content: ${edit.content_title}`);
      console.log(`   Edit type: ${edit.type}`);
      console.log(`   Edit description: ${edit.description?.substring(0, 50)}...`);
      console.log(`   Current media.description: ${currentMedia.description || '(empty)'}`);

      if (!hasDescription) {
        // Update the content item's media to include description
        const newMedia = {
          ...currentMedia,
          description: edit.description,
        };

        // If edit has caption in media, add that too
        if (edit.media?.caption) {
          newMedia.caption = edit.media.caption;
        }

        await queryRunner.query(`
          UPDATE content_items
          SET media = $1::jsonb,
              "updatedAt" = NOW()
          WHERE id = $2
        `, [JSON.stringify(newMedia), edit.contentItemId]);

        console.log(`   ✅ Đã thêm description vào content_items.media`);
        fixedCount++;
      } else {
        console.log(`   ⏭️ Đã có description, bỏ qua`);
      }
    }

    console.log(`\n\n========================================`);
    console.log(`✅ Hoàn tất! Đã fix ${fixedCount}/${approvedEditsWithDescription.length} content items`);
    console.log(`========================================\n`);

  } catch (error) {
    console.error('❌ Lỗi:', error);
  } finally {
    await queryRunner.release();
    await dataSource.destroy();
  }
}

fixMissingDescriptions();
