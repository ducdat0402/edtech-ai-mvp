# 🔧 Fix Connection Timeout Issue

## ❌ Vấn đề: Connection timeout khi đăng ký

Lỗi: `The semaphore timeout period has expired` khi Flutter app cố kết nối đến backend.

## ✅ Giải pháp

### Bước 1: Kiểm tra Backend đang chạy

```bash
# Test từ máy tính
curl http://localhost:3000/api/v1/health

# Nếu OK, sẽ thấy:
# {"status":"ok","database":"connected"}
```

### Bước 2: Đổi API URL trong Flutter

**Vấn đề:** `10.0.2.2` có thể không hoạt động với một số emulator.

**Giải pháp:** Dùng IP thật của máy tính.

1. **Tìm IP của máy tính:**
   ```bash
   # Windows
   ipconfig
   # Tìm "IPv4 Address" (ví dụ: 192.168.1.100)
   
   # Mac/Linux
   ifconfig
   # Tìm inet address
   ```

2. **Đổi API URL trong Flutter:**
   
   Mở file: `mobile/lib/core/config/api_config.dart`
   
   ```dart
   // Thay YOUR_IP bằng IP thật của máy
   static const String baseUrl = 'http://YOUR_IP:3000/api/v1';
   
   // Ví dụ:
   static const String baseUrl = 'http://192.168.1.100:3000/api/v1';
   ```

3. **Hot restart Flutter app:**
   - Stop app (Ctrl+C)
   - Run lại: `flutter run`

### Bước 3: Kiểm tra Firewall

Windows Firewall có thể chặn port 3000:

1. Mở **Windows Defender Firewall**
2. **Advanced settings**
3. **Inbound Rules** → **New Rule**
4. Chọn **Port** → **TCP** → **3000**
5. Allow connection
6. Apply cho tất cả profiles

### Bước 4: Test từ Emulator Browser

Mở browser trong Android emulator và truy cập:
```
http://YOUR_IP:3000/api/v1/health
```

Nếu không load được → Vấn đề network/firewall.

---

## 🔄 Các Options API URL

### Option 1: Android Emulator (10.0.2.2)
```dart
static const String baseUrl = 'http://10.0.2.2:3000/api/v1';
```
**Khi nào dùng:** Android emulator (mặc định)

### Option 2: iOS Simulator
```dart
static const String baseUrl = 'http://localhost:3000/api/v1';
```
**Khi nào dùng:** iOS Simulator

### Option 3: Physical Device (IP thật)
```dart
static const String baseUrl = 'http://192.168.1.100:3000/api/v1';
```
**Khi nào dùng:** 
- Physical device
- Emulator không kết nối được với 10.0.2.2

### Option 4: Localhost (nếu dùng port forwarding)
```dart
static const String baseUrl = 'http://localhost:3000/api/v1';
```
**Khi nào dùng:** Nếu đã setup port forwarding

---

## 🧪 Test Connection

### Test 1: Từ máy tính
```bash
curl http://localhost:3000/api/v1/health
```

### Test 2: Từ emulator browser
```
http://YOUR_IP:3000/api/v1/health
```

### Test 3: Từ Flutter app
- Mở app
- Thử Register
- Check logs trong Flutter console

---

## 📝 Quick Fix Checklist

- [ ] Backend đang chạy (`npm start`)
- [ ] Backend accessible từ máy tính (`curl localhost:3000/api/v1/health`)
- [ ] Đã đổi API URL trong `api_config.dart` thành IP thật
- [ ] Firewall không chặn port 3000
- [ ] Hot restart Flutter app
- [ ] Test từ emulator browser

---

## 💡 Tips

1. **Luôn dùng IP thật** nếu `10.0.2.2` không hoạt động
2. **Check firewall** nếu vẫn timeout
3. **Test từ browser** trong emulator trước
4. **Check backend logs** khi Flutter app gọi API

---

## 🐛 Still Having Issues?

1. **Check backend logs:**
   - Có request đến không?
   - Có error gì không?

2. **Check Flutter logs:**
   - Request có được gửi không?
   - Error message là gì?

3. **Test với Postman:**
   ```bash
   curl -X POST http://YOUR_IP:3000/api/v1/auth/register \
     -H "Content-Type: application/json" \
     -d '{"email":"test@test.com","password":"Test123!@#","fullName":"Test"}'
   ```

