# Hướng Dẫn Seed Learning Nodes Cho Subject

## Tổng Quan

Learning Nodes là các bài học/concept trong một subject. Để tạo roadmap cho một subject, bạn cần có ít nhất 1 Learning Node.

## ⚡ Cách Nhanh Nhất: Tự Động Bằng AI

**Bạn KHÔNG CẦN nhập thủ công!** Chỉ cần cung cấp tên subject, AI tự động tạo tất cả.

👉 **Xem hướng dẫn chi tiết**: [GUIDE_AUTO_GENERATE_LEARNING_NODES.md](./GUIDE_AUTO_GENERATE_LEARNING_NODES.md)

### Quick Start:

```bash
# Chạy script tự động
npx ts-node src/seed/auto-generate-nodes.ts
```

Hoặc qua API:
```bash
POST /api/v1/nodes/generate-from-raw
{
  "subjectId": "uuid",
  "subjectName": "Python",
  "numberOfNodes": 10
}
```

---

## Cách Thủ Công (Nếu Muốn Tự Kiểm Soát)

## Cấu Trúc Learning Node

### 1. Learning Node Entity

```typescript
{
  id: string (UUID, tự động generate)
  subjectId: string (ID của subject)
  title: string (Tên bài học, ví dụ: "Vệ Sĩ Mật Khẩu")
  description: string (Mô tả ngắn về bài học)
  order: number (Thứ tự hiển thị, bắt đầu từ 1)
  prerequisites: string[] (Mảng các node IDs cần hoàn thành trước, [] nếu là node đầu tiên)
  contentStructure: {
    concepts: number (Số lượng concept items)
    examples: number (Số lượng example items)
    hiddenRewards: number (Số lượng hidden reward items)
    bossQuiz: number (Số lượng boss quiz, thường là 1)
  }
  metadata: {
    icon?: string (Emoji hoặc icon, ví dụ: "🔑")
    position?: { x: number, y: number } (Vị trí trên bản đồ học tập)
  }
}
```

### 2. Content Items (Tùy chọn nhưng khuyến khích)

Mỗi Learning Node có thể có các Content Items:

- **Concepts**: Khái niệm cơ bản (4-10 items)
- **Examples**: Ví dụ thực tế (10-20 items)
- **Hidden Rewards**: Phần thưởng ẩn (5-10 items)
- **Boss Quiz**: Bài kiểm tra cuối (1 item)

## Các Bước Seed Learning Nodes

### Bước 1: Tìm Subject ID

```bash
# Chạy query trong database hoặc qua API
SELECT id, name FROM subjects WHERE name = 'Tên Subject';
```

Hoặc qua API:
```http
GET /api/v1/subjects/explorer
GET /api/v1/subjects/scholar
```

### Bước 2: Tạo Learning Node

#### Cách 1: Qua Script Seed (Khuyến nghị)

Tạo file mới: `backend/src/seed/seed-learning-nodes.ts`

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { SeedModule } from './seed.module';
import { SeedService } from './seed.service';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const seedService = app.select(SeedModule).get(SeedService);
  
  // Gọi method seed Learning Nodes cho subject
  await seedService.seedLearningNodesForSubject('subject-id-here');
  
  await app.close();
}

bootstrap();
```

#### Cách 2: Qua API (Nếu có endpoint)

```http
POST /api/v1/learning-nodes
Authorization: Bearer <token>
Content-Type: application/json

{
  "subjectId": "uuid-of-subject",
  "title": "Tên Bài Học",
  "description": "Mô tả bài học",
  "order": 1,
  "prerequisites": [],
  "contentStructure": {
    "concepts": 4,
    "examples": 10,
    "hiddenRewards": 5,
    "bossQuiz": 1
  },
  "metadata": {
    "icon": "🔑",
    "position": { "x": 0, "y": 0 }
  }
}
```

### Bước 3: Tạo Content Items (Tùy chọn)

Sau khi tạo Learning Node, bạn có thể thêm Content Items:

```typescript
// Concept Item
{
  nodeId: "learning-node-id",
  type: "concept",
  title: "Tên Concept",
  content: "Nội dung concept...",
  order: 1,
  rewards: { xp: 10, coin: 1 }
}

// Example Item
{
  nodeId: "learning-node-id",
  type: "example",
  title: "Tên Example",
  content: "Mô tả example...",
  media: {
    videoUrl: "https://example.com/video.mp4",
    // hoặc
    imageUrl: "https://example.com/image.jpg",
    // hoặc
    interactiveUrl: "https://example.com/tool"
  },
  order: 1,
  rewards: { xp: 15, coin: 2 }
}

// Hidden Reward Item
{
  nodeId: "learning-node-id",
  type: "hidden_reward",
  title: "Phần Thưởng Ẩn",
  content: "Bạn đã phát hiện rương coin!",
  order: 1,
  rewards: { xp: 5, coin: 5 }
}

