# 🎓 EdTech AI MVP

> Ứng dụng học tập thông minh với AI, gamification, và adaptive learning

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev)
[![NestJS](https://img.shields.io/badge/NestJS-10.0+-red.svg)](https://nestjs.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-blue.svg)](https://www.postgresql.org)
[![OpenAI](https://img.shields.io/badge/OpenAI-GPT--4-green.svg)](https://openai.com)

---

## 📖 Tổng quan

EdTech AI MVP là một nền tảng học tập thông minh kết hợp:
- **AI-Powered Onboarding**: Chat với AI để tạo profile học tập cá nhân
- **Adaptive Placement Test**: Test thích ứng để xác định level phù hợp
- **Personalized Roadmap**: Lộ trình học 30 ngày được tạo tự động
- **Gamification**: Streaks, quests, leaderboard để tăng động lực
- **Fog of War Learning**: Học tập theo cấu trúc knowledge graph với progressive unlock

---

## ✨ Tính năng chính

### 🎯 Core Features
- ✅ **Authentication**: Register, Login, JWT-based security
- ✅ **AI Onboarding**: Conversational onboarding với OpenAI
- ✅ **Adaptive Placement Test**: Test thích ứng với AI-generated questions
- ✅ **Knowledge Graph**: Visual learning path với Fog of War
- ✅ **Content Learning**: Text, Video, Code examples, Interactive quizzes
- ✅ **30-Day Roadmap**: Personalized learning path
- ✅ **Gamification**: Streaks, Daily Quests, Leaderboard, Points system
- ✅ **Progress Tracking**: Real-time progress với visual indicators

### 🎨 UX Features
- ✅ **Skeleton Loaders**: Shimmer animations cho loading states
- ✅ **Error Handling**: Comprehensive error widgets với retry
- ✅ **Empty States**: Informative empty states với actions
- ✅ **Pull-to-Refresh**: Easy data refresh trên tất cả screens
- ✅ **Bottom Navigation**: Quick access to main features
- ✅ **Responsive Design**: Works trên mọi screen sizes

---

## 🏗️ Kiến trúc

### Tech Stack

**Backend**
- **Framework**: NestJS 10+
- **Database**: PostgreSQL 14+ với TypeORM
- **Authentication**: JWT
- **AI**: OpenAI API (GPT-4)
- **Validation**: class-validator

**Mobile**
- **Framework**: Flutter 3.0+
- **State Management**: Provider
- **Routing**: go_router
- **HTTP Client**: Dio
- **Video Player**: video_player, chewie

### Project Structure

```
edtech-ai-mvp/
├── backend/                 # NestJS Backend
│   ├── src/
│   │   ├── auth/          # Authentication
│   │   ├── users/         # User management
│   │   ├── subjects/      # Subject management
│   │   ├── learning-nodes/# Learning nodes
│   │   ├── content-items/ # Content items
│   │   ├── user-progress/ # Progress tracking
│   │   ├── roadmap/       # 30-day roadmap
│   │   ├── placement-test/# Placement test
│   │   ├── quests/        # Daily quests
│   │   ├── leaderboard/   # Leaderboard
│   │   ├── user-currency/ # Currency system
│   │   └── ai/            # AI integration
│   └── package.json
│
├── mobile/                 # Flutter Mobile App
│   ├── lib/
│   │   ├── app/           # App config & routing
│   │   ├── core/          # Core utilities
│   │   │   ├── services/  # API services
│   │   ├── widgets/       # Reusable widgets
│   │   └── features/      # Feature modules
│   │       ├── auth/
│   │       ├── onboarding/
│   │       ├── placement_test/
│   │       ├── subjects/
│   │       ├── learning_nodes/
│   │       ├── content/
│   │       ├── roadmap/
│   │       ├── quests/
│   │       ├── leaderboard/
│   │       ├── profile/
│   │       └── dashboard/
│   └── pubspec.yaml
│
└── docs/                   # Documentation
    ├── PROJECT_STATUS.md
    ├── IMPLEMENTATION_SUMMARY.md
    ├── TEST_CHECKLIST.md
    └── QUICK_START_GUIDE.md
```

---

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- PostgreSQL 14+
- Flutter 3.0+
- OpenAI API Key

### Backend Setup

```bash
# 1. Install dependencies
cd backend
npm install

# 2. Setup database
createdb edtech_ai_mvp

# 3. Configure environment
cp .env.example .env
# Edit .env với your credentials

# 4. Run migrations
npm run migration:run

# 5. Seed database (optional)
npm run seed

# 6. Start server
npm run start:dev
```

Backend chạy tại: `http://localhost:3000`

### Mobile Setup

```bash
# 1. Install dependencies
cd mobile
flutter pub get

# 2. Configure API
# Update mobile/lib/core/config/api_config.dart
# với backend URL

# 3. Run app
flutter run
```

📖 **Chi tiết**: Xem [QUICK_START_GUIDE.md](./QUICK_START_GUIDE.md)

---

## 📱 Screenshots

### Onboarding & Placement Test
- AI Chat interface
- Adaptive placement test
- Analysis results

### Learning Flow
- Knowledge graph visualization
- Node map với Fog of War
- Content viewer với multiple types

### Gamification
- Streak display
- Daily quests
- Leaderboard

---

## 📚 Documentation

- **[PROJECT_STATUS.md](./PROJECT_STATUS.md)** - Project status và roadmap
- **[IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md)** - Chi tiết implementation
- **[TEST_CHECKLIST.md](./TEST_CHECKLIST.md)** - Test cases và checklist
- **[QUICK_START_GUIDE.md](./QUICK_START_GUIDE.md)** - Setup và quick start

---

## 🎯 User Flow

```
Register/Login
    ↓
Onboarding Chat (AI)
    ↓
Placement Test (Adaptive)
    ↓
Analysis Complete
    ↓
Subject Introduction (Knowledge Graph)
    ↓
Learning Node Map (Fog of War)
    ↓
Node Detail → Content Viewer
    ↓
Complete Content → Update Progress
    ↓
30-Day Roadmap → Daily Lessons
    ↓
Daily Quests → Claim Rewards
    ↓
Leaderboard → View Rankings
```

---

## 🔌 API Endpoints

### Authentication
- `POST /auth/register` - Register user
- `POST /auth/login` - Login
- `GET /auth/me` - Get current user

### Learning
- `GET /subjects/:id/intro` - Subject introduction
- `GET /subjects/:id/nodes` - Subject nodes
- `GET /nodes/:id` - Node detail
- `GET /content/:id` - Content detail
- `POST /progress/complete-item` - Complete content

### Roadmap
- `POST /roadmap/generate` - Generate roadmap
- `GET /roadmap` - Get roadmap
- `GET /roadmap/:id/today` - Today's lesson
- `POST /roadmap/:id/complete-day` - Complete day

### Gamification
- `GET /quests/daily` - Daily quests
- `POST /quests/:id/claim` - Claim quest
- `GET /leaderboard/global` - Global leaderboard
- `GET /leaderboard/weekly` - Weekly leaderboard

📖 **Chi tiết**: Xem [PROJECT_STATUS.md](./PROJECT_STATUS.md#-api-endpoints)

---

## 🧪 Testing

### Test Checklist
Xem [TEST_CHECKLIST.md](./TEST_CHECKLIST.md) để có danh sách đầy đủ test cases.

### Quick Test
```bash
# Backend
npm run test

# Mobile
flutter test
```

---

## 🛠️ Development

### Backend Commands
```bash
npm run start:dev      # Development mode
npm run build          # Build for production
npm run start:prod     # Production mode
npm run migration:run   # Run migrations
npm run seed           # Seed database
```

### Mobile Commands
```bash
flutter run            # Run app
flutter test           # Run tests
flutter build apk      # Build Android
flutter build ios      # Build iOS
```

---

## 📊 Project Status

### ✅ Completed
- [x] Authentication system
- [x] AI onboarding chat
- [x] Adaptive placement test
- [x] Learning flow (subjects, nodes, content)
- [x] 30-day roadmap
- [x] Gamification (streaks, quests, leaderboard)
- [x] Dashboard & Profile
- [x] Navigation system
- [x] UX improvements

### 🚧 In Progress
- [ ] Unit tests
- [ ] Integration tests
- [ ] Performance optimization
- [ ] Offline support

### 📋 Planned
- [ ] Push notifications
- [ ] Analytics tracking
- [ ] Dark mode
- [ ] Localization (i18n)

📖 **Chi tiết**: Xem [PROJECT_STATUS.md](./PROJECT_STATUS.md)

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

---

## 📝 License

This project is licensed under the MIT License.

---

## 👥 Team

- **Backend**: NestJS, TypeORM, PostgreSQL
- **Mobile**: Flutter, Provider, go_router
- **AI**: OpenAI API

---

## 🆘 Support

Nếu gặp vấn đề:
1. Check [QUICK_START_GUIDE.md](./QUICK_START_GUIDE.md) - Common Issues
2. Review [TEST_CHECKLIST.md](./TEST_CHECKLIST.md)
3. Check error logs
4. Create issue trên GitHub

---

## 🎉 Acknowledgments

- OpenAI cho AI capabilities
- Flutter team cho amazing framework
- NestJS team cho robust backend framework
- Community cho support và feedback

---

## 📞 Contact

- **Project**: EdTech AI MVP
- **Version**: 1.0.0
- **Last Updated**: 2024

---

**Made with ❤️ for better education**
