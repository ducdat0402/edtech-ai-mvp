# 🚀 Quick Start Backend

## ⚡ Cách nhanh nhất để start backend

### Windows:
```bash
cd backend
start.bat
```

### Linux/Mac/Git Bash:
```bash
cd backend
./start.sh
```

Script sẽ tự động:
1. ✅ Check port 3000
2. ✅ Kill process cũ nếu có
3. ✅ Start backend mới

---

## 🔧 Nếu gặp lỗi "Port already in use"

### Cách 1: Dùng script tự động (Khuyến nghị)
```bash
# Windows
cd backend
start.bat

# Linux/Mac/Bash
cd backend
./start.sh
```

### Cách 2: Kill thủ công

**Windows:**
```bash
# Tìm process
netstat -ano | findstr :3000

# Kill process (thay PID bằng số tìm được)
taskkill /F /PID <PID>
```

**Linux/Mac:**
```bash
# Tìm và kill
lsof -ti:3000 | xargs kill -9
```

### Cách 3: Đổi port

Nếu không thể kill process, đổi port trong `.env`:
```env
PORT=3001
```

Sau đó update Flutter app API URL:
```dart
// mobile/lib/core/constants/api_constants.dart
static const String baseUrl = 'http://10.0.2.2:3001/api/v1';
```

---

## ✅ Kiểm tra Backend đang chạy

```bash
# Test health endpoint
curl http://localhost:3000/api/v1/health

# Hoặc mở browser:
# http://localhost:3000/api/v1/health
# http://localhost:3000/api/v1/docs (Swagger)
```

---

## 📝 Lưu ý

- **Luôn dùng `start.bat` hoặc `start.sh`** để tránh lỗi port
- Nếu có nhiều terminal đang chạy backend, chỉ giữ 1 cái
- Check port trước khi start: `netstat -ano | findstr :3000`
