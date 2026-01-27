/**
 * Check recent contributions and their media URLs
 */
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { Repository } from 'typeorm';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { ContentEdit } from '../content-edits/entities/content-edit.entity';
import { getRepositoryToken } from '@nestjs/typeorm';

async function checkContributions() {
  console.log('🔍 Checking recent contributions...\n');

  const app = await NestFactory.createApplicationContext(AppModule);
  const contentItemRepo = app.get<Repository<ContentItem>>(getRepositoryToken(ContentItem));
  const contentEditRepo = app.get<Repository<ContentEdit>>(getRepositoryToken(ContentEdit));

  try {
    // Check recent approved content edits with media
    console.log('📋 Recent APPROVED content edits with media:\n');
    const approvedEdits = await contentEditRepo
      .createQueryBuilder('edit')
      .where("edit.status = 'approved'")
      .andWhere("(edit.media->>'imageUrl' IS NOT NULL OR edit.media->>'videoUrl' IS NOT NULL)")
      .orderBy('edit.updatedAt', 'DESC')
      .limit(10)
      .getMany();

    for (const edit of approvedEdits) {
      console.log(`Edit ID: ${edit.id}`);
      console.log(`  Content Item: ${edit.contentItemId}`);
      console.log(`  Type: ${edit.type}`);
      console.log(`  Status: ${edit.status}`);
      console.log(`  Image URL: ${edit.media?.imageUrl || 'N/A'}`);
      console.log(`  Video URL: ${edit.media?.videoUrl || 'N/A'}`);
      console.log(`  Updated: ${edit.updatedAt}`);
      
      // Check the actual content item
      const contentItem = await contentItemRepo.findOne({
        where: { id: edit.contentItemId },
      });
      
      if (contentItem) {
        console.log(`  → Content Item imageUrl: ${contentItem.media?.imageUrl || 'N/A'}`);
        console.log(`  → Content Item videoUrl: ${contentItem.media?.videoUrl || 'N/A'}`);
        
        // Check if URLs match
        if (edit.media?.imageUrl && contentItem.media?.imageUrl !== edit.media.imageUrl) {
          console.log(`  ⚠️ WARNING: Image URL mismatch!`);
        }
        if (edit.media?.videoUrl && contentItem.media?.videoUrl !== edit.media.videoUrl) {
          console.log(`  ⚠️ WARNING: Video URL mismatch!`);
        }
      }
      console.log('');
    }

    // Check content items with contributorId (recent contributions)
    console.log('\n📋 Content items with recent contributions:\n');
    const contributedItems = await contentItemRepo
      .createQueryBuilder('item')
      .where('item.contributorId IS NOT NULL')
      .orderBy('item.contributedAt', 'DESC')
      .limit(10)
      .getMany();

    for (const item of contributedItems) {
      console.log(`Content: ${item.title}`);
      console.log(`  ID: ${item.id}`);
      console.log(`  Contributor: ${item.contributorId}`);
      console.log(`  Contributed at: ${item.contributedAt}`);
      console.log(`  Image URL: ${item.media?.imageUrl || 'N/A'}`);
      console.log(`  Video URL: ${item.media?.videoUrl || 'N/A'}`);
      
      // Check URL type
      if (item.media?.imageUrl) {
        if (item.media.imageUrl.includes('cloudinary')) {
          console.log(`  → Image stored on: Cloudinary ✅`);
        } else if (item.media.imageUrl.includes('/uploads/')) {
          console.log(`  → Image stored on: Local server ⚠️`);
        } else if (item.media.imageUrl.includes('placehold.co')) {
          console.log(`  → Image stored on: Placeholder (not real!) ❌`);
        }
      }
      console.log('');
    }

  } finally {
    await app.close();
  }
}

checkContributions()
  .then(() => process.exit(0))
  .catch(e => { console.error(e); process.exit(1); });
