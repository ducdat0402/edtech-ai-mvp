# 📐 Media Normalization - Tự Động Chuẩn Hóa Ảnh/Video

## 🎯 Mục đích

Hệ thống tự động chuẩn hóa mọi ảnh/video người dùng upload để đảm bảo:
- ✅ **Cùng kích thước chuẩn**: Tất cả media có cùng dimensions
- ✅ **Watermark tự động**: Chèn watermark để bảo vệ bản quyền
- ✅ **Khung mẫu**: Áp khung viền đồng nhất cho tất cả bài học
- ✅ **Không lệch lạc**: Toàn bộ bài học nhìn giống nhau, chuyên nghiệp

## ⚙️ Cấu hình

Thêm các biến môi trường sau vào file `.env`:

```env
# Media Normalization Settings
MEDIA_NORMALIZATION_ENABLED=true          # Bật/tắt chuẩn hóa (mặc định: true)
MEDIA_WATERMARK_ENABLED=true              # Bật/tắt watermark (mặc định: true)
MEDIA_WATERMARK_TEXT=EdTech AI            # Text watermark (mặc định: "EdTech AI")
```

## 📏 Kích thước chuẩn

### Ảnh (Images)
- **Width**: 1200px
- **Height**: 800px
- **Aspect Ratio**: 3:2
- **Crop Mode**: Fill (cắt để vừa khung, giữ tỷ lệ)

### Video
- **Width**: 1920px (Full HD)
- **Height**: 1080px (Full HD)
- **Aspect Ratio**: 16:9
- **Format**: MP4 (H.264 codec)
- **Crop Mode**: Fill (cắt để vừa khung, giữ tỷ lệ)

## 🎨 Tính năng chuẩn hóa

### 1. Resize & Crop
- Tự động resize và crop về kích thước chuẩn
- Giữ tỷ lệ khung hình, crop phần thừa
- Center gravity (cắt từ giữa)

### 2. Watermark
- **Vị trí**: Góc dưới bên phải (south_east)
- **Màu**: Trắng (#FFFFFF)
- **Opacity**: 60% (ảnh), 70% (video)
- **Font**: Arial, Bold
- **Size**: 30px (ảnh), 40px (video)

### 3. Template Frame
- **Border**: 3px solid blue (#4A90E2)
- **Border Radius**: 8px (bo góc)
- **Áp dụng**: Chỉ cho ảnh (video dùng CSS frame)

## 🔄 Cách hoạt động

1. **User upload ảnh/video** → File được gửi lên backend
2. **Backend nhận file** → `FileStorageService.saveImage()` hoặc `saveVideo()`
3. **Cloudinary upload** → `CloudinaryStorageService.uploadImage()` hoặc `uploadVideo()`
4. **Tự động chuẩn hóa** → `MediaNormalizationService` áp dụng transformations:
   - Resize/crop về kích thước chuẩn
   - Thêm watermark
   - Áp khung viền (ảnh)
5. **Lưu kết quả** → File đã chuẩn hóa được lưu trên Cloudinary
6. **Trả về URL** → Frontend nhận URL của file đã chuẩn hóa

## 📝 Ví dụ

### Upload ảnh 2000x1500px
```
Input: 2000x1500px (4:3 ratio)
↓
Normalization:
  - Resize & crop to 1200x800px (3:2 ratio)
  - Add watermark "EdTech AI" (bottom right)
  - Add blue border frame
↓
Output: 1200x800px với watermark và frame
```

### Upload video 1280x720px
```
Input: 1280x720px (16:9 ratio)
↓
Normalization:
  - Resize & crop to 1920x1080px (Full HD)
  - Add watermark "EdTech AI" (bottom right)
  - Convert to MP4 (H.264)
↓
Output: 1920x1080px MP4 với watermark
```

## 🎛️ Tùy chỉnh

### Thay đổi kích thước chuẩn
Sửa trong `media-normalization.service.ts`:
```typescript
private readonly STANDARD_IMAGE_WIDTH = 1200;  // Thay đổi ở đây
private readonly STANDARD_IMAGE_HEIGHT = 800;  // Thay đổi ở đây
private readonly STANDARD_VIDEO_WIDTH = 1920;  // Thay đổi ở đây
private readonly STANDARD_VIDEO_HEIGHT = 1080; // Thay đổi ở đây
```

### Thay đổi watermark
Sửa trong `.env`:
```env
MEDIA_WATERMARK_TEXT=Your Brand Name
MEDIA_WATERMARK_ENABLED=true
```

### Tắt chuẩn hóa
```env
MEDIA_NORMALIZATION_ENABLED=false
```

## ⚠️ Lưu ý

1. **Cloudinary Required**: Tính năng này chỉ hoạt động khi Cloudinary được cấu hình
2. **Processing Time**: Chuẩn hóa có thể mất thêm vài giây khi upload
3. **Storage**: File gốc và file đã chuẩn hóa đều được lưu trên Cloudinary
4. **Quality**: Cloudinary tự động optimize chất lượng để cân bằng giữa chất lượng và kích thước file

## 🚀 Sử dụng

Tính năng tự động hoạt động khi:
- User upload ảnh qua API `/content-edits/upload/image`
- User upload video qua API `/content-edits/upload/video`

Không cần thay đổi code frontend, mọi thứ tự động!

