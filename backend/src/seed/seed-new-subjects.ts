/**
 * Script tạo 4 môn học mới: Bóng rổ, Tin học văn phòng, Skincare, Tài chính cá nhân
 * 
 * CÁCH SỬ DỤNG:
 * npx ts-node src/seed/seed-new-subjects.ts
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { SeedModule } from './seed.module';
import { SeedService } from './seed.service';
import { SubjectsService } from '../subjects/subjects.service';
import { SubjectsModule } from '../subjects/subjects.module';
// Lưu ý: phiên bản rút gọn, chỉ tạo subjects, KHÔNG tạo Knowledge Graph

async function seedNewSubjects() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const seedService = app.select(SeedModule).get(SeedService);
  const subjectsService = app.select(SubjectsModule).get(SubjectsService);

  const subjectRepo = (seedService as any).subjectRepository;

  console.log('🌱 Bắt đầu tạo 4 môn học mới...\n');

  const newSubjects = [
    {
      name: 'Bóng rổ',
      description:
        'Học chơi bóng rổ từ cơ bản đến nâng cao, bao gồm kỹ thuật, chiến thuật và thể lực',
      track: 'explorer' as const,
      icon: '🏀',
      color: '#FF6B35',
    },
    {
      name: 'Tin học văn phòng',
      description:
        'Thành thạo Microsoft Office: Word, Excel, PowerPoint và các kỹ năng văn phòng cần thiết',
      track: 'explorer' as const,
      icon: '💻',
      color: '#4A90E2',
    },
    {
      name: 'Skincare',
      description:
        'Chăm sóc da đúng cách: hiểu về da, sản phẩm phù hợp và quy trình skincare hiệu quả',
      track: 'explorer' as const,
      icon: '✨',
      color: '#FFB6C1',
    },
    {
      name: 'Tài chính cá nhân',
      description:
        'Quản lý tài chính cá nhân: ngân sách, tiết kiệm, đầu tư và lập kế hoạch tài chính',
      track: 'explorer' as const,
      icon: '💰',
      color: '#FFD700',
    },
    // ─── Các môn mới bạn yêu cầu ───
    {
      name: 'Lập trình hướng đối tượng',
      description:
        'Hiểu và áp dụng các khái niệm OOP: class, object, inheritance, polymorphism, encapsulation.',
      track: 'explorer' as const,
      icon: '🧱',
      color: '#8B5CF6',
    },
    {
      name: 'Quản trị học (Principles of Management)',
      description:
        'Các nguyên lý cơ bản của quản trị: hoạch định, tổ chức, lãnh đạo và kiểm soát trong doanh nghiệp.',
      track: 'explorer' as const,
      icon: '📊',
      color: '#10B981',
    },
    {
      name: 'Digital Marketing',
      description:
        'Marketing số: SEO, social media, content marketing, email, paid ads và đo lường hiệu quả.',
      track: 'explorer' as const,
      icon: '📣',
      color: '#F97316',
    },
    {
      name: 'Nguyên lý kế toán',
      description:
        'Các khái niệm và nguyên tắc cơ bản trong kế toán tài chính: tài sản, nợ phải trả, vốn chủ sở hữu.',
      track: 'explorer' as const,
      icon: '📚',
      color: '#06B6D4',
    },
    {
      name: 'Phân tích tài chính doanh nghiệp',
      description:
        'Đọc và phân tích báo cáo tài chính, tỷ số tài chính, dòng tiền và đánh giá sức khỏe doanh nghiệp.',
      track: 'explorer' as const,
      icon: '💼',
      color: '#0EA5E9',
    },
    {
      name: 'Biên phiên dịch (Translation and Interpreting)',
      description:
        'Kỹ năng dịch viết và dịch nói, xử lý ngữ cảnh, thuật ngữ chuyên ngành và phong cách ngôn ngữ.',
      track: 'explorer' as const,
      icon: '🗣️',
      color: '#EC4899',
    },
    {
      name: 'Quản trị chuỗi cung ứng (Supply Chain Management)',
      description:
        'Quản lý dòng chảy hàng hóa, thông tin và tài chính từ nhà cung cấp tới khách hàng cuối cùng.',
      track: 'explorer' as const,
      icon: '🚚',
      color: '#22C55E',
    },
    {
      name: 'Giải phẫu học (Human Anatomy)',
      description:
        'Cấu trúc và chức năng của cơ thể người: hệ xương, cơ, tuần hoàn, hô hấp và thần kinh.',
      track: 'explorer' as const,
      icon: '🧠',
      color: '#EF4444',
    },
    {
      name: 'Cơ học kỹ thuật',
      description:
        'Các khái niệm về lực, mô men, cân bằng, ứng suất và biến dạng trong cơ học kỹ thuật.',
      track: 'explorer' as const,
      icon: '⚙️',
      color: '#3B82F6',
    },
    {
      name: 'Luật dân sự',
      description:
        'Những nguyên tắc cơ bản của luật dân sự: quyền sở hữu, hợp đồng, bồi thường thiệt hại và thừa kế.',
      track: 'explorer' as const,
      icon: '⚖️',
      color: '#6366F1',
    },
  ];

  for (const subjectData of newSubjects) {
    try {
      // Check if subject already exists
      const existing = await subjectRepo.findOne({
        where: { name: subjectData.name },
      });

      if (existing) {
        console.log(`⏭️  Subject "${subjectData.name}" đã tồn tại. Bỏ qua...`);
        continue;
      }

      // Create subject
      const subject = await subjectsService.createIfNotExists(
        subjectData.name,
        subjectData.description,
        subjectData.track,
      );

      // Update metadata
      subject.metadata = {
        icon: subjectData.icon,
        color: subjectData.color,
        estimatedDays: 30,
      };
      subject.unlockConditions = {
        minCoin: 0,
      };
      await (seedService as any).subjectRepository.save(subject);

      console.log(`✅ Đã tạo subject: ${subjectData.name} (ID: ${subject.id})`);
    } catch (error) {
      console.error(`❌ Lỗi khi tạo subject "${subjectData.name}":`, error.message);
    }
  }

  console.log('✅ Hoàn thành tạo subjects!');
  await app.close();
}

seedNewSubjects().catch(console.error);

