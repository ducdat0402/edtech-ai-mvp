# 🔄 Restart Backend Guide

## ❌ Lỗi: Port 3000 đã được sử dụng

Nếu gặp lỗi `EADDRINUSE: address already in use 0.0.0.0:3000`, có nghĩa là có process khác đang dùng port 3000.

## ✅ Giải pháp nhanh

### Windows (CMD/PowerShell):
```bash
# Tìm process đang dùng port 3000
netstat -ano | findstr :3000

# Kill process (thay PID bằng số từ lệnh trên)
taskkill /F /PID <PID>

# Hoặc dùng script tự động:
KILL_PORT.bat
```

### Git Bash / Linux:
```bash
# Tìm và kill process
./KILL_PORT.sh

# Hoặc thủ công:
PID=$(netstat -ano | grep :3000 | grep LISTENING | awk '{print $5}' | head -1)
taskkill //F //PID $PID  # Windows
# hoặc
kill -9 $PID  # Linux
```

## 🚀 Start Backend

Sau khi port đã free:
```bash
cd backend
npm start
```

Bạn sẽ thấy:
```
🚀 Server running on http://0.0.0.0:3000/api/v1
📚 Swagger docs available at http://localhost:3000/api/v1/docs
```

## 🔍 Kiểm tra Backend đang chạy

```bash
# Test health endpoint
curl http://localhost:3000/api/v1/health

# Hoặc mở browser:
# http://localhost:3000/api/v1/health
```

## 💡 Tips

1. **Luôn check port trước khi start:**
   ```bash
   netstat -ano | findstr :3000
   ```

2. **Nếu có nhiều Node processes:**
   ```bash
   # Kill tất cả Node processes (cẩn thận!)
   taskkill /F /IM node.exe
   ```

3. **Dùng script tự động:**
   - Windows: `KILL_PORT.bat`
   - Bash: `chmod +x KILL_PORT.sh && ./KILL_PORT.sh`

