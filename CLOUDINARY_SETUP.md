# ☁️ Cloudinary Setup Guide

## Tại sao sử dụng Cloudinary?

- ✅ **CDN Global**: Video được serve từ CDN gần user nhất → nhanh hơn
- ✅ **Auto Compression**: Tự động nén video để tiết kiệm bandwidth
- ✅ **Format Optimization**: Tự động convert sang format tối ưu (MP4, WebM)
- ✅ **Thumbnail Generation**: Tự động tạo thumbnail cho video
- ✅ **Free Tier**: 25GB storage + 25GB bandwidth/month miễn phí
- ✅ **Scalable**: Tự động scale khi có nhiều user

---

## 📝 Setup Steps

### 1. Tạo Cloudinary Account

1. Truy cập: https://cloudinary.com/
2. Sign up (miễn phí)
3. Vào Dashboard → Settings → Account Details
4. Copy các thông tin:
   - Cloud Name
   - API Key
   - API Secret

### 2. Cấu hình Environment Variables

Thêm vào file `.env` của bạn:

```env
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

### 3. Restart Backend

```bash
npm run start:dev
```

Backend sẽ tự động detect Cloudinary config và sử dụng cloud storage.

---

## 🔄 Fallback Behavior

**Nếu Cloudinary KHÔNG được config:**
- ✅ Hệ thống tự động fallback về local storage (`uploads/` directory)
- ✅ Vẫn hoạt động bình thường, chỉ không có CDN và optimization

**Nếu Cloudinary ĐƯỢC config:**
- ✅ Video/images được upload lên Cloudinary
- ✅ Tự động compression và optimization
- ✅ Serve qua CDN (nhanh hơn)
- ✅ Tự động generate thumbnails

---

## 📊 So sánh Performance

### Local Storage (hiện tại)
- ❌ Video lưu trên server disk
- ❌ Serve trực tiếp từ server → chậm khi nhiều user
- ❌ Không có compression
- ❌ Server bandwidth bị quá tải

### Cloudinary (đề xuất)
- ✅ Video lưu trên Cloudinary cloud
- ✅ Serve qua CDN → nhanh cho mọi user
- ✅ Auto compression → tiết kiệm bandwidth
- ✅ Format optimization → tương thích tốt hơn

---

## 💰 Pricing

**Free Tier:**
- 25GB storage
- 25GB bandwidth/month
- ✅ Đủ cho MVP/Startup

**Paid Plans:**
- $99/month: 100GB storage + 100GB bandwidth
- Scale theo nhu cầu

---

## 🧪 Testing

1. Upload một video qua API
2. Check logs: `Video uploaded to Cloudinary: {public_id}`
3. Video URL sẽ là Cloudinary CDN URL (res.cloudinary.com)
4. Video sẽ load nhanh hơn và được optimize tự động

---

## 🔧 Troubleshooting

**Lỗi: "Cloudinary is not configured"**
→ Kiểm tra `.env` file có đủ 3 biến: CLOUDINARY_CLOUD_NAME, API_KEY, API_SECRET

**Video không upload được**
→ Check Cloudinary dashboard → Media Library → xem có lỗi gì không

**Fallback về local storage**
→ Normal behavior nếu Cloudinary không config. Hệ thống vẫn hoạt động.

---

## 📚 Tài liệu thêm

- Cloudinary Docs: https://cloudinary.com/documentation
- Video Upload: https://cloudinary.com/documentation/video_upload
- Video Transformation: https://cloudinary.com/documentation/video_transformation_reference

