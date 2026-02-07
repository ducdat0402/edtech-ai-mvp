# 🧪 API Testing Guide

## Prerequisites
- Server đang chạy: `npm start` hoặc `npm run start:nodemon`
- Database đã được seed: `npm run seed`
- Port mặc định: `3000`

## Test với cURL hoặc Postman

### 1. Register User
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!@#",
    "fullName": "Test User"
  }'
```

### 2. Login
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!@#"
  }'
```

**Lưu token từ response để dùng cho các request sau**

### 3. Get Explorer Subjects (Public)
```bash
curl http://localhost:3000/api/v1/subjects/explorer
```

### 4. Get Dashboard (Requires Auth)
```bash
curl http://localhost:3000/api/v1/dashboard \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 5. Get Scholar Subjects (Requires Auth)
```bash
curl http://localhost:3000/api/v1/subjects/scholar \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 6. Start Placement Test
```bash
# Start test without subject (general test)
curl -X POST http://localhost:3000/api/v1/test/start \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{}'

# Start test with specific subject
curl -X POST http://localhost:3000/api/v1/test/start \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "subjectId": "SUBJECT_ID_HERE"
  }'
```

**Response sẽ chứa:**
- `id`: Test ID
- `questions`: Array of questions (10 questions)
- `currentQuestionIndex`: 0
- `status`: "in_progress"
- `adaptiveData`: Initial adaptive data

### 7. Get Current Test & Question
```bash
curl http://localhost:3000/api/v1/test/current \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Response:**
```json
{
  "test": { ... },
  "question": {
    "id": "question-id",
    "question": "Phishing là gì?",
    "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
    "difficulty": "beginner"
  },
  "progress": {
    "current": 1,
    "total": 10
  }
}
```

### 8. Submit Answer
```bash
curl -X POST http://localhost:3000/api/v1/test/submit \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "answer": 1
  }'
```

**Response:**
```json
{
  "test": { ... },
  "isCorrect": true,
  "explanation": "Giải thích đáp án...",
  "nextQuestion": { ... },
  "completed": false
}
```

**Lặp lại bước 7-8 cho đến khi `completed: true`**

### 9. Get Test Result
```bash
curl http://localhost:3000/api/v1/test/result/TEST_ID_HERE \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Response:**
```json
{
  "id": "test-id",
  "score": 75,
  "level": "intermediate",
  "questions": [...],
  "completedAt": "2025-12-15T..."
}
```

### 10. Generate Roadmap
```bash
curl -X POST http://localhost:3000/api/v1/roadmap/generate \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "subjectId": "SUBJECT_ID_HERE"
  }'
```

**Response:**
```json
{
  "id": "roadmap-id",
  "subjectId": "subject-id",
  "status": "active",
  "totalDays": 30,
  "currentDay": 1,
  "startDate": "2025-12-15",
  "endDate": "2026-01-14",
  "days": [...]
}
```

### 11. Get Today's Lesson
```bash
curl http://localhost:3000/api/v1/roadmap/ROADMAP_ID_HERE/today \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Response:**
```json
{
  "dayNumber": 1,
  "scheduledDate": "2025-12-15",
  "status": "pending",
  "nodeId": "node-id",
  "content": {
    "node": { ... },
    "items": [...]
  }
}
```

### 12. Complete Roadmap Day
```bash
curl -X POST http://localhost:3000/api/v1/roadmap/ROADMAP_ID_HERE/complete-day \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "dayNumber": 1
  }'
```

### 13. Get Daily Quests
```bash
curl http://localhost:3000/api/v1/quests/daily \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 14. Get User Currency
```bash
curl http://localhost:3000/api/v1/currency \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 15. Get Journey Log History (Requires Auth)
```bash
curl http://localhost:3000/api/v1/content-edits/history/user \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 16. Submit Content Edit (Test for History)
```bash
curl -X POST http://localhost:3000/api/v1/content-edits/content/CONTENT_ITEM_ID/submit \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "add_image",
    "imageUrl": "https://example.com/image.jpg",
    "description": "Test image contribution"
  }'
```

### 17. Get All History (Admin Only)
```bash
curl http://localhost:3000/api/v1/content-edits/history/all \
  -H "Authorization: Bearer ADMIN_TOKEN_HERE"
```

## Expected Responses

### Register/Login Success
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid",
    "email": "test@example.com",
    "fullName": "Test User"
  }
}
```

### Dashboard Response
```json
{
  "stats": {
    "totalXP": 0,
    "coins": 0,
    "streak": 0,
    "shards": {}
  },
  "activeLearning": [],
  "explorerSubjects": [...],
  "scholarSubjects": [...],
  "dailyQuests": [...]
}
```

## 🧪 Test Flow Hoàn Chỉnh

### Flow 1: Placement Test → Roadmap
1. Register/Login
2. Get Explorer Subjects
3. Start Placement Test (với subjectId)
4. Answer tất cả questions (lặp get current → submit answer)
5. Get Test Result
6. Generate Roadmap (dựa trên test result)
7. Get Today's Lesson
8. Complete Day

### Flow 2: Daily Quests
1. Login
2. Get Daily Quests
3. Complete content items (tự động update quest progress)
4. Claim Quest Rewards

### Flow 3: Explorer Learning
1. Login
2. Get Explorer Subjects
3. Get Subject Nodes (Fog of War)
4. Get Node Content Items
5. Complete Content Items (nhận rewards tự động)
6. Get Progress

## 🚀 Automated Testing

### Linux/Mac
```bash
cd backend
chmod +x scripts/test-placement-roadmap.sh
./scripts/test-placement-roadmap.sh
```

### Windows (Git Bash)
```bash
cd backend
bash scripts/test-placement-roadmap.sh
```

## Troubleshooting

1. **401 Unauthorized**: Kiểm tra token có đúng format `Bearer TOKEN`
2. **500 Internal Server Error**: Kiểm tra database connection và logs
3. **404 Not Found**: Kiểm tra API prefix `/api/v1` và route path
4. **No questions in test**: Chạy `npm run seed` để tạo sample questions
5. **Roadmap generation fails**: Đảm bảo user đã hoàn thành placement test

