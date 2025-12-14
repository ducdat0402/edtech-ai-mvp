# 📱 Flutter App - Quick Start

## ⚡ Quick Setup (Nếu đã có Flutter)

```bash
cd mobile
flutter create .
flutter pub get
flutter run
```

## 📋 Step-by-Step Setup

### 1. Install Flutter (Nếu chưa có)

**Windows:**
1. Download Flutter SDK từ https://flutter.dev/docs/get-started/install/windows
2. Extract vào `C:\src\flutter`
3. Add `C:\src\flutter\bin` vào PATH
4. Run `flutter doctor`

**macOS/Linux:**
```bash
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
flutter doctor
```

### 2. Create Flutter Project

```bash
cd mobile
flutter create .
```

### 3. Add Dependencies

Tạo file `pubspec.yaml` với dependencies cần thiết (xem SETUP.md)

### 4. Run App

```bash
flutter pub get
flutter run
```

## 🔗 Backend Connection

**Development:**
- Android Emulator: `http://10.0.2.2:3000/api/v1`
- iOS Simulator: `http://localhost:3000/api/v1`
- Physical Device: `http://YOUR_IP:3000/api/v1`

**Production:**
- Update `api_endpoints.dart` với production URL

## 📚 Next Steps

1. Setup API client
2. Implement authentication
3. Build dashboard
4. Implement learning flow

Xem `SETUP.md` để có hướng dẫn chi tiết hơn.

