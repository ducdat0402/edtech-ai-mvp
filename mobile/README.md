# 📱 Gamistu — Flutter app

## 🎯 Overview

Ứng dụng Flutter của **Gamistu**: học cá nhân hóa, gamification tinh tế (xem `DESIGN.md`).

## 🏗️ Architecture

- **Framework**: Flutter 3.x
- **State Management**: Provider / Riverpod (TBD)
- **HTTP Client**: Dio / http
- **Local Storage**: SharedPreferences / Hive
- **Navigation**: GoRouter / Navigator 2.0
- **UI**: Material Design 3

## 📁 Project Structure

```
mobile/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   └── routes.dart
│   ├── core/
│   │   ├── api/
│   │   ├── models/
│   │   ├── services/
│   │   └── utils/
│   ├── features/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── onboarding/
│   │   ├── placement_test/
│   │   ├── roadmap/
│   │   ├── learning/
│   │   ├── quests/
│   │   └── leaderboard/
│   └── widgets/
│       └── common/
├── test/
└── pubspec.yaml
```

## 🚀 Setup

### Prerequisites
- Flutter SDK 3.x
- Dart 3.x
- Android Studio / Xcode (for mobile development)

### Installation

```bash
cd mobile
flutter pub get
flutter run
```

## 🔌 API Integration

Backend API Base URL: `http://localhost:3000/api/v1`

**Key Endpoints:**
- Auth: `/auth/register`, `/auth/login`
- Dashboard: `/dashboard`
- Subjects: `/subjects/explorer`, `/subjects/scholar`
- Progress: `/progress/node/:nodeId`, `/progress/complete-item`
- Quests: `/quests/daily`
- Leaderboard: `/leaderboard/global`, `/leaderboard/weekly`
- Placement Test: `/test/start`, `/test/submit`
- Roadmap: `/roadmap/generate`, `/roadmap/:id/today`
- Onboarding: `/onboarding/chat`

**Full API Docs**: `http://localhost:3000/api/v1/docs`

## 📱 Features to Implement

### Phase 1: Core Features
- [ ] Authentication (Login/Register)
- [ ] Dashboard với stats
- [ ] Onboarding AI Chat
- [ ] Placement Test UI
- [ ] Roadmap View

### Phase 2: Learning Features
- [ ] Subject List (Explorer/Scholar)
- [ ] Learning Node Map (Fog of War)
- [ ] Content Item Viewer
- [ ] Progress Tracking
- [ ] Quest System

### Phase 3: Gamification
- [ ] Leaderboard
- [ ] Achievements
- [ ] Rewards System
- [ ] Streak Visualization

## 🎨 UI/UX Guidelines

- **Design System**: Material Design 3
- **Color Scheme**: 
  - Primary: Explorer track (Green)
  - Secondary: Scholar track (Blue)
  - Accent: Gamification (Gold/Orange)
- **Typography**: Roboto / Inter
- **Icons**: Material Icons / Custom icons

## 📝 Notes

- Backend API đã sẵn sàng
- Swagger docs available tại `/api/v1/docs`
- JWT authentication required cho most endpoints
- CORS đã được configure

