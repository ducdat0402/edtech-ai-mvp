# 📚 Hướng Dẫn Import Dữ Liệu Thô Thành Concepts/Questions

## Tổng Quan

Hệ thống hỗ trợ chuyển đổi dữ liệu thô (text, documents) thành structured content (concepts, examples, questions) sử dụng AI.

## API Endpoints

### 1. Upload File và Import Concepts (PDF, DOCX, TXT)

**Endpoint:** `POST /api/v1/content/node/:nodeId/import-file`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Body (Form Data):**
- `file`: File (PDF, DOCX, hoặc TXT) - Max 10MB
- `topic`: Chủ đề (ví dụ: Excel, Python, Security)
- `count`: Số lượng concepts (optional, default: 5)

**Response:**
```json
[
  {
    "id": "uuid",
    "nodeId": "node-uuid",
    "type": "concept",
    "title": "Tên khái niệm",
    "content": "Nội dung chi tiết...",
    "order": 1,
    "rewards": {
      "xp": 10,
      "coin": 1
    }
  },
  ...
]
```

**Ví dụ với cURL:**
```bash
curl -X POST http://localhost:3000/api/v1/content/node/abc123/import-file \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@/path/to/document.pdf" \
  -F "topic=Microsoft Excel" \
  -F "count=5"
```

**Ví dụ với Postman:**
1. Chọn method: POST
2. URL: `http://localhost:3000/api/v1/content/node/:nodeId/import-file`
3. Body → form-data
4. Key: `file` (type: File) → Chọn file
5. Key: `topic` (type: Text) → Nhập topic
6. Key: `count` (type: Text, optional) → Nhập số lượng

### 2. Upload File và Generate Single Concept

**Endpoint:** `POST /api/v1/content/node/:nodeId/generate-concept-from-file`

**Body (Form Data):**
- `file`: File (PDF, DOCX, TXT)
- `topic`: Chủ đề
- `difficulty`: "beginner" | "intermediate" | "advanced" (optional, default: "beginner")

### 3. Upload File và Generate Examples

**Endpoint:** `POST /api/v1/content/node/:nodeId/generate-examples-from-file`

**Body (Form Data):**
- `file`: File (PDF, DOCX, TXT)
- `topic`: Chủ đề
- `count`: Số lượng examples (optional, default: 3)

### 4. Import Multiple Concepts từ Raw Text

**Endpoint:** `POST /api/v1/content/node/:nodeId/import-concepts`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Body:**
```json
{
  "rawText": "Nội dung thô từ tài liệu, sách, PDF...",
  "topic": "Chủ đề (ví dụ: Excel, Python, Security)",
  "count": 5
}
```

**Response:**
```json
[
  {
    "id": "uuid",
    "nodeId": "node-uuid",
    "type": "concept",
    "title": "Tên khái niệm",
    "content": "Nội dung chi tiết...",
    "order": 1,
    "rewards": {
      "xp": 10,
      "coin": 1
    }
  },
  ...
]
```

**Ví dụ:**
```bash
curl -X POST http://localhost:3000/api/v1/content/node/abc123/import-concepts \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "rawText": "Excel là một công cụ bảng tính mạnh mẽ. Nó cho phép bạn tạo các bảng tính, tính toán, và phân tích dữ liệu...",
    "topic": "Microsoft Excel",
    "count": 5
  }'
```

### 2. Generate Single Concept

**Endpoint:** `POST /api/v1/content/node/:nodeId/generate-concept`

**Body:**
```json
{
  "rawText": "Nội dung thô cho 1 khái niệm",
  "topic": "Chủ đề",
  "difficulty": "beginner" // hoặc "intermediate", "advanced"
}
```

**Response:**
```json
{
  "id": "uuid",
  "nodeId": "node-uuid",
  "type": "concept",
  "title": "Tên khái niệm",
  "content": "Nội dung chi tiết...",
  "order": 1,
  "rewards": {
    "xp": 10,
    "coin": 1
  }
}
```

### 3. Generate Examples

**Endpoint:** `POST /api/v1/content/node/:nodeId/generate-examples`

**Body:**
```json
{
  "rawText": "Nội dung thô để tạo ví dụ",
  "topic": "Chủ đề",
  "count": 3
}
```

**Response:**
```json
[
  {
    "id": "uuid",
    "nodeId": "node-uuid",
    "type": "example",
    "title": "Ví dụ 1",
    "content": "Nội dung ví dụ...",
    "order": 1,
    "rewards": {
      "xp": 5,
      "coin": 1
    }
  },
  ...
]
```

