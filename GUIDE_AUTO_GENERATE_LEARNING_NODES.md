# 🤖 Hướng Dẫn Tự Động Tạo Learning Nodes Bằng AI

## Tổng Quan

Hệ thống hỗ trợ **tự động tạo Learning Nodes** từ dữ liệu thô bằng AI. Bạn **KHÔNG CẦN** nhập thủ công:
- ✅ Title, Description
- ✅ Order (thứ tự)
- ✅ Prerequisites (phụ thuộc)
- ✅ Content Items (Concepts, Examples)
- ✅ Icons

Chỉ cần cung cấp:
- Tên subject (ví dụ: "Python", "Piano", "Excel")
- Mô tả subject (tùy chọn)
- Danh sách topics/chapters (tùy chọn)

AI sẽ tự động tạo toàn bộ cấu trúc!

## 3 Cách Tạo Learning Nodes

### Cách 1: Tự Động Hoàn Toàn (Khuyến Nghị) ⭐

**Chỉ cần tên subject**, AI tự động tạo tất cả:

```bash
POST /api/v1/nodes/generate-from-raw
Authorization: Bearer <token>
Content-Type: application/json

{
  "subjectId": "uuid-of-subject",
  "subjectName": "Python",
  "numberOfNodes": 10
}
```

**Kết quả**: AI tự động tạo 10 Learning Nodes với:
- Titles phù hợp
- Descriptions
- Order (1-10)
- Prerequisites (tự động: node sau phụ thuộc node trước)
- Concepts (3-5 concepts mỗi node)
- Examples (2-3 examples mỗi node)
- Icons phù hợp

### Cách 2: Với Mô Tả Subject

```json
{
  "subjectId": "uuid-of-subject",
  "subjectName": "Piano",
  "subjectDescription": "Học chơi đàn piano từ cơ bản đến nâng cao, bao gồm nhạc lý, kỹ thuật ngón tay, và chơi các bài hát",
  "numberOfNodes": 12
}
```

### Cách 3: Với Danh Sách Topics/Chapters

Nếu bạn đã có danh sách chương/topic, AI sẽ sử dụng để tạo nodes chính xác hơn:

```json
{
  "subjectId": "uuid-of-subject",
  "subjectName": "Excel",
  "subjectDescription": "Học Microsoft Excel từ cơ bản",
  "topicsOrChapters": [
    "Giới thiệu Excel và giao diện",
    "Nhập dữ liệu và định dạng",
    "Công thức và hàm cơ bản",
    "Biểu đồ và đồ thị",
    "Pivot Table",
    "VLOOKUP và HLOOKUP",
    "Macro và VBA cơ bản"
  ],
  "numberOfNodes": 7
}
```

## Ví Dụ Thực Tế

### Ví Dụ 1: Tạo Nodes Cho "Python"

```bash
curl -X POST http://localhost:3000/api/v1/nodes/generate-from-raw \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "subjectId": "abc-123-def",
    "subjectName": "Python",
    "numberOfNodes": 10
  }'
```

**Kết quả**: AI tự động tạo:
1. Python Cơ Bản
2. Biến và Kiểu Dữ Liệu
3. Toán Tử và Biểu Thức
4. Cấu Trúc Điều Khiển
5. Danh Sách và Từ Điển
6. Hàm (Functions)
7. Xử Lý File
8. Xử Lý Ngoại Lệ
9. Lập Trình Hướng Đối Tượng
10. Modules và Packages

### Ví Dụ 2: Tạo Nodes Cho "Piano"

```json
{
  "subjectId": "piano-subject-id",
  "subjectName": "Piano",
  "subjectDescription": "Học chơi đàn piano",
  "numberOfNodes": 8
}
```

**Kết quả**: AI tự động tạo:
1. Giới Thiệu Piano
2. Nhạc Lý Cơ Bản
3. Tư Thế và Kỹ Thuật Ngón Tay
4. Đọc Bản Nhạc
5. Chơi Gam và Hợp Âm
6. Luyện Tập Bài Hát Đơn Giản
7. Kỹ Thuật Nâng Cao
8. Biểu Diễn

### Ví Dụ 3: Với Topics Có Sẵn

```json
{
  "subjectId": "excel-subject-id",
  "subjectName": "Microsoft Excel",
  "topicsOrChapters": [
    "Giới thiệu Excel",
    "Nhập dữ liệu",
    "Công thức SUM, AVERAGE",
    "VLOOKUP",
    "Pivot Table",
    "Biểu đồ"
  ],
  "numberOfNodes": 6
}
```

AI sẽ tạo 6 nodes dựa trên các topics này.

## So Sánh: Thủ Công vs Tự Động

### ❌ Cách Cũ: Nhập Thủ Công

```typescript
// Phải tự viết tất cả
const nodesData = [
  {
    title: "Python Cơ Bản", // ← Phải tự nghĩ
    description: "Giới thiệu...", // ← Phải tự viết
    order: 1, // ← Phải tự đếm
    prerequisites: [], // ← Phải tự quản lý
    icon: "🐍", // ← Phải tự chọn
    concepts: [ // ← Phải tự viết từng concept
      { title: "...", content: "..." },
      ...
    ],
  },
  // ... phải viết 10 nodes như vậy
];
```