// Boss Quiz Item
{
  nodeId: "learning-node-id",
  type: "boss_quiz",
  title: "Boss Quiz",
  content: "Bài kiểm tra cuối",
  order: 1,
  quizData: {
    question: "Câu hỏi?",
    options: ["A. Option 1", "B. Option 2", "C. Option 3", "D. Option 4"],
    correctAnswer: 0,
    explanation: "Giải thích đáp án"
  },
  rewards: { xp: 50, coin: 10 }
}
```

## Ví Dụ Hoàn Chỉnh: Seed Learning Nodes Cho Subject "Python"

### File: `backend/src/seed/seed-python-nodes.ts`

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { SeedModule } from './seed.module';
import { SeedService } from './seed.service';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const seedService = app.select(SeedModule).get(SeedService);
  
  // Tìm subject "Python" (giả sử đã có trong DB)
  const pythonSubject = await seedService.findSubjectByName('Python');
  
  if (!pythonSubject) {
    console.error('❌ Subject "Python" not found. Please create it first.');
    await app.close();
    return;
  }
  
  // Seed Learning Nodes cho Python
  await seedService.seedPythonNodes(pythonSubject.id);
  
  console.log('✅ Successfully seeded Python Learning Nodes!');
  await app.close();
}

bootstrap();
```

### Thêm Method vào SeedService

```typescript
// Trong backend/src/seed/seed.service.ts

async seedPythonNodes(subjectId: string) {
  console.log('🌱 Seeding Python Learning Nodes...');
  
  // Node 1: Python Basics
  const node1 = this.nodeRepository.create({
    subjectId,
    title: 'Python Cơ Bản',
    description: 'Học các khái niệm cơ bản về Python',
    order: 1,
    prerequisites: [],
    contentStructure: {
      concepts: 5,
      examples: 8,
      hiddenRewards: 3,
      bossQuiz: 1,
    },
    metadata: {
      icon: '🐍',
      position: { x: 0, y: 0 },
    },
  });
  const savedNode1 = await this.nodeRepository.save(node1);
  
  // Thêm Concepts cho Node 1
  const concepts = [
    {
      title: 'Python là gì?',
      content: 'Python là ngôn ngữ lập trình thông dịch, đa mục đích...',
      rewards: { xp: 10, coin: 1 },
    },
    {
      title: 'Cài đặt Python',
      content: 'Hướng dẫn cài đặt Python trên Windows/Mac/Linux...',
      rewards: { xp: 10, coin: 1 },
    },
    // ... thêm 3 concepts nữa
  ];
  
  for (let i = 0; i < concepts.length; i++) {
    const concept = this.contentItemRepository.create({
      nodeId: savedNode1.id,
      type: 'concept',
      title: concepts[i].title,
      content: concepts[i].content,
      order: i + 1,
      rewards: concepts[i].rewards,
    });
    await this.contentItemRepository.save(concept);
  }
  
  // Node 2: Variables & Data Types (phụ thuộc Node 1)
  const node2 = this.nodeRepository.create({
    subjectId,
    title: 'Biến và Kiểu Dữ Liệu',
    description: 'Học về biến, kiểu dữ liệu trong Python',
    order: 2,
    prerequisites: [savedNode1.id], // Cần hoàn thành Node 1 trước
    contentStructure: {
      concepts: 4,
      examples: 10,
      hiddenRewards: 5,
      bossQuiz: 1,
    },
    metadata: {
      icon: '📊',
      position: { x: 100, y: 0 },
    },
  });
  await this.nodeRepository.save(node2);
  
  // ... tiếp tục tạo các nodes khác
  
  console.log('✅ Python Learning Nodes seeded successfully!');
}
```

## Checklist Trước Khi Seed

- [ ] Subject đã tồn tại trong database
- [ ] Đã có Subject ID
- [ ] Đã chuẩn bị nội dung cho Learning Nodes:
  - [ ] Titles và descriptions
  - [ ] Thứ tự (order) cho các nodes
  - [ ] Prerequisites (nếu có)
  - [ ] Content items (concepts, examples, etc.)

## Chạy Script Seed

```bash
# Từ thư mục backend
npm run seed:python-nodes

# Hoặc nếu dùng ts-node
npx ts-node src/seed/seed-python-nodes.ts
```

## Kiểm Tra Kết Quả

```sql
-- Kiểm tra Learning Nodes đã được tạo
SELECT id, title, "order", prerequisites 
FROM learning_nodes 
WHERE "subjectId" = 'your-subject-id'
ORDER BY "order" ASC;

-- Kiểm tra Content Items
SELECT type, title, "order" 
FROM content_items 
WHERE "nodeId" = 'your-node-id'
ORDER BY "order" ASC;
```

## Lưu Ý Quan Trọng

1. **Order**: Đảm bảo `order` tăng dần (1, 2, 3, ...)
2. **Prerequisites**: Node đầu tiên nên có `prerequisites: []`
3. **Content Structure**: Số lượng trong `contentStructure` nên khớp với số Content Items thực tế
4. **Minimum Nodes**: Để tạo roadmap, cần ít nhất 1 Learning Node, nhưng khuyến nghị có ít nhất 5-10 nodes để roadmap phong phú

## Troubleshooting

### Lỗi: "Subject not found"
- Kiểm tra Subject ID có đúng không
- Đảm bảo Subject đã được seed trước

### Lỗi: "Foreign key constraint"
- Kiểm tra `subjectId` có tồn tại trong bảng `subjects`
- Kiểm tra `prerequisites` có chứa node IDs hợp lệ

### Roadmap không tạo được
- Đảm bảo Subject có ít nhất 1 Learning Node
- Kiểm tra bằng query: `SELECT COUNT(*) FROM learning_nodes WHERE subjectId = '...'`

## Ví Dụ Thực Tế: Tạo 10 Nodes Cho Python

Xem file `backend/src/seed/seed-python-nodes-example.ts` (sẽ được tạo) để xem ví dụ đầy đủ với 10 Learning Nodes cho Python.