## Workflow Sử Dụng

### Phương Án 1: Upload File (Khuyến Nghị)

#### Bước 1: Chuẩn Bị File
- File PDF, DOCX, hoặc TXT
- Max size: 10MB
- Nội dung liên quan đến chủ đề

#### Bước 2: Upload File
Sử dụng endpoint `/import-file` với file upload

#### Bước 3: AI Tự Động
- Parse file thành text
- Generate concepts bằng AI
- Save vào database

### Phương Án 2: Raw Text

#### Bước 1: Chuẩn Bị Dữ Liệu Thô

Dữ liệu thô có thể là:
- Text từ tài liệu, sách
- Nội dung từ website, blog
- Text đã extract từ PDF/DOCX

**Lưu ý:**
- Giới hạn độ dài: 8000 ký tự cho multiple concepts
- Giới hạn độ dài: 2000 ký tự cho single concept
- Nên chọn nội dung liên quan đến chủ đề

### Bước 2: Xác Định Learning Node (Cả 2 phương án)

Cần có `nodeId` của Learning Node mà bạn muốn thêm content vào.

**Lấy nodeId:**
```bash
# Get all nodes for a subject
GET /api/v1/nodes/subject/:subjectId

# Get specific node
GET /api/v1/nodes/:nodeId
```

### Bước 3: Gọi API Import

**Phương án 1 (File Upload):**
```bash
# Upload file và import
curl -X POST http://localhost:3000/api/v1/content/node/NODE_ID/import-file \
  -H "Authorization: Bearer TOKEN" \
  -F "file=@document.pdf" \
  -F "topic=Excel Basics" \
  -F "count=5"
```

**Phương án 2 (Raw Text):**
Sử dụng endpoint `/import-concepts` với raw text trong body.

### Bước 4: Review & Edit (Optional)

Sau khi AI generate, bạn có thể:
- Review content trong database
- Edit nếu cần thiết
- Delete nếu không phù hợp

## Ví Dụ Thực Tế

### Ví Dụ 1: Upload PDF và Import Concepts

```bash
# 1. Get node ID
curl http://localhost:3000/api/v1/nodes/subject/excel-subject-id

# 2. Upload PDF file
curl -X POST http://localhost:3000/api/v1/content/node/NODE_ID/import-file \
  -H "Authorization: Bearer TOKEN" \
  -F "file=@excel-tutorial.pdf" \
  -F "topic=Microsoft Excel Basics" \
  -F "count=5"
```

**Kết quả:** 
- PDF được parse thành text
- AI tạo 5 concepts từ nội dung PDF
- Concepts được save vào database

### Ví Dụ 2: Import Concepts cho Excel Node (Raw Text)

```bash
# 1. Get node ID
curl http://localhost:3000/api/v1/nodes/subject/excel-subject-id

# 2. Import concepts
curl -X POST http://localhost:3000/api/v1/content/node/NODE_ID/import-concepts \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "rawText": "Excel là công cụ bảng tính. Các hàm cơ bản: SUM, AVERAGE, COUNT. PivotTable giúp phân tích dữ liệu. VLOOKUP tìm kiếm dữ liệu. Conditional Formatting định dạng có điều kiện.",
    "topic": "Microsoft Excel Basics",
    "count": 5
  }'
```

**Kết quả:** AI sẽ tạo 5 concepts:
1. Excel là công cụ bảng tính
2. Các hàm cơ bản (SUM, AVERAGE, COUNT)
3. PivotTable phân tích dữ liệu
4. VLOOKUP tìm kiếm
5. Conditional Formatting

### Ví Dụ 3: Upload DOCX và Generate Single Concept

```bash
curl -X POST http://localhost:3000/api/v1/content/node/NODE_ID/generate-concept-from-file \
  -H "Authorization: Bearer TOKEN" \
  -F "file=@security-guide.docx" \
  -F "topic=Cybersecurity" \
  -F "difficulty=beginner"
```

### Ví Dụ 4: Generate Single Concept (Raw Text)

```bash
curl -X POST http://localhost:3000/api/v1/content/node/NODE_ID/generate-concept \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "rawText": "Two-Factor Authentication (2FA) là phương pháp bảo mật yêu cầu hai yếu tố xác thực: mật khẩu và mã OTP hoặc thiết bị.",
    "topic": "Cybersecurity",
    "difficulty": "beginner"
  }'
```

