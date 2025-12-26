# Quick Start Guide - EdTech AI MVP

## 🚀 Bắt đầu nhanh

Hướng dẫn này giúp bạn setup và chạy ứng dụng EdTech AI MVP trong vài phút.

---

## 📋 Prerequisites

### Backend
- Node.js 18+ 
- PostgreSQL 14+
- npm hoặc yarn

### Mobile
- Flutter 3.0+
- Dart 3.0+
- Android Studio / Xcode (cho mobile development)
- Emulator hoặc physical device

---

## 🔧 Setup Backend

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Setup Database
```bash
# Tạo database PostgreSQL
createdb edtech_ai_mvp

# Hoặc sử dụng psql
psql -U postgres
CREATE DATABASE edtech_ai_mvp;
```

### 3. Configure Environment
Tạo file `.env` trong thư mục `backend/`:
```env
# Database
DATABASE_URL=postgresql://username:password@localhost:5432/edtech_ai_mvp

# JWT
JWT_SECRET=your-secret-key-here

# OpenAI
OPENAI_API_KEY=your-openai-api-key

# Server
PORT=3000
CORS_ORIGIN=http://localhost:3000
```

### 4. Run Migrations
```bash
npm run migration:run
```

### 5. Seed Database (Optional)
```bash
npm run seed
```

### 6. Start Backend
```bash
npm run start:dev
```

Backend sẽ chạy tại: `http://localhost:3000`

---

## 📱 Setup Mobile

### 1. Install Dependencies
```bash
cd mobile
flutter pub get
```

### 2. Configure API
Mở file `mobile/lib/core/config/api_config.dart` và cập nhật:
```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:3000/api/v1';
  // Hoặc cho Android emulator:
  // static const String baseUrl = 'http://10.0.2.2:3000/api/v1';
  // Hoặc cho iOS simulator:
  // static const String baseUrl = 'http://localhost:3000/api/v1';
}
```

### 3. Run App
```bash
# Android
flutter run

# iOS
flutter run -d ios

# Specific device
flutter devices
flutter run -d <device-id>
```

---

## 🧪 Test Flow

### 1. Register New User
1. Mở app → Login screen
2. Tap "Đăng ký"
3. Nhập thông tin:
   - Email: `test@example.com`
   - Password: `password123`
   - Full Name: `Test User`
4. Submit → Navigate to Dashboard

### 2. Complete Onboarding
1. Từ Dashboard → Navigate to Onboarding (hoặc auto redirect)
2. Chat với AI:
   - Turn 1: Nickname (ví dụ: "Tester")
   - Turn 2: Age (ví dụ: "25")
   - Turn 3: Current Level (ví dụ: "Beginner")
   - Turn 4: Target Goal (ví dụ: "Học Excel")
3. Tap "Xong / Test thôi" → Navigate to Placement Test

### 3. Take Placement Test
1. Answer questions (adaptive algorithm)
2. Complete test → Navigate to Analysis Complete
3. View results:
   - Score
   - Strengths/Weaknesses
   - Recommended level

### 4. Start Learning
1. Tap "Bắt đầu học" → Navigate to Subject Intro
2. View knowledge graph
3. Tap "Bắt đầu học" → Navigate to Node Map
4. Tap unlocked node → Node Detail
5. Tap content item → Content Viewer
6. Complete content → Mark as complete
7. Back to Node Detail → Progress updated

### 5. View Roadmap
1. Navigate to Roadmap (từ Dashboard hoặc bottom nav)
2. View 30-day learning path
3. Tap today's lesson → Start learning
4. Complete lesson → Day marked as complete

### 6. Complete Quests
1. Navigate to Daily Quests
2. View quests với progress
3. Complete quest → "Nhận phần thưởng" button
4. Claim reward → Success message
5. View quest history

### 7. Check Leaderboard
1. Navigate to Leaderboard
2. View rankings (Global, Weekly, Subject)
3. Check your rank
4. View top users

### 8. View Profile
1. Navigate to Profile
2. View stats (XP, Coins, Streak)
3. Toggle detailed view
4. View onboarding data
5. View placement test results

---

## 🔍 Common Issues

### Backend không start
```bash
# Check port 3000
lsof -i :3000
# Kill process nếu cần
kill -9 <PID>

# Check database connection
psql -U postgres -d edtech_ai_mvp

# Check environment variables
cat backend/.env
```

### Mobile không connect được backend
```bash
# Android emulator
# Sử dụng 10.0.2.2 thay vì localhost
# Update api_config.dart

# iOS simulator
# Sử dụng localhost (OK)

# Physical device
# Sử dụng IP của máy tính
# Ví dụ: http://192.168.1.100:3000/api/v1
```

### Database errors
```bash
# Reset database
npm run migration:revert
npm run migration:run
npm run seed
```

### Flutter errors
```bash
# Clean build
flutter clean
flutter pub get
flutter run
```

---

## 📊 API Testing

### Test với Postman/curl

#### Register
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "fullName": "Test User"
  }'
```

#### Login
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

#### Get Dashboard (với token)
```bash
curl -X GET http://localhost:3000/api/v1/dashboard \
  -H "Authorization: Bearer <token>"
```

---

## 🎯 Quick Test Checklist

- [ ] Backend starts successfully
- [ ] Database connected
- [ ] Mobile app runs
- [ ] Can register new user
- [ ] Can login
- [ ] Can complete onboarding
- [ ] Can take placement test
- [ ] Can view subject intro
- [ ] Can navigate to node map
- [ ] Can view content
- [ ] Can complete quests
- [ ] Can view leaderboard
- [ ] Can view profile

---

## 📝 Next Steps

1. **Explore Features**: Test tất cả tính năng theo TEST_CHECKLIST.md
2. **Review Code**: Xem PROJECT_STATUS.md và IMPLEMENTATION_SUMMARY.md
3. **Customize**: Update API keys, database config, etc.
4. **Deploy**: Setup production environment

---

## 🆘 Support

Nếu gặp vấn đề:
1. Check error logs
2. Review common issues section
3. Check TEST_CHECKLIST.md
4. Review code documentation

---

**Happy Testing! 🎉**


