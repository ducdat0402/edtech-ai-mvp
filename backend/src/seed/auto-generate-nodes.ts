/**
 * Script tự động tạo Learning Nodes bằng AI
 * 
 * CÁCH SỬ DỤNG:
 * 1. Sửa tên subject ở dòng 20
 * 2. (Tùy chọn) Sửa số lượng nodes ở dòng 30
 * 3. Chạy: npx ts-node src/seed/auto-generate-nodes.ts
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { SeedModule } from './seed.module';
import { SeedService } from './seed.service';
import { LearningNodesModule } from '../learning-nodes/learning-nodes.module';
import { LearningNodesService } from '../learning-nodes/learning-nodes.service';

async function autoGenerateNodes() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const seedService = app.select(SeedModule).get(SeedService);
  const nodesService = app.select(LearningNodesModule).get(LearningNodesService);
  
  // ⚠️ SỬA TÊN SUBJECT Ở ĐÂY
  const subjectName = 'Python';
  const numberOfNodes = 10; // Số lượng nodes muốn tạo
  
  console.log(`🌱 Bắt đầu tự động tạo Learning Nodes cho "${subjectName}"...`);
  
  // 1. Tìm subject
  const subjectRepo = (seedService as any).subjectRepository;
  const subject = await subjectRepo.findOne({ 
    where: { name: subjectName } 
  });
  
  if (!subject) {
    console.error(`❌ Subject "${subjectName}" not found!`);
    console.log('\n💡 Danh sách subjects hiện có:');
    const allSubjects = await subjectRepo.find();
    allSubjects.forEach(s => console.log(`   - ${s.name} (${s.id})`));
    console.log('\n💡 Vui lòng:');
    console.log('   1. Tạo Subject trước, HOẶC');
    console.log('   2. Sửa tên subject trong script này');
    await app.close();
    return;
  }
  
  console.log(`✅ Found Subject: ${subject.name} (ID: ${subject.id})`);
  
  // 2. Kiểm tra nodes đã có
  const existingNodes = await nodesService.findBySubject(subject.id);
  if (existingNodes.length > 0) {
    console.log(`⚠️  Subject đã có ${existingNodes.length} Learning Nodes!`);
    console.log('💡 Bạn có muốn tạo thêm không? (Script sẽ tiếp tục...)');
  }
  
  // 3. AI tự động tạo nodes
  console.log(`\n🤖 AI đang tạo ${numberOfNodes} Learning Nodes...`);
  console.log('⏳ Vui lòng đợi (có thể mất 10-30 giây)...\n');
  
  try {
    const nodes = await nodesService.generateNodesFromRawData(
      subject.id,
      subject.name,
      subject.description,
      undefined, // topics (có thể thêm nếu có)
      numberOfNodes,
    );
    
    console.log(`\n✅ Hoàn thành! Đã tạo ${nodes.length} Learning Nodes:`);
    nodes.forEach((node, index) => {
      console.log(`   ${index + 1}. ${node.title} (${node.contentStructure.concepts} concepts)`);
    });
    
    console.log(`\n💡 Bây giờ bạn có thể:`);
    console.log(`   1. Tạo roadmap cho subject này`);
    console.log(`   2. Xem nodes qua API: GET /api/v1/nodes/subject/${subject.id}`);
    console.log(`   3. Chỉnh sửa nodes nếu cần`);
    
  } catch (error) {
    console.error('❌ Lỗi khi tạo nodes:', error.message);
    if (error.message.includes('OpenAI API')) {
      console.log('\n💡 Vui lòng kiểm tra:');
      console.log('   1. OPENAI_API_KEY đã được set trong .env');
      console.log('   2. API key còn hiệu lực');
      console.log('   3. Đã restart server sau khi thêm key');
    }
  }
  
  await app.close();
}

autoGenerateNodes().catch((error) => {
  console.error('❌ Error:', error);
  process.exit(1);
});