## Supported File Types

- **PDF** (.pdf) - Application/pdf
- **DOCX** (.docx) - Microsoft Word documents
- **TXT** (.txt) - Plain text files

**Limitations:**
- Max file size: 10MB
- PDF: Text-based PDFs work best (scanned PDFs may not work)
- DOCX: Standard Word documents

## Best Practices

### 1. Chọn File/Raw Text Phù Hợp
- ✅ Nội dung rõ ràng, có cấu trúc
- ✅ Liên quan trực tiếp đến chủ đề
- ✅ Không quá dài (tối đa 8000 ký tự)
- ❌ Tránh nội dung lộn xộn, không liên quan

### 2. Đặt Topic Chính Xác
- ✅ Topic ngắn gọn, rõ ràng
- ✅ Phù hợp với Learning Node
- ❌ Tránh topic quá chung chung

### 3. File Quality
- ✅ PDF: Text-based (không phải scanned image)
- ✅ DOCX: Standard format, không có password
- ✅ TXT: UTF-8 encoding
- ❌ Tránh scanned PDFs, corrupted files

### 4. Số Lượng Concepts
- ✅ 3-5 concepts cho mỗi lần import
- ✅ Không quá nhiều để tránh chất lượng kém
- ❌ Tránh import quá nhiều cùng lúc

### 5. Review Sau Khi Generate
- ✅ Luôn review content sau khi AI generate
- ✅ Edit nếu cần thiết
- ✅ Delete nếu không phù hợp

## Error Handling

### Common Errors

1. **"Learning node not found"**
   - Kiểm tra `nodeId` có đúng không
   - Đảm bảo node đã tồn tại trong database

2. **"OpenAI API not configured"**
   - Kiểm tra `OPENAI_API_KEY` trong `.env`
   - Đảm bảo API key hợp lệ

3. **"Failed to parse PDF/DOCX"**
   - File có thể bị corrupted
   - PDF có thể là scanned image (không có text)
   - DOCX có thể có password protection
   - Thử với file khác hoặc convert sang TXT

4. **"File size exceeds maximum limit"**
   - File quá 10MB
   - Chia nhỏ file hoặc extract text thủ công

5. **"Unsupported file type"**
   - Chỉ support PDF, DOCX, TXT
   - Convert file sang format được support

6. **"Failed to generate concepts"**
   - Raw text có thể quá dài
   - API rate limit
   - Thử lại với text ngắn hơn hoặc file nhỏ hơn

## Cost Estimation

### OpenAI API Costs (gpt-4o-mini)

- **Single Concept:** ~500-1000 tokens → ~$0.0001-0.0002
- **Multiple Concepts (5):** ~2500-5000 tokens → ~$0.0005-0.001
- **Example:** ~300-600 tokens → ~$0.00006-0.00012

**Lưu ý:** Chi phí có thể thay đổi tùy theo độ dài raw text và số lượng concepts.

## Limitations

1. **Text Length:**
   - Multiple concepts: 8000 ký tự
   - Single concept: 2000 ký tự

2. **Rate Limiting:**
   - Delay 500ms giữa các requests
   - Tránh gọi quá nhiều cùng lúc

3. **Quality:**
   - Phụ thuộc vào chất lượng raw text
   - Cần review và edit sau khi generate

## Next Steps

1. ✅ Implement file upload (PDF, DOCX)
2. ✅ Batch import từ multiple files
3. ✅ Preview trước khi save
4. ✅ Edit generated content
5. ✅ Export/Import templates

## Testing

### Test với cURL

```bash
# 1. Login để lấy token
TOKEN=$(curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}' \
  | jq -r '.accessToken')

# 2. Get node ID
NODE_ID=$(curl http://localhost:3000/api/v1/nodes/subject/SUBJECT_ID \
  -H "Authorization: Bearer $TOKEN" \
  | jq -r '.[0].id')

# 3. Import concepts
curl -X POST http://localhost:3000/api/v1/content/node/$NODE_ID/import-concepts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "rawText": "Your raw text here...",
    "topic": "Your topic",
    "count": 5
  }'
```

## Support

Nếu gặp vấn đề:
1. Check logs trong backend console
2. Verify API key trong `.env`
3. Check nodeId có tồn tại không
4. Review raw text có quá dài không

