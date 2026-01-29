import { DataSource } from 'typeorm';
import { Domain } from '../domains/entities/domain.entity';
import { Subject } from '../subjects/entities/subject.entity';

/**
 * Seed domains for existing subjects
 * This script creates default domains/chapters for subjects
 */
export async function seedDomains(dataSource: DataSource) {
  const domainRepository = dataSource.getRepository(Domain);
  const subjectRepository = dataSource.getRepository(Subject);

  console.log('🌱 Seeding domains...');

  // Get all subjects
  const subjects = await subjectRepository.find();

  if (subjects.length === 0) {
    console.log('⚠️  No subjects found. Please seed subjects first.');
    return;
  }

  // Domain templates for different subject types
  const domainTemplates: Record<string, string[]> = {
    // Excel
    excel: [
      'Cơ bản về Excel',
      'Công thức và Hàm',
      'Định dạng và Trình bày',
      'Biểu đồ và Đồ thị',
      'Phân tích Dữ liệu',
      'Pivot Tables',
      'Macros và VBA',
    ],
    // Python
    python: [
      'Cơ bản Python',
      'Cấu trúc Dữ liệu',
      'Hàm và Modules',
      'Lập trình Hướng đối tượng',
      'Xử lý File và JSON',
      'Thư viện Numpy và Pandas',
      'Web Development với Flask',
    ],
    // Piano
    piano: [
      'Nhạc lý Cơ bản',
      'Kỹ thuật Ngón tay',
      'Hợp âm Cơ bản',
      'Đọc Sheet Music',
      'Các Bài hát Đơn giản',
      'Kỹ thuật Nâng cao',
      'Biểu diễn',
    ],
    // Default
    default: [
      'Cơ bản',
      'Trung cấp',
      'Nâng cao',
      'Thực hành',
      'Dự án',
    ],
  };

  let createdCount = 0;

  for (const subject of subjects) {
    const subjectName = subject.name.toLowerCase();
    
    // Determine domain template based on subject name
    let domains: string[] = domainTemplates.default;
    
    if (subjectName.includes('excel')) {
      domains = domainTemplates.excel;
    } else if (subjectName.includes('python')) {
      domains = domainTemplates.python;
    } else if (subjectName.includes('piano') || subjectName.includes('nhạc')) {
      domains = domainTemplates.piano;
    }

    // Check if domains already exist for this subject
    const existingDomains = await domainRepository.find({
      where: { subjectId: subject.id },
    });

    if (existingDomains.length > 0) {
      console.log(`⏭️  Subject "${subject.name}" already has ${existingDomains.length} domains. Skipping...`);
      continue;
    }

    // Create domains
    for (let i = 0; i < domains.length; i++) {
      const domain = domainRepository.create({
        subjectId: subject.id,
        name: domains[i],
        description: `Chương ${i + 1}: ${domains[i]}`,
        order: i,
        metadata: {
          icon: '📚',
          estimatedDays: Math.ceil(domains.length / 7) * 7, // Rough estimate
        },
      });

      await domainRepository.save(domain);
      createdCount++;
      console.log(`✅ Created domain: "${domains[i]}" for subject "${subject.name}"`);
    }
  }

  console.log(`\n✅ Successfully created ${createdCount} domains for ${subjects.length} subjects!`);
}

