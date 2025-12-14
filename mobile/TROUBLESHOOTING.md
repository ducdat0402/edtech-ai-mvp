# 🔧 Troubleshooting Guide

## ❌ Lỗi Connection Timeout

### Triệu chứng:
- Lỗi: `DioException [connection error]: The semaphore timeout period has expired`
- Không thể kết nối với backend từ Flutter app

### Giải pháp:

#### 1. Kiểm tra Backend đang chạy
```bash
cd backend
npm start
```

Bạn sẽ thấy:
```
🚀 Server running on http://0.0.0.0:3000/api/v1
```

#### 2. Kiểm tra Backend accessible
```bash
# Test từ máy tính
curl http://localhost:3000/api/v1/health

# Nếu OK, sẽ thấy:
# {"status":"ok","timestamp":"...","database":"connected"}
```

#### 3. Kiểm tra API URL trong Flutter

**Android Emulator:**
```dart
// mobile/lib/core/constants/api_constants.dart
static const String baseUrl = 'http://10.0.2.2:3000/api/v1';
```

**iOS Simulator:**
```dart
static const String baseUrl = 'http://localhost:3000/api/v1';
```

**Physical Device:**
```dart
// Tìm IP của máy tính:
// Windows: ipconfig
// Mac/Linux: ifconfig
static const String baseUrl = 'http://192.168.1.100:3000/api/v1'; // Thay bằng IP thật
```

#### 4. Kiểm tra Firewall

Windows Firewall có thể chặn port 3000:
- Tạm thời tắt firewall để test
- Hoặc thêm exception cho port 3000

#### 5. Restart Backend với 0.0.0.0

Backend đã được config để listen trên `0.0.0.0` (tất cả interfaces), nên có thể access từ network.

**Restart backend:**
```bash
cd backend
# Stop backend (Ctrl+C)
npm start
```

#### 6. Test từ Browser trong Emulator

Mở browser trong Android emulator và truy cập:
```
http://10.0.2.2:3000/api/v1/health
```

Nếu không load được → Vấn đề network/firewall.

---

## ❌ Lỗi Favicon.ico (404)

### Triệu chứng:
```
NotFoundException: Cannot GET /favicon.ico
```

### Giải pháp:
✅ **Đã fix!** Backend giờ sẽ ignore favicon requests và không log error.

---

## ❌ Lỗi 401 Unauthorized

### Triệu chứng:
- Login thành công nhưng các API khác trả về 401

### Giải pháp:

1. **Kiểm tra token được lưu:**
   - Token được lưu trong secure storage sau khi login
   - Check Flutter logs xem token có được gửi trong headers không

2. **Kiểm tra token format:**
   - Token phải bắt đầu với `Bearer `
   - Check trong `api_client.dart` line 30

3. **Test token với Postman:**
   ```bash
   # Lấy token từ login response
   # Test với:
   curl -X GET http://localhost:3000/api/v1/dashboard \
     -H "Authorization: Bearer YOUR_TOKEN"
   ```

---

## ❌ Lỗi CORS

### Triệu chứng:
- Browser console: `CORS policy: No 'Access-Control-Allow-Origin' header`

### Giải pháp:
✅ **Đã fix!** Backend CORS đã được config:
```typescript
app.enableCors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true,
});
```

---

## 🔍 Debug Tips

### 1. Enable API Logging

API client đã có logging trong debug mode. Bạn sẽ thấy:
- Request URL, headers, body
- Response status, body
- Errors

### 2. Check Backend Logs

Khi Flutter app gọi API, check backend terminal:
- Request có đến backend không?
- Response status code là gì?
- Có error gì không?

### 3. Test API với Postman/cURL

Test API trực tiếp trước khi test từ Flutter:
```bash
# Register
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123!@#","fullName":"Test"}'

# Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123!@#"}'
```

### 4. Check Network trong Flutter DevTools

- Mở Flutter DevTools
- Xem Network tab
- Check request/response details

---

## ✅ Quick Checklist

Trước khi test Flutter app:

- [ ] Backend đang chạy (`npm start`)
- [ ] Backend accessible từ browser (`http://localhost:3000/api/v1/health`)
- [ ] API URL đúng trong `api_constants.dart`
- [ ] Firewall không chặn port 3000
- [ ] Emulator có internet connection
- [ ] Backend listen trên `0.0.0.0` (đã fix)

---

## 📞 Still Having Issues?

1. **Check Flutter logs:**
   ```bash
   flutter run -v
   ```

2. **Check Backend logs:**
   - Xem terminal nơi chạy `npm start`
   - Check có request đến không

3. **Test với Postman:**
   - Import API từ Swagger: `http://localhost:3000/api/v1/docs`
   - Test register/login endpoints

4. **Check Network:**
   - Emulator có internet không?
   - Có proxy/VPN nào chặn không?

