# 🔧 Cloudinary Debug Guide

## Vấn đề: Video không được upload lên Cloudinary

Nếu bạn đã cấu hình Cloudinary nhưng video vẫn được lưu local thay vì upload lên Cloudinary, hãy làm theo các bước sau:

## ✅ Bước 1: Kiểm tra cấu hình

Chạy script kiểm tra:

```bash
cd backend
npm run check-cloudinary
```

Nếu thấy "✅ All Cloudinary environment variables are set" → Cấu hình đúng.

## ✅ Bước 2: Restart Backend

**QUAN TRỌNG**: Backend cần được restart sau khi thêm/sửa environment variables.

```bash
# Dừng backend hiện tại (Ctrl+C)
# Sau đó restart:
cd backend
npm run start:dev
```

Khi backend khởi động, bạn sẽ thấy log:
- ✅ `Cloudinary configured successfully (Cloud Name: edtech)` → Cloudinary đã được kích hoạt
- ⚠️ `Cloudinary not configured` → Cần kiểm tra lại .env

## ✅ Bước 3: Kiểm tra logs khi upload video

Khi upload video, backend sẽ log:

**Nếu Cloudinary hoạt động:**
```
🔍 Attempting to upload video to Cloudinary (size: X.XX MB, type: video/mp4)
✅ Video uploaded to Cloudinary successfully: content-edits/videos/xxx (X.XX MB)
   Cloudinary URL: https://res.cloudinary.com/edtech/video/upload/...
```

**Nếu Cloudinary không hoạt động (fallback về local):**
```
⚠️ Cloudinary not configured, using local storage for video upload
💾 Saving video to local storage: video.mp4 (X.XX MB)
✅ Video saved to local storage: /uploads/videos/xxx.mp4
```

**Nếu có lỗi Cloudinary:**
```
❌ Cloudinary upload failed: [error message]
⚠️ Falling back to local storage
```

## ✅ Bước 4: Kiểm tra URL video trong database

Video URL từ Cloudinary sẽ có format:
```
https://res.cloudinary.com/{cloud_name}/video/upload/...
```

Video URL từ local storage sẽ có format:
```
/uploads/videos/{filename}.mp4
```

## 🔍 Troubleshooting

### 1. Backend không log "Cloudinary configured successfully"

**Nguyên nhân**: Environment variables chưa được load đúng.

**Giải pháp**:
- Kiểm tra file `.env` có đúng format không (không có dấu cách thừa)
- Đảm bảo `.env` nằm trong thư mục `backend/`
- Restart backend

### 2. Log "Cloudinary upload failed"

**Nguyên nhân**: Lỗi khi upload lên Cloudinary (API key sai, network issue, etc.)

**Giải pháp**:
- Kiểm tra Cloudinary credentials trong dashboard
- Kiểm tra network connection
- Xem chi tiết lỗi trong logs

### 3. Video vẫn lưu local dù Cloudinary đã config

**Nguyên nhân**: Backend chưa được restart sau khi thêm env variables.

**Giải pháp**:
- **Restart backend ngay lập tức**
- Kiểm tra logs khi khởi động để xác nhận Cloudinary đã được config

## 📝 Checklist

- [ ] Đã thêm 3 biến môi trường vào `.env`:
  - `CLOUDINARY_CLOUD_NAME`
  - `CLOUDINARY_API_KEY`
  - `CLOUDINARY_API_SECRET`
- [ ] Đã restart backend sau khi thêm env variables
- [ ] Backend log hiển thị "Cloudinary configured successfully"
- [ ] Khi upload video, log hiển thị "Video uploaded to Cloudinary"
- [ ] Video URL trong database là Cloudinary URL (res.cloudinary.com)

## 🚀 Sau khi fix

1. Upload một video mới
2. Kiểm tra logs: `✅ Video uploaded to Cloudinary successfully`
3. Kiểm tra Cloudinary dashboard → Media Library → sẽ thấy video mới
4. Video URL trong database sẽ là Cloudinary CDN URL

