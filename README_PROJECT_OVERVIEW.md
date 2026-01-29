# EdTech AI MVP - Tổng Quan Dự Án

## 📋 Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [Công Nghệ Sử Dụng](#công-nghệ-sử-dụng)
3. [Cấu Trúc Dự Án](#cấu-trúc-dự-án)
4. [Tính Năng Chính](#tính-năng-chính)
5. [Hướng Dẫn Cài Đặt](#hướng-dẫn-cài-đặt)
6. [Scripts Hữu Ích](#scripts-hữu-ích)
7. [Design System](#design-system)

---

## 🎯 Giới Thiệu

**EdTech AI MVP** là ứng dụng học tập gamified (game hóa) với AI hỗ trợ. Ứng dụng kết hợp:
- **Gamification**: XP, Level, Streak, Coins, Achievements, Leaderboard
- **AI Tutoring**: Chat AI để xác định mục tiêu học tập, tạo lộ trình cá nhân hóa
- **Adaptive Learning**: Bài kiểm tra đầu vào, Skill Tree động
- **Community**: Đóng góp nội dung, chỉnh sửa bài học

---

## 🛠 Công Nghệ Sử Dụng

### Backend
| Công nghệ | Mục đích |
|-----------|----------|
| **NestJS** | Framework chính |
| **TypeORM** | ORM cho PostgreSQL |
| **PostgreSQL + pgvector** | Database + Vector embeddings |
| **OpenAI GPT-4o-mini** | AI generation (quiz, content) |
| **JWT** | Authentication |
| **Cloudinary** | Media storage |

### Mobile/Desktop
| Công nghệ | Mục đích |
|-----------|----------|
| **Flutter** | Cross-platform UI |
| **Provider** | State management |
| **go_router** | Navigation |
| **Dio** | HTTP client |
| **flutter_quill** | Rich text editor |
| **confetti** | Celebration animations |
| **Google Fonts** | Orbitron, Exo2, Inter |

---

## 📁 Cấu Trúc Dự Án

```
edtech-ai-mvp/
├── backend/                    # NestJS Backend
│   └── src/
│       ├── achievements/       # Hệ thống thành tựu
│       ├── ai/                 # AI Service (OpenAI)
│       ├── ai-agents/          # ITS, DRL, LangChain
│       ├── auth/               # Authentication
│       ├── content-edits/      # Community editing
│       ├── content-items/      # Nội dung bài học
│       ├── dashboard/          # Dashboard API
│       ├── domains/            # Lĩnh vực học
│       ├── knowledge-graph/    # Knowledge graph + RAG
│       ├── leaderboard/        # Bảng xếp hạng
│       ├── learning-nodes/     # Bài học
│       ├── onboarding/         # Onboarding chat
│       ├── personal-mind-map/  # Mind map cá nhân
│       ├── placement-test/     # Bài kiểm tra đầu vào
│       ├── quests/             # Daily quests
│       ├── quiz/               # Quiz system
│       ├── seed/               # Database seeding scripts
│       ├── skill-tree/         # Skill tree
│       ├── subjects/           # Môn học
│       ├── user-currency/      # XP, Coins, Level
│       └── user-progress/      # Tiến độ học
│
├── mobile/                     # Flutter App
│   └── lib/
│       ├── app/                # App config, routes
│       ├── core/               # Services, constants
│       ├── features/           # Feature modules
│       │   ├── achievements/   # Màn hình thành tựu
│       │   ├── admin/          # Admin panel
│       │   ├── auth/           # Login/Register
│       │   ├── content/        # Xem/sửa nội dung
│       │   ├── currency/       # XP, Coins
│       │   ├── dashboard/      # Trang chủ
│       │   ├── domains/        # Lĩnh vực
│       │   ├── leaderboard/    # Bảng xếp hạng
│       │   ├── learning_nodes/ # Bài học
│       │   ├── onboarding/     # Onboarding
│       │   ├── placement_test/ # Kiểm tra đầu vào
│       │   ├── profile/        # Hồ sơ cá nhân
│       │   ├── quests/         # Nhiệm vụ hàng ngày
│       │   ├── quiz/           # Quiz & Boss Quiz
│       │   ├── skill_tree/     # Cây kỹ năng
│       │   └── subjects/       # Môn học
│       └── theme/              # Design system
│           ├── colors.dart
│           ├── gradients.dart
│           ├── text_styles.dart
│           ├── app_theme.dart
│           └── widgets/        # Custom widgets
```

---

## ✨ Tính Năng Chính

### 1. 🎮 Gamification System
- **Level System**: 7 cấp danh hiệu (Người mới → Thần đồng)
- **XP & Coins**: Nhận từ quiz, quests, achievements
- **Streak**: Chuỗi ngày học liên tục
- **Daily Quests**: Nhiệm vụ hàng ngày với rewards
- **Achievements**: 50+ thành tựu để unlock
- **Leaderboard**: Xếp hạng XP theo tuần/tháng/all-time

### 2. 📚 Learning System
- **Subjects**: Quản lý môn học
- **Domains**: Phân chia lĩnh vực trong môn
- **Learning Nodes**: Bài học với concept + example
- **Content Items**: Nội dung rich text, media
- **Skill Tree**: Cây kỹ năng với prerequisites

### 3. 🧠 AI Features
- **Onboarding Chat**: AI giới thiệu app
- **Learning Goals Chat**: AI xác định mục tiêu học tập
- **Placement Test**: AI tạo bài kiểm tra đầu vào
- **Quiz Generation**: AI tạo câu hỏi từ nội dung
- **Boss Quiz**: Quiz tổng hợp cho learning node
- **Personal Mind Map**: Mind map học tập cá nhân

### 4. ✏️ Community Features
- **Content Editing**: Đề xuất chỉnh sửa bài học
- **Version History**: Lịch sử phiên bản
- **Admin Approval**: Admin duyệt contributions
- **Media Upload**: Upload hình ảnh, video

### 5. 📊 Progress Tracking
- **User Progress**: Theo dõi tiến độ từng bài
- **Journey Log**: Lịch sử hoạt động
- **Analysis**: Phân tích kết quả placement test

---

## 🚀 Hướng Dẫn Cài Đặt

### Prerequisites
- Node.js 18+
- PostgreSQL 15+ với pgvector extension
- Flutter 3.16+
- OpenAI API Key

### Backend Setup
```bash
cd backend

# Install dependencies
npm install

# Setup environment
cp .env.example .env
# Edit .env với database URL và OpenAI key

# Run migrations
npm run migration:run

# Start server
npm start
```

### Mobile Setup
```bash
cd mobile

# Install dependencies
flutter pub get

# Run on Windows
flutter run -d windows

# Run on Android
flutter run -d android

# Run on Web
flutter run -d chrome
```

---

## 📜 Scripts Hữu Ích

### Database Seeding
```bash
cd backend

# Seed subjects và domains
npx ts-node src/seed/seed.service.ts

# Generate learning nodes từ file markdown
npx ts-node src/seed/generate-learning-nodes.ts

# Generate quizzes cho content items
npx ts-node src/seed/generate-quizzes.ts --limit=100

# Generate boss quizzes cho learning nodes
npx ts-node src/seed/generate-boss-quizzes.ts --limit=50

# Generate embeddings cho knowledge graph
npx ts-node src/knowledge-graph/generate-embeddings-standalone.ts
```

### Useful Commands
```bash
# Backend
npm run start:dev          # Development mode
npm run build              # Build production
npm run migration:generate # Generate migration
npm run migration:run      # Run migrations

# Mobile
flutter clean              # Clean build
flutter pub get            # Get dependencies
flutter run -d windows     # Run on Windows
flutter build apk          # Build Android APK
```

---

## 🎨 Design System

### Color Palette (Cyberpunk Dark Theme)

```dart
// Backgrounds
bgPrimary:   #0A0A0A  // Main background
bgSecondary: #1A1A1A  // Cards
bgTertiary:  #252525  // Active elements

// Neon Colors
purpleNeon:  #8B5CF6
pinkNeon:    #EC4899
orangeNeon:  #F59E0B
cyanNeon:    #06B6D4

// Functional
successNeon: #00FF88
errorNeon:   #FF3366
warningNeon: #FFE31A

// Gamification
xpGold:      #FFD700
streakOrange:#FF4500
coinGold:    #FFD700
```

### Typography
- **Headers**: Orbitron (gaming style)
- **Body**: Exo2 (sci-fi)
- **Numbers/Stats**: Inter

### Level Colors
| Level | Danh hiệu | Màu |
|-------|-----------|-----|
| 1-5 | Người mới | #9CA3AF (Gray) |
| 6-10 | Học viên | #60A5FA (Blue) |
| 11-20 | Sinh viên | #34D399 (Green) |
| 21-35 | Chuyên gia | #A78BFA (Purple) |
| 36-50 | Bậc thầy | #F59E0B (Orange) |
| 51-75 | Huyền thoại | #EC4899 (Pink) |
| 76+ | Thần đồng | #FFD700 (Gold) |

---

## 📱 Screenshots

*(Thêm screenshots của app ở đây)*

---

## 🔗 API Documentation

Xem các file hướng dẫn chi tiết:
- `QUICK_START_GUIDE.md` - Bắt đầu nhanh
- `CONTENT_MANAGEMENT_API.md` - API quản lý nội dung
- `COMMUNITY_EDIT_FLOW.md` - Luồng đóng góp cộng đồng
- `SKILL_TREE_GUIDE.md` - Hướng dẫn Skill Tree
- `VIDEO_STORAGE_ARCHITECTURE.md` - Kiến trúc lưu trữ video

---

## 👥 Team

*(Thêm thông tin team ở đây)*

---

## 📄 License

*(Thêm license ở đây)*

---

*Last updated: January 2026*
