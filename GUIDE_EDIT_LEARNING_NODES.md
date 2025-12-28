# ✏️ Hướng Dẫn Chỉnh Sửa Learning Nodes

## Tổng Quan

Sau khi AI tự động tạo Learning Nodes, bạn có thể chỉnh sửa nếu:
- Nội dung không phù hợp
- Thiếu thông tin
- Cần thêm/bớt content items
- Cần sửa title, description, order

## API Endpoints Để Chỉnh Sửa

### 1. Cập Nhật Learning Node

**Endpoint:** `PUT /api/v1/nodes/:id`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Body:**
```json
{
  "title": "Tên mới",
  "description": "Mô tả mới",
  "order": 2,
  "prerequisites": ["node-id-1"],
  "metadata": {
    "icon": "🎯",
    "position": { "x": 100, "y": 0 }
  }
}
```

**Ví dụ:**
```bash
curl -X PUT http://localhost:3000/api/v1/nodes/node-uuid \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Python Nâng Cao",
    "description": "Học các kỹ thuật nâng cao trong Python"
  }'
```

### 2. Cập Nhật Content Item

**Endpoint:** `PUT /api/v1/content/:id`

**Body:**
```json
{
  "title": "Tên concept/example mới",
  "content": "Nội dung mới...",
  "order": 1,
  "rewards": {
    "xp": 15,
    "coin": 2
  },
  "quizData": {
    "question": "Câu hỏi mới?",
    "options": ["A. ...", "B. ...", "C. ...", "D. ..."],
    "correctAnswer": 0,
    "explanation": "Giải thích..."
  }
}
```

**Ví dụ:**
```bash
curl -X PUT http://localhost:3000/api/v1/content/content-uuid \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Khái niệm mới",
    "content": "Nội dung chi tiết hơn..."
  }'
```

### 3. Xóa Content Item

**Endpoint:** `DELETE /api/v1/content/:id`

```bash
curl -X DELETE http://localhost:3000/api/v1/content/content-uuid \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 4. Thêm Content Item Mới

**Endpoint:** `POST /api/v1/content`

**Body:**
```json
{
  "nodeId": "node-uuid",
  "type": "concept",
  "title": "Khái niệm mới",
  "content": "Nội dung...",
  "order": 5,
  "rewards": {
    "xp": 10,
    "coin": 1
  }
}
```

## Workflow Chỉnh Sửa

### Bước 1: Xem Node Hiện Tại

```bash
GET /api/v1/nodes/:id
```

Response sẽ bao gồm tất cả content items.

### Bước 2: Chỉnh Sửa

- Sửa title/description của node
- Sửa content items
- Thêm/bớt content items
- Sửa boss quiz

### Bước 3: Cập Nhật Content Structure

Sau khi thêm/bớt content items, cần cập nhật `contentStructure` trong node:

```json
{
  "contentStructure": {
    "concepts": 5,
    "examples": 8,
    "hiddenRewards": 3,
    "bossQuiz": 1
  }
}
```

## Ví Dụ Thực Tế

### Ví Dụ 1: Sửa Title và Description

```bash
PUT /api/v1/nodes/node-123
{
  "title": "Python Functions Nâng Cao",
  "description": "Học về decorators, generators, và lambda functions"
}
```

### Ví Dụ 2: Thêm Concept Mới

```bash
POST /api/v1/content
{
  "nodeId": "node-123",
  "type": "concept",
  "title": "Decorators trong Python",
  "content": "Decorators là một tính năng mạnh mẽ...",
  "order": 6,
  "rewards": { "xp": 10, "coin": 1 }
}
```

Sau đó cập nhật contentStructure:
```bash
PUT /api/v1/nodes/node-123
{
  "contentStructure": {
    "concepts": 6,  // Tăng từ 5 lên 6
    "examples": 8,
    "hiddenRewards": 3,
    "bossQuiz": 1
  }
}
```

### Ví Dụ 3: Sửa Boss Quiz

```bash
PUT /api/v1/content/quiz-uuid
{
  "quizData": {
    "question": "Câu hỏi mới, chính xác hơn?",
    "options": [
      "A. Đáp án đúng",
      "B. Đáp án sai 1",
      "C. Đáp án sai 2",
      "D. Đáp án sai 3"
    ],
    "correctAnswer": 0,
    "explanation": "Giải thích chi tiết tại sao A đúng..."
  }
}
```

## Lưu Ý

1. **Content Structure**: Nhớ cập nhật `contentStructure` sau khi thêm/bớt items
2. **Order**: Đảm bảo `order` tăng dần và không trùng lặp
3. **Prerequisites**: Khi sửa prerequisites, đảm bảo node IDs hợp lệ
4. **Boss Quiz**: Chỉ có 1 boss quiz per node, nên update thay vì tạo mới

## Tính Năng Tương Lai

Sẽ có thêm:
- UI để chỉnh sửa trực tiếp trên web/mobile
- Preview trước khi lưu
- Version history (lịch sử chỉnh sửa)
- Rollback về phiên bản cũ