### ✅ Cách Mới: AI Tự Động

```json
{
  "subjectName": "Python",
  "numberOfNodes": 10
}
```

**Xong!** AI tự động tạo tất cả.

## API Response

```json
{
  "id": "node-uuid-1",
  "subjectId": "subject-uuid",
  "title": "Python Cơ Bản",
  "description": "Giới thiệu về Python và cài đặt môi trường",
  "order": 1,
  "prerequisites": [],
  "contentStructure": {
    "concepts": 4,
    "examples": 2,
    "hiddenRewards": 3,
    "bossQuiz": 1
  },
  "metadata": {
    "icon": "🐍",
    "position": { "x": 0, "y": 0 }
  },
  "contentItems": [
    {
      "type": "concept",
      "title": "Python là gì?",
      "content": "Python là ngôn ngữ lập trình..."
    },
    ...
  ]
}
```

## Workflow Đề Xuất

### Bước 1: Tạo Subject (nếu chưa có)

```bash
# Qua API hoặc database
POST /api/v1/subjects
{
  "name": "Python",
  "description": "Học lập trình Python",
  "track": "explorer"
}
```

### Bước 2: AI Tự Động Tạo Learning Nodes

```bash
POST /api/v1/nodes/generate-from-raw
{
  "subjectId": "subject-id-from-step-1",
  "subjectName": "Python",
  "numberOfNodes": 10
}
```

### Bước 3: Kiểm Tra và Chỉnh Sửa (Tùy chọn)

- Xem lại nodes đã tạo
- Chỉnh sửa nếu cần (title, description, etc.)
- Thêm/bớt content items nếu cần

### Bước 4: Tạo Roadmap

Sau khi có Learning Nodes, bạn có thể tạo roadmap:

```bash
POST /api/v1/roadmap/generate
{
  "subjectId": "subject-id"
}
```

## Tùy Chỉnh Nâng Cao

### Thêm Content Items Sau Khi Tạo Nodes

Nếu muốn thêm concepts/examples cho một node đã có:

```bash
POST /api/v1/content/node/:nodeId/import-concepts
{
  "rawText": "Nội dung thô về topic này...",
  "topic": "Python Functions",
  "count": 5
}
```

### Chỉnh Sửa Nodes Đã Tạo

Có thể chỉnh sửa qua API hoặc database:
- Sửa title, description
- Thay đổi order
- Cập nhật prerequisites
- Thêm/bớt content items

## Lưu Ý Quan Trọng

1. **API Key**: Cần có `OPENAI_API_KEY` trong `.env`
2. **Chi phí**: Mỗi lần generate tốn ~$0.01-0.05 (tùy số lượng nodes)
3. **Thời gian**: ~10-30 giây cho 10 nodes
4. **Chất lượng**: AI tạo nodes chất lượng tốt, nhưng nên review và chỉnh sửa nếu cần

## Troubleshooting

### Lỗi: "OpenAI API not configured"
- Kiểm tra `OPENAI_API_KEY` trong `.env`
- Restart server sau khi thêm key

### Lỗi: "Subject not found"
- Đảm bảo `subjectId` đúng
- Kiểm tra subject đã tồn tại trong database

### Nodes không đúng như mong muốn
- Thử thêm `subjectDescription` chi tiết hơn
- Cung cấp `topicsOrChapters` để AI hiểu rõ hơn
- Có thể chỉnh sửa sau khi tạo

## Ví Dụ Script Tự Động

Tạo file `backend/src/seed/auto-generate-nodes.ts`:

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { SeedModule } from './seed.module';
import { SeedService } from './seed.service';
import { LearningNodesService } from '../learning-nodes/learning-nodes.service';

async function autoGenerateNodes() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const seedService = app.select(SeedModule).get(SeedService);
  const nodesService = app.get(LearningNodesService);
  
  // 1. Tìm subject
  const subjectName = 'Python'; // ⚠️ SỬA TÊN Ở ĐÂY
  const subjectRepo = (seedService as any).subjectRepository;
  const subject = await subjectRepo.findOne({ where: { name: subjectName } });
  
  if (!subject) {
    console.error(`❌ Subject "${subjectName}" not found!`);
    await app.close();
    return;
  }
  
  // 2. AI tự động tạo nodes
  console.log(`🤖 AI đang tạo Learning Nodes cho "${subjectName}"...`);
  const nodes = await nodesService.generateNodesFromRawData(
    subject.id,
    subject.name,
    subject.description,
    undefined, // topics (có thể thêm nếu có)
    10, // số lượng nodes
  );
  
  console.log(`✅ Đã tạo ${nodes.length} Learning Nodes!`);
  console.log(`💡 Bây giờ có thể tạo roadmap cho subject này!`);
  
  await app.close();
}

autoGenerateNodes();
```

Chạy:
```bash
npx ts-node src/seed/auto-generate-nodes.ts
```

## Kết Luận

**Bạn KHÔNG CẦN nhập thủ công!** Chỉ cần:
1. Có Subject trong database
2. Gọi API với `subjectName` và `numberOfNodes`
3. AI tự động tạo tất cả!

Sau đó có thể review và chỉnh sửa nếu cần.


