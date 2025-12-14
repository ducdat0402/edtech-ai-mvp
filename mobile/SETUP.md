# 🚀 Flutter App Setup Guide

## Prerequisites

1. **Install Flutter SDK**
   ```bash
   # Download from https://flutter.dev/docs/get-started/install
   # Add to PATH
   flutter --version
   ```

2. **Install Dependencies**
   ```bash
   flutter doctor
   # Fix any issues shown
   ```

3. **IDE Setup**
   - Android Studio (recommended)
   - VS Code với Flutter extension
   - Xcode (for iOS, macOS only)

## Project Setup

### Step 1: Create Flutter Project

```bash
cd mobile
flutter create .
# Or if directory is empty:
# flutter create edtech_mobile
```

### Step 2: Add Dependencies

Update `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP & API
  dio: ^5.4.0
  http: ^1.1.0
  
  # State Management
  provider: ^6.1.1
  # or riverpod: ^2.4.9
  
  # Local Storage
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Navigation
  go_router: ^12.1.1
  
  # UI
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  
  # Utils
  intl: ^0.18.1
  uuid: ^4.2.1
  json_annotation: ^4.8.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  hive_generator: ^2.0.1
```

### Step 3: Project Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── routes.dart
├── core/
│   ├── api/
│   │   ├── api_client.dart
│   │   ├── api_endpoints.dart
│   │   └── interceptors.dart
│   ├── models/
│   │   └── base_models.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── storage_service.dart
│   │   └── api_service.dart
│   └── utils/
│       ├── constants.dart
│       └── helpers.dart
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── providers/
│   ├── dashboard/
│   ├── onboarding/
│   ├── placement_test/
│   ├── roadmap/
│   ├── learning/
│   ├── quests/
│   └── leaderboard/
└── widgets/
    └── common/
```

### Step 4: Configure API

Create `lib/core/api/api_endpoints.dart`:

```dart
class ApiEndpoints {
  static const String baseUrl = 'http://localhost:3000/api/v1';
  
  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  
  // Dashboard
  static const String dashboard = '/dashboard';
  
  // Subjects
  static const String explorerSubjects = '/subjects/explorer';
  static const String scholarSubjects = '/subjects/scholar';
  
  // Progress
  static String nodeProgress(String nodeId) => '/progress/node/$nodeId';
  static const String completeItem = '/progress/complete-item';
  
  // Quests
  static const String dailyQuests = '/quests/daily';
  
  // Leaderboard
  static const String globalLeaderboard = '/leaderboard/global';
  static const String weeklyLeaderboard = '/leaderboard/weekly';
  static const String myRank = '/leaderboard/me';
  
  // Placement Test
  static const String startTest = '/test/start';
  static const String currentTest = '/test/current';
  static const String submitAnswer = '/test/submit';
  
  // Roadmap
  static const String generateRoadmap = '/roadmap/generate';
  static String todayLesson(String roadmapId) => '/roadmap/$roadmapId/today';
  
  // Onboarding
  static const String onboardingChat = '/onboarding/chat';
  static const String onboardingStatus = '/onboarding/status';
}
```

## Next Steps

1. Setup API client với Dio
2. Implement authentication flow
3. Create dashboard screen
4. Implement onboarding chat
5. Build learning flow

## Resources

- **Backend API Docs**: http://localhost:3000/api/v1/docs
- **Flutter Docs**: https://flutter.dev/docs
- **Material Design**: https://m3.material.io/

