# EdTech AI MVP

Nền tảng học tập cá nhân hóa bằng AI trên mobile, giúp người dùng học kỹ năng thực tế một cách thú vị, nhớ lâu và duy trì thói quen học hàng ngày.

## 🎯 Tính năng chính

- **Học tập cá nhân hóa qua AI conversational** - Onboarding bằng chat với AI
- **Gamification mạnh** - Streak, XP, daily quests, leaderboard
- **Lộ trình học 30 ngày tự động** - Dựa trên trình độ thực tế
- **Hybrid learning** - Video + Quiz + Simulation thực hành
- **Spaced Repetition System (SRS)** - Nhắc ôn đúng lúc

## 🏗️ Kiến trúc

- **Backend**: NestJS + PostgreSQL + Redis + JWT
- **Mobile**: Flutter (sắp triển khai)
- **AI**: Google Gemini 1.5 Flash

## 🚀 Quick Start

### Backend Setup

#### Option 1: Dùng Docker (Khuyến nghị)

```bash
# Start PostgreSQL và Redis
docker-compose up -d

# Setup backend
cd backend
cp .env.example .env
# Sửa .env với: DATABASE_URL=postgres://edtech_user:edtech_pass@localhost:5432/edtech_db

npm install
npm run seed  # Seed sample data
npm start
```

#### Option 2: Setup thủ công

Xem chi tiết trong `backend/SETUP.md`

```bash
cd backend
cp .env.example .env
# Sửa .env với thông tin PostgreSQL của bạn

npm install
npm run seed
npm start
```

### Environment Variables

Tạo file `backend/.env` với nội dung:

```env
DATABASE_URL=postgres://user:pass@localhost:5432/edtech_db
REDIS_URL=redis://localhost:6379
JWT_SECRET=your-secret-key-here
JWT_EXPIRES_IN=7d
GEMINI_API_KEY=your-gemini-api-key
PORT=3000
NODE_ENV=development
CORS_ORIGIN=http://localhost:3000
```

### API Endpoints

#### Authentication
- `POST /api/v1/auth/register` - Đăng ký
- `POST /api/v1/auth/login` - Đăng nhập
- `GET /api/v1/auth/verify` - Verify token
- `GET /api/v1/auth/me` - Lấy thông tin user hiện tại

#### Users
- `GET /api/v1/users/profile` - Lấy profile (cần JWT)

## 📁 Cấu trúc dự án

```
edtech-ai-mvp/
├── backend/          # NestJS backend
│   ├── src/
│   │   ├── auth/     # Authentication module
│   │   ├── users/    # Users module
│   │   ├── config/   # Configuration files
│   │   └── main.ts   # Entry point
│   └── package.json
├── mobile/           # Flutter app (đang setup)
├── shared/           # Shared code/types
└── docs/             # Documentation
```

## 🔄 Roadmap

### ✅ Đã hoàn thành

- [x] Setup NestJS backend structure
- [x] Implement Auth module (register, login, verify)
- [x] Setup User entity và database
- [x] **Gamification System** - Currency, Progress, Shards
- [x] **Subjects & Learning Nodes** - Explorer và Scholar tracks
- [x] **Fog of War** - Chỉ hiện nodes đã unlock
- [x] **Unlock Mechanism** - Coin + Payment cho Scholar track
- [x] **Content Items** - Concepts, Examples, Hidden Rewards, Boss Quiz

### 🚧 Đang phát triển

- [x] Dashboard module (aggregator) ✅
- [x] Onboarding AI chat (Gemini integration) ✅
- [x] Placement test (Adaptive testing) ✅
- [x] Roadmap generation (30-day personalized learning path) ✅
- [x] Daily Quests system ✅
- [x] Leaderboard ✅
- [x] Swagger API Documentation ✅
- [x] Health Check Endpoint ✅
- [x] Global Error Handling ✅
- [x] **Backend 100% Complete** ✅
- [ ] Flutter mobile app

## 🧪 Testing

Sau khi seed database, bạn có thể test API:

### Quick Test
```bash
# Linux/Mac
cd backend
chmod +x scripts/test-api.sh
./scripts/test-api.sh

# Windows
cd backend
scripts\test-api.bat
```

### Manual Testing
Xem file `backend/API_TEST.md` để có hướng dẫn chi tiết test từng endpoint với cURL hoặc Postman.

### API Documentation (Swagger)
Sau khi start server, truy cập: `http://localhost:3000/api/v1/docs`
- Interactive API documentation
- Test endpoints trực tiếp từ browser
- JWT authentication support

### Seed Data
```bash
cd backend
npm run seed
```

Seed sẽ tạo:
- 2 subjects (1 Explorer, 1 Scholar)
- 1 learning node với 20 content items
- 9 sample questions cho placement test

## 📚 API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Đăng ký
- `POST /api/v1/auth/login` - Đăng nhập
- `GET /api/v1/auth/verify` - Verify token
- `GET /api/v1/auth/me` - Thông tin user hiện tại

### Currency & Gamification
- `GET /api/v1/currency` - Lấy coins, XP, streak, shards

### Subjects
- `GET /api/v1/subjects/explorer` - Danh sách subjects Explorer
- `GET /api/v1/subjects/scholar` - Danh sách subjects Scholar (với unlock status)
- `GET /api/v1/subjects/:id` - Chi tiết subject
- `GET /api/v1/subjects/:id/nodes` - Nodes đã unlock (Fog of War)

### Learning Nodes
- `GET /api/v1/nodes/subject/:subjectId` - Tất cả nodes của subject
- `GET /api/v1/nodes/:id` - Chi tiết node

### Content Items
- `GET /api/v1/content/node/:nodeId` - Content items của node
- `GET /api/v1/content/:id` - Chi tiết content item

### Progress Tracking
- `GET /api/v1/progress/node/:nodeId` - Tiến độ của user trong node (với HUD)
- `POST /api/v1/progress/complete-item` - Hoàn thành 1 content item

### Unlock Scholar
- `POST /api/v1/unlock/scholar` - Unlock subject Scholar (coin + payment)
- `GET /api/v1/unlock/transactions` - Lịch sử unlock transactions

### Placement Test
- `POST /api/v1/test/start` - Bắt đầu placement test (optional: subjectId)
- `GET /api/v1/test/current` - Lấy câu hỏi hiện tại và tiến độ
- `POST /api/v1/test/submit` - Submit đáp án (adaptive difficulty)
- `GET /api/v1/test/result/:testId` - Lấy kết quả test

### Onboarding AI
- `POST /api/v1/onboarding/chat` - Chat với AI để onboarding (conversational)
- `GET /api/v1/onboarding/status` - Lấy trạng thái onboarding
- `POST /api/v1/onboarding/reset` - Reset onboarding session

### Leaderboard
- `GET /api/v1/leaderboard/global?limit=100&page=1` - Global leaderboard (public)
- `GET /api/v1/leaderboard/weekly?limit=100&page=1` - Weekly leaderboard (requires auth)
- `GET /api/v1/leaderboard/subject/:subjectId?limit=100&page=1` - Subject leaderboard (requires auth)
- `GET /api/v1/leaderboard/me` - User's rank (requires auth)

### Health Check
- `GET /api/v1/health` - Server health status

## 📝 License

ISC

