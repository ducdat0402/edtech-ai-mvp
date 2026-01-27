/**
 * Check if content items have media descriptions
 */
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { Repository } from 'typeorm';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { getRepositoryToken } from '@nestjs/typeorm';

async function checkMediaDescriptions() {
  console.log('🔍 Checking media descriptions in database...\n');

  const app = await NestFactory.createApplicationContext(AppModule);
  const contentItemRepo = app.get<Repository<ContentItem>>(getRepositoryToken(ContentItem));

  try {
    // Get sample items
    const items = await contentItemRepo
      .createQueryBuilder('item')
      .where("item.type IN ('concept', 'example')")
      .limit(5)
      .getMany();

    console.log('📋 Sample content items:\n');
    for (const item of items) {
      console.log(`--- ${item.title} (${item.difficulty}) ---`);
      console.log('  imagePrompt:', item.media?.imagePrompt ? '✅ ' + item.media.imagePrompt.substring(0, 80) + '...' : '❌ NULL');
      console.log('  imageDescription:', item.media?.imageDescription ? '✅ ' + item.media.imageDescription.substring(0, 80) + '...' : '❌ NULL');
      console.log('  videoScript:', item.media?.videoScript ? '✅ ' + item.media.videoScript.substring(0, 80) + '...' : '❌ NULL');
      console.log('  videoDescription:', item.media?.videoDescription ? '✅ ' + item.media.videoDescription.substring(0, 80) + '...' : '❌ NULL');
      console.log('');
    }

    // Count statistics
    const allItems = await contentItemRepo
      .createQueryBuilder('item')
      .where("item.type IN ('concept', 'example')")
      .getMany();

    let hasImagePrompt = 0;
    let hasImageDesc = 0;
    let hasVideoScript = 0;
    let hasVideoDesc = 0;

    for (const item of allItems) {
      if (item.media?.imagePrompt) hasImagePrompt++;
      if (item.media?.imageDescription) hasImageDesc++;
      if (item.media?.videoScript) hasVideoScript++;
      if (item.media?.videoDescription) hasVideoDesc++;
    }

    console.log('='.repeat(50));
    console.log('📊 STATISTICS:');
    console.log(`   Total items: ${allItems.length}`);
    console.log(`   Has imagePrompt: ${hasImagePrompt} (${(hasImagePrompt/allItems.length*100).toFixed(1)}%)`);
    console.log(`   Has imageDescription: ${hasImageDesc} (${(hasImageDesc/allItems.length*100).toFixed(1)}%)`);
    console.log(`   Has videoScript: ${hasVideoScript} (${(hasVideoScript/allItems.length*100).toFixed(1)}%)`);
    console.log(`   Has videoDescription: ${hasVideoDesc} (${(hasVideoDesc/allItems.length*100).toFixed(1)}%)`);
    console.log('='.repeat(50));

  } finally {
    await app.close();
  }
}

checkMediaDescriptions()
  .then(() => process.exit(0))
  .catch(e => { console.error(e); process.exit(1); });
