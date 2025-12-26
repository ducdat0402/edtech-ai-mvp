/**
 * Ví dụ: Seed Learning Nodes cho Subject "Python"
 * 
 * CÁCH SỬ DỤNG:
 * 1. Đảm bảo Subject "Python" đã tồn tại trong database
 * 2. Chạy: npx ts-node src/seed/seed-python-nodes-example.ts
 * 
 * HOẶC sử dụng method seedLearningNodesForSubject trong SeedService
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { SeedModule } from './seed.module';
import { SeedService } from './seed.service';

async function seedPythonNodes() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const seedService = app.select(SeedModule).get(SeedService);
  
  console.log('🌱 Starting Python Learning Nodes seed...');

  // 1. Tìm Subject "Python" (hoặc subject khác - sửa tên ở đây)
  const subjectName = 'Python'; // ⚠️ SỬA TÊN SUBJECT Ở ĐÂY
  
  const subjectRepo = (seedService as any).subjectRepository;
  const pythonSubject = await subjectRepo.findOne({
    where: { name: subjectName },
  });
  
  if (!pythonSubject) {
    console.error(`❌ Subject "${subjectName}" not found!`);
    console.log('\n💡 Vui lòng:');
    console.log('   1. Tạo Subject trước, HOẶC');
    console.log('   2. Sửa tên subject trong script này (dòng: const subjectName = ...)');
    console.log('\n📋 Danh sách subjects hiện có:');
    const allSubjects = await subjectRepo.find();
    allSubjects.forEach(s => console.log(`   - ${s.name} (${s.id})`));
    await app.close();
    return;
  }
  
  console.log(`✅ Found Subject: ${pythonSubject.name} (ID: ${pythonSubject.id})`);

  // 2. Định nghĩa các Learning Nodes
  const nodesData = [
    {
      title: 'Python Cơ Bản',
      description: 'Giới thiệu về Python và cài đặt môi trường',
      order: 1,
      icon: '🐍',
      concepts: [
        { title: 'Python là gì?', content: 'Python là ngôn ngữ lập trình thông dịch, đa mục đích, được thiết kế để dễ đọc và dễ học.' },
        { title: 'Cài đặt Python', content: 'Hướng dẫn cài đặt Python trên Windows, Mac và Linux.' },
        { title: 'Python Interpreter', content: 'Tìm hiểu về Python Interpreter và cách chạy code Python.' },
        { title: 'IDE và Editor', content: 'Giới thiệu các IDE phổ biến: VS Code, PyCharm, Jupyter Notebook.' },
      ],
    },
    {
      title: 'Biến và Kiểu Dữ Liệu',
      description: 'Học về biến, kiểu dữ liệu cơ bản trong Python',
      order: 2,
      icon: '📊',
      concepts: [
        { title: 'Biến trong Python', content: 'Cách khai báo và sử dụng biến trong Python.' },
        { title: 'Kiểu dữ liệu số', content: 'int, float, complex - các kiểu số trong Python.' },
        { title: 'Kiểu dữ liệu chuỗi', content: 'str - làm việc với chuỗi ký tự.' },
        { title: 'Kiểu dữ liệu boolean', content: 'bool - True và False.' },
      ],
    },
    {
      title: 'Toán Tử và Biểu Thức',
      description: 'Học về các toán tử và cách viết biểu thức',
      order: 3,
      icon: '➕',
      concepts: [
        { title: 'Toán tử số học', content: '+, -, *, /, %, **, //' },
        { title: 'Toán tử so sánh', content: '==, !=, <, >, <=, >=' },
        { title: 'Toán tử logic', content: 'and, or, not' },
        { title: 'Toán tử gán', content: '=, +=, -=, *=, /=' },
      ],
    },
    {
      title: 'Cấu Trúc Điều Khiển',
      description: 'Học về if/else, vòng lặp',
      order: 4,
      icon: '🔄',
      concepts: [
        { title: 'Câu lệnh if/else', content: 'Cấu trúc điều kiện trong Python.' },
        { title: 'Vòng lặp for', content: 'Sử dụng for để lặp qua các phần tử.' },
        { title: 'Vòng lặp while', content: 'Sử dụng while để lặp với điều kiện.' },
        { title: 'break và continue', content: 'Điều khiển luồng trong vòng lặp.' },
      ],
    },
    {
      title: 'Danh Sách và Từ Điển',
      description: 'Học về list, tuple, dict',
      order: 5,
      icon: '📋',
      concepts: [
        { title: 'List (Danh sách)', content: 'Tạo và thao tác với list.' },
        { title: 'Tuple', content: 'Tuple - danh sách không thể thay đổi.' },
        { title: 'Dictionary (Từ điển)', content: 'Lưu trữ dữ liệu dạng key-value.' },
        { title: 'Set', content: 'Set - tập hợp các phần tử duy nhất.' },
      ],
    },
    {
      title: 'Hàm (Functions)',
      description: 'Học cách tạo và sử dụng hàm',
      order: 6,
      icon: '⚙️',
      concepts: [
        { title: 'Định nghĩa hàm', content: 'Cách tạo hàm với def.' },
        { title: 'Tham số và đối số', content: 'Truyền tham số vào hàm.' },
        { title: 'Giá trị trả về', content: 'return statement và giá trị trả về.' },
        { title: 'Lambda functions', content: 'Hàm ẩn danh với lambda.' },
      ],
    },
    {
      title: 'Xử Lý File',
      description: 'Đọc và ghi file trong Python',
      order: 7,
      icon: '📁',
      concepts: [
        { title: 'Mở và đóng file', content: 'open() và close() - làm việc với file.' },
        { title: 'Đọc file', content: 'read(), readline(), readlines().' },
        { title: 'Ghi file', content: 'write() và writelines().' },
        { title: 'Xử lý lỗi file', content: 'try/except khi làm việc với file.' },
      ],
    },
    {
      title: 'Xử Lý Ngoại Lệ',
      description: 'Try/except và xử lý lỗi',
      order: 8,
      icon: '⚠️',
      concepts: [
        { title: 'Try/Except', content: 'Bắt và xử lý ngoại lệ.' },
        { title: 'Finally', content: 'Khối finally luôn được thực thi.' },
        { title: 'Raise Exception', content: 'Ném ngoại lệ tùy chỉnh.' },
        { title: 'Custom Exceptions', content: 'Tạo exception class riêng.' },
      ],
    },
    {
      title: 'Lập Trình Hướng Đối Tượng',
      description: 'Class, Object, Inheritance',
      order: 9,
      icon: '🏗️',
      concepts: [
        { title: 'Class và Object', content: 'Tạo class và khởi tạo object.' },
        { title: 'Constructor', content: '__init__ method.' },
        { title: 'Inheritance', content: 'Kế thừa trong Python.' },
        { title: 'Polymorphism', content: 'Đa hình trong Python.' },
      ],
    },
    {
      title: 'Modules và Packages',
      description: 'Import và sử dụng thư viện',
      order: 10,
      icon: '📦',
      concepts: [
        { title: 'Import modules', content: 'Cách import và sử dụng module.' },
        { title: 'Standard Library', content: 'Thư viện chuẩn của Python.' },
        { title: 'Third-party packages', content: 'Cài đặt và sử dụng pip.' },
        { title: 'Tạo package riêng', content: 'Tổ chức code thành package.' },
      ],
    },
  ];

  // 3. Gọi method seedLearningNodesForSubject
  await seedService.seedLearningNodesForSubject(pythonSubject.id, nodesData);

  console.log(`\n✅ Successfully seeded ${nodesData.length} Python Learning Nodes!`);
  console.log(`📚 Subject ID: ${pythonSubject.id}`);
  console.log(`\n💡 Bây giờ bạn có thể tạo roadmap cho subject này!`);
  
  await app.close();
}

seedPythonNodes().catch((error) => {
  console.error('❌ Error seeding Python nodes:', error);
  process.exit(1);
});
