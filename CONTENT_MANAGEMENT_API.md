# 📚 Content Management API - Complete Guide

## Tổng Quan

Hệ thống Content Management API hỗ trợ đầy đủ các tính năng:
- ✅ Import raw data (text/files) thành concepts/questions
- ✅ AI generate content tự động
- ✅ File upload (PDF, DOCX, TXT)
- ✅ Preview content trước khi generate
- ✅ Update/Edit generated content
- ✅ Delete content
- ✅ Reorder content items

## API Endpoints

### 1. Preview Endpoints

#### Preview File
**Endpoint:** `POST /api/v1/content/preview-file`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Body (Form Data):**
- `file`: File (PDF, DOCX, TXT)

**Response:**
```json
{
  "filename": "document.pdf",
  "size": 1024000,
  "mimetype": "application/pdf",
  "parsedText": "Full parsed text...",
  "textLength": 5000,
  "estimatedConcepts": 5,
  "preview": "First 500 characters..."
}
```

**Ví dụ:**
```bash
curl -X POST http://localhost:3000/api/v1/content/preview-file \
  -H "Authorization: Bearer TOKEN" \
  -F "file=@document.pdf"
```

#### Preview Text
**Endpoint:** `POST /api/v1/content/preview-text`

**Body:**
```json
{
  "rawText": "Your raw text here...",
  "topic": "Excel Basics"
}
```

**Response:**
```json
{
  "textLength": 5000,
  "estimatedConcepts": 5,
  "preview": "First 500 characters...",
  "topic": "Excel Basics"
}
```

### 2. Import Endpoints

#### Import Concepts từ Raw Text
**Endpoint:** `POST /api/v1/content/node/:nodeId/import-concepts`

**Body:**
```json
{
  "rawText": "Your raw text...",
  "topic": "Excel Basics",
  "count": 5
}
```

#### Import Concepts từ File
**Endpoint:** `POST /api/v1/content/node/:nodeId/import-file`

**Body (Form Data):**
- `file`: File (PDF, DOCX, TXT)
- `topic`: Chủ đề
- `count`: Số lượng concepts (optional, default: 5)

#### Generate Single Concept từ Raw Text
**Endpoint:** `POST /api/v1/content/node/:nodeId/generate-concept`

**Body:**
```json
{
  "rawText": "Your raw text...",
  "topic": "Excel Basics",
  "difficulty": "beginner"
}
```

#### Generate Single Concept từ File
**Endpoint:** `POST /api/v1/content/node/:nodeId/generate-concept-from-file`

**Body (Form Data):**
- `file`: File
- `topic`: Chủ đề
- `difficulty`: "beginner" | "intermediate" | "advanced"

#### Generate Examples từ Raw Text
**Endpoint:** `POST /api/v1/content/node/:nodeId/generate-examples`

**Body:**
```json
{
  "rawText": "Your raw text...",
  "topic": "Excel Basics",
  "count": 3
}
```

#### Generate Examples từ File
**Endpoint:** `POST /api/v1/content/node/:nodeId/generate-examples-from-file`

**Body (Form Data):**
- `file`: File
- `topic`: Chủ đề
- `count`: Số lượng examples (optional, default: 3)

### 3. CRUD Endpoints

#### Get Content by Node
**Endpoint:** `GET /api/v1/content/node/:nodeId`

**Response:**
```json
[
  {
    "id": "uuid",
    "nodeId": "node-uuid",
    "type": "concept",
    "title": "Title",
    "content": "Content...",
    "order": 1,
    "rewards": { "xp": 10, "coin": 1 }
  }
]
```

#### Get Content by ID
**Endpoint:** `GET /api/v1/content/:id`

**Response:**
```json
{
  "id": "uuid",
  "nodeId": "node-uuid",
  "type": "concept",
  "title": "Title",
  "content": "Content...",
  "order": 1,
  "rewards": { "xp": 10, "coin": 1 }
}
```

#### Update Content Item
**Endpoint:** `PUT /api/v1/content/:id`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Body:**
```json
{
  "title": "Updated title",
  "content": "Updated content...",
  "order": 2,
  "rewards": { "xp": 15, "coin": 2 },
  "media": {
    "videoUrl": "https://example.com/video.mp4"
  }
}
```

**Ví dụ:**
```bash
curl -X PUT http://localhost:3000/api/v1/content/CONTENT_ID \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Updated Title",
    "content": "Updated content..."
  }'
```

#### Delete Content Item
**Endpoint:** `DELETE /api/v1/content/:id`

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "message": "Content item deleted successfully"
}
```

**Ví dụ:**
```bash
curl -X DELETE http://localhost:3000/api/v1/content/CONTENT_ID \
  -H "Authorization: Bearer TOKEN"
