# 🚀 Flutter App - Quick Start

## ✅ Setup Complete!

Flutter project đã được setup với:
- ✅ Project structure
- ✅ Dependencies installed
- ✅ API client với Dio
- ✅ Authentication service
- ✅ Login & Register screens
- ✅ Dashboard screen
- ✅ Routing với GoRouter

## 🏃 Run App

```bash
cd mobile
flutter run
```

**Lưu ý**: 
- Android Emulator: API URL đã được set là `http://10.0.2.2:3000/api/v1`
- iOS Simulator: Cần đổi thành `http://localhost:3000/api/v1` trong `api_constants.dart`
- Physical Device: Cần đổi thành `http://YOUR_IP:3000/api/v1`

## 📱 Features Implemented

### Authentication
- ✅ Login screen
- ✅ Register screen
- ✅ JWT token storage (secure storage)
- ✅ Auto token injection

### Dashboard
- ✅ Stats display (XP, Coins, Streak)
- ✅ Daily Quests list
- ✅ Explorer & Scholar subjects
- ✅ Pull to refresh

### API Integration
- ✅ All endpoints defined
- ✅ Error handling
- ✅ Token management
- ✅ Auto refresh on 401

## 🔧 Next Steps

1. **Test Authentication**
   - Run app
   - Try login/register
   - Check dashboard loads

2. **Add More Screens**
   - Onboarding chat
   - Placement test
   - Learning nodes
   - Roadmap view

3. **Improve UI**
   - Better styling
   - Animations
   - Loading states
   - Error handling UI

## 📚 Project Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart          # App setup với providers
│   └── routes.dart        # GoRouter configuration
├── core/
│   ├── api/
│   │   └── api_client.dart
│   ├── constants/
│   │   └── api_constants.dart
│   └── services/
│       ├── auth_service.dart
│       └── api_service.dart
└── features/
    ├── auth/
    │   └── screens/
    │       ├── login_screen.dart
    │       └── register_screen.dart
    └── dashboard/
        └── screens/
            └── dashboard_screen.dart
```

## 🐛 Troubleshooting

### Connection Error
- Check backend is running: `cd backend && npm start`
- Check API URL in `api_constants.dart`
- For physical device, use your computer's IP address

### Build Errors
```bash
flutter clean
flutter pub get
flutter run
```

### Import Errors
- Make sure all files are saved
- Run `flutter pub get` again
- Check file paths are correct

## 📖 Documentation

- **Backend API**: http://localhost:3000/api/v1/docs
- **Flutter Docs**: https://flutter.dev/docs
- **Dio Docs**: https://pub.dev/packages/dio
- **GoRouter Docs**: https://pub.dev/packages/go_router

