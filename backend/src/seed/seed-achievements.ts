import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { DataSource } from 'typeorm';
import { Achievement, AchievementRarity, AchievementType } from '../achievements/entities/achievement.entity';
import { AppModule } from '../app.module';

async function seedAchievements() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const dataSource = app.get(DataSource);
  const repo = dataSource.getRepository(Achievement);

  const defs: Array<Partial<Achievement>> = [
    {
      code: 'first_steps',
      name: 'Bước chân đầu tiên',
      description: 'Hoàn thành bài học đầu tiên của bạn.',
      type: AchievementType.COMPLETION,
      rarity: AchievementRarity.COMMON,
      requirements: { completedNodes: 1 },
      rewards: { xp: 50, coins: 10 },
      iconUrl:
        'https://cdn-icons-png.flaticon.com/512/190/190411.png', // bước chân
      order: 1,
    },
    {
      code: 'streak_7',
      name: 'Chuỗi 7 ngày',
      description: 'Học liên tục 7 ngày không bỏ lỡ.',
      type: AchievementType.STREAK,
      rarity: AchievementRarity.UNCOMMON,
      requirements: { streak: 7 },
      rewards: { xp: 150, coins: 30 },
      iconUrl:
        'https://cdn-icons-png.flaticon.com/512/4834/4834679.png', // ngọn lửa nhỏ
      order: 2,
    },
    {
      code: 'streak_30',
      name: 'Chiến binh 30 ngày',
      description: 'Duy trì streak 30 ngày liên tiếp.',
      type: AchievementType.STREAK,
      rarity: AchievementRarity.RARE,
      requirements: { streak: 30 },
      rewards: { xp: 400, coins: 80 },
      iconUrl:
        'https://cdn-icons-png.flaticon.com/512/992/992700.png', // ngọn lửa lớn
      order: 3,
    },
    {
      code: 'xp_1000',
      name: 'Người ham học',
      description: 'Tích lũy 1,000 XP trong hành trình học.',
      type: AchievementType.MILESTONE,
      rarity: AchievementRarity.UNCOMMON,
      requirements: { xp: 1000 },
      rewards: { xp: 200, coins: 40 },
      iconUrl:
        'https://cdn-icons-png.flaticon.com/512/1821/1821065.png', // cúp vàng
      order: 4,
    },
    {
      code: 'subject_finisher',
      name: 'Hoàn thành môn học',
      description: 'Hoàn thành toàn bộ node của một môn bất kỳ.',
      type: AchievementType.COMPLETION,
      rarity: AchievementRarity.RARE,
      requirements: { completedSubjects: 1 },
      rewards: { xp: 300, coins: 60 },
      iconUrl:
        'https://cdn-icons-png.flaticon.com/512/3135/3135789.png', // mũ tốt nghiệp
      order: 5,
    },
    {
      code: 'quest_master_10',
      name: 'Thợ săn nhiệm vụ',
      description: 'Hoàn thành 10 nhiệm vụ hằng ngày.',
      type: AchievementType.QUEST_MASTER,
      rarity: AchievementRarity.UNCOMMON,
      requirements: { questsCompleted: 10 },
      rewards: { xp: 150, coins: 50 },
      iconUrl:
        'https://cdn-icons-png.flaticon.com/512/3209/3209265.png', // danh hiệu nhiệm vụ
      order: 6,
    },
  ];

  for (const def of defs) {
    const existing = await repo.findOne({ where: { code: def.code! } });
    if (existing) {
      console.log(`⚠️  Achievement "${def.code}" đã tồn tại, bỏ qua.`);
      continue;
    }
    const entity = repo.create(def as Achievement);
    await repo.save(entity);
    console.log(`✅ Đã tạo achievement "${def.name}" (${def.code})`);
  }

  await app.close();
  console.log('🎉 Seed achievements hoàn tất!');
}

seedAchievements().catch((err) => {
  console.error('❌ Lỗi seed achievements:', err);
  process.exit(1);
});