```

#### Reorder Content Items
**Endpoint:** `POST /api/v1/content/node/:nodeId/reorder`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Body:**
```json
{
  "itemIds": ["id1", "id2", "id3", "id4"]
}
```

**Response:**
```json
[
  {
    "id": "id1",
    "order": 1
  },
  {
    "id": "id2",
    "order": 2
  },
  ...
]
```

**Ví dụ:**
```bash
curl -X POST http://localhost:3000/api/v1/content/node/NODE_ID/reorder \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "itemIds": ["id1", "id2", "id3"]
  }'
```

## Workflow Hoàn Chỉnh

### Workflow 1: Import từ File với Preview

```
1. Upload file → Preview
   POST /api/v1/content/preview-file
   ↓
2. Review parsed text
   ↓
3. Import concepts
   POST /api/v1/content/node/:nodeId/import-file
   ↓
4. Review generated concepts
   GET /api/v1/content/node/:nodeId
   ↓
5. Edit nếu cần
   PUT /api/v1/content/:id
   ↓
6. Reorder nếu cần
   POST /api/v1/content/node/:nodeId/reorder
```

### Workflow 2: Import từ Raw Text

```
1. Preview text
   POST /api/v1/content/preview-text
   ↓
2. Import concepts
   POST /api/v1/content/node/:nodeId/import-concepts
   ↓
3. Review & Edit
   GET /api/v1/content/node/:nodeId
   PUT /api/v1/content/:id
```

## Ví Dụ Thực Tế

### Ví Dụ 1: Import PDF và Edit

```bash
# 1. Preview file
curl -X POST http://localhost:3000/api/v1/content/preview-file \
  -H "Authorization: Bearer TOKEN" \
  -F "file=@tutorial.pdf"

# 2. Import concepts
curl -X POST http://localhost:3000/api/v1/content/node/NODE_ID/import-file \
  -H "Authorization: Bearer TOKEN" \
  -F "file=@tutorial.pdf" \
  -F "topic=Excel Basics" \
  -F "count=5"

# 3. Get generated concepts
curl http://localhost:3000/api/v1/content/node/NODE_ID \
  -H "Authorization: Bearer TOKEN"

# 4. Edit a concept
curl -X PUT http://localhost:3000/api/v1/content/CONTENT_ID \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Improved Title",
    "content": "Improved content with more details..."
  }'
```

### Ví Dụ 2: Generate và Reorder

```bash
# 1. Generate concepts
curl -X POST http://localhost:3000/api/v1/content/node/NODE_ID/import-concepts \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "rawText": "Excel basics...",
    "topic": "Excel",
    "count": 5
  }'

# 2. Reorder concepts
curl -X POST http://localhost:3000/api/v1/content/node/NODE_ID/reorder \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "itemIds": ["id3", "id1", "id5", "id2", "id4"]
  }'
```

## Best Practices

### 1. Preview Trước Khi Import
- ✅ Luôn preview file/text trước khi import
- ✅ Kiểm tra parsed text có đúng không
- ✅ Estimate số lượng concepts phù hợp

### 2. Review Sau Khi Generate
- ✅ Review tất cả generated concepts
- ✅ Edit nếu cần thiết
- ✅ Delete nếu không phù hợp

### 3. Organize Content
- ✅ Sử dụng reorder để sắp xếp logic
- ✅ Đảm bảo order hợp lý (1, 2, 3...)
- ✅ Group related concepts together

### 4. Error Handling
- ✅ Check file size trước khi upload
- ✅ Validate file type
- ✅ Handle parsing errors gracefully

## Error Codes

- `400 Bad Request` - Invalid file type, file too large, invalid data
- `401 Unauthorized` - Missing or invalid token
- `404 Not Found` - Content item or node not found
- `500 Internal Server Error` - Server error, AI API error

## Rate Limiting

- File upload: Max 10MB
- AI generation: 500ms delay between requests
- Preview: No rate limit (but file size limit applies)

## Security

- ✅ All endpoints require JWT authentication (except GET)
- ✅ File validation (type, size)
- ✅ Input sanitization
- ✅ Error messages don't expose sensitive info

## Next Steps

1. ✅ Preview mode - DONE
2. ✅ Update/Edit - DONE
3. ✅ Delete - DONE
4. ✅ Reorder - DONE
5. ⏳ Batch operations (import multiple files)
6. ⏳ Content versioning
7. ⏳ Content templates
8. ⏳ Analytics (usage stats)


