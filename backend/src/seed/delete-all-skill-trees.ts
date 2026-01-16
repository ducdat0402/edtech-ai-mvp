/**
 * Script xóa tất cả skill trees và skill nodes hiện tại
 * 
 * CÁCH SỬ DỤNG:
 * npx ts-node src/seed/delete-all-skill-trees.ts
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { DataSource, In } from 'typeorm';
import { SkillTree } from '../skill-tree/entities/skill-tree.entity';
import { SkillNode } from '../skill-tree/entities/skill-node.entity';
import { UserSkillProgress } from '../skill-tree/entities/user-skill-progress.entity';

async function deleteAllSkillTrees() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const dataSource = app.get(DataSource);
  
  const skillTreeRepo = dataSource.getRepository(SkillTree);
  const skillNodeRepo = dataSource.getRepository(SkillNode);
  const userSkillProgressRepo = dataSource.getRepository(UserSkillProgress);

  console.log('🗑️  Bắt đầu xóa tất cả skill trees...\n');

  try {
    // 1. Xóa user skill progress
    const allUserSkillProgress = await userSkillProgressRepo.find();
    if (allUserSkillProgress.length > 0) {
      await userSkillProgressRepo.remove(allUserSkillProgress);
      console.log(`✅ Đã xóa ${allUserSkillProgress.length} user skill progress records`);
    } else {
      console.log('   ⏭️  Không có user skill progress để xóa');
    }

    // 2. Xóa skill nodes
    const allSkillNodes = await skillNodeRepo.find();
    if (allSkillNodes.length > 0) {
      await skillNodeRepo.remove(allSkillNodes);
      console.log(`✅ Đã xóa ${allSkillNodes.length} skill nodes`);
    } else {
      console.log('   ⏭️  Không có skill nodes để xóa');
    }

    // 3. Xóa skill trees
    const allSkillTrees = await skillTreeRepo.find();
    if (allSkillTrees.length > 0) {
      await skillTreeRepo.remove(allSkillTrees);
      console.log(`✅ Đã xóa ${allSkillTrees.length} skill trees`);
    } else {
      console.log('   ⏭️  Không có skill trees để xóa');
    }

    console.log('\n✅ Hoàn thành xóa tất cả skill trees!');
    console.log('📝 Bây giờ bạn có thể tạo lại skill tree mới từ frontend hoặc API.');
    console.log('   - Refresh skill tree screen để tự động tạo lại');
    console.log('   - Hoặc gọi API POST /skill-tree/generate với subjectId');
  } catch (error) {
    console.error('❌ Lỗi khi xóa skill trees:', error);
    throw error;
  } finally {
    await app.close();
  }
}

deleteAllSkillTrees().catch(console.error);
