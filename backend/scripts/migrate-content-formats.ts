import { config } from 'dotenv';
import * as path from 'path';
import { DataSource } from 'typeorm';
import { ContentItem } from '../src/content-items/entities/content-item.entity';

// Load environment variables
config({ path: path.join(__dirname, '../.env') });

async function migrateFormats() {
  const dataSource = new DataSource({
    type: 'postgres',
    url: process.env.DATABASE_URL,
    entities: [ContentItem],
    synchronize: false,
  });

  try {
    await dataSource.initialize();
    console.log('✅ Connected to database');

    const contentItemRepository = dataSource.getRepository(ContentItem);
    const items = await contentItemRepository.find();
    
    console.log(`\n📊 Found ${items.length} content items to migrate\n`);

    let updated = 0;
    let errors = 0;

    for (const item of items) {
      try {
        // Detect format
        const hasVideo = item.media?.videoUrl && item.media.videoUrl.trim() !== '';
        const hasImage = item.media?.imageUrl && item.media.imageUrl.trim() !== '';
        const hasQuiz = item.quizData && item.quizData.question;
        const hasContent = item.content && item.content.trim() !== '';

        let format: 'video' | 'image' | 'mixed' | 'quiz' | 'text' = 'text';
        if (hasQuiz) {
          format = 'quiz';
        } else if (hasVideo && hasImage) {
          format = 'mixed';
        } else if (hasVideo) {
          format = 'video';
        } else if (hasImage) {
          format = 'image';
        } else if (hasContent) {
          format = 'text';
        }

        // Set difficulty if not set
        let difficulty: 'easy' | 'medium' | 'hard' | 'expert' = item.difficulty || 'medium';

        // Calculate rewards if not set or incomplete
        const rewardsMap = {
          easy: { xp: 10, coin: 5 },
          medium: { xp: 25, coin: 10 },
          hard: { xp: 50, coin: 20 },
          expert: { xp: 100, coin: 50 },
        };
        const defaultRewards = rewardsMap[difficulty];
        const rewards = {
          ...defaultRewards,
          ...(item.rewards || {}),
        };

        // Update if needed
        const needsUpdate = 
          item.format !== format || 
          item.difficulty !== difficulty ||
          item.rewards?.xp !== rewards.xp ||
          item.rewards?.coin !== rewards.coin;

        if (needsUpdate) {
          item.format = format;
          item.difficulty = difficulty;
          item.rewards = rewards;
          await contentItemRepository.save(item);
          updated++;
          console.log(`✅ Updated: ${item.title.substring(0, 40)}... (format: ${format}, difficulty: ${difficulty})`);
        }
      } catch (error) {
        errors++;
        console.error(`❌ Error updating ${item.id}: ${error.message}`);
      }
    }

    console.log(`\n📊 Migration Summary:`);
    console.log(`   ✅ Updated: ${updated}`);
    console.log(`   ❌ Errors: ${errors}`);
    console.log(`   ⏭️  Skipped: ${items.length - updated - errors}\n`);

    await dataSource.destroy();
    console.log('✅ Migration completed!');
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

migrateFormats();

