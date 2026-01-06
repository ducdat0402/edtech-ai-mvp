# 🎥 Video Storage Architecture - Tối ưu cho hệ thống đóng góp video

## 📊 Tình trạng hiện tại

**Cách lưu trữ hiện tại:**
- Video được lưu trực tiếp trên server: `backend/uploads/videos/`
- Serve static files qua NestJS: `app.useStaticAssets()`
- Max file size: 100MB
- Không có CDN, không có compression, không có transcoding

**Vấn đề khi scale:**
- ❌ Server disk space sẽ hết nhanh
- ❌ Bandwidth server sẽ bị quá tải khi nhiều user xem cùng lúc
- ❌ Không có video compression/optimization
- ❌ Không hỗ trợ adaptive streaming (HLS/DASH)
- ❌ Khó backup và disaster recovery
- ❌ Không scale được khi deploy multiple servers

---

## 🎯 Giải pháp đề xuất

### **Option 1: AWS S3 + CloudFront CDN** (Recommended cho production)

**Ưu điểm:**
- ✅ Scalable và reliable
- ✅ CDN global distribution (nhanh cho user ở mọi nơi)
- ✅ Pay-as-you-go pricing
- ✅ Built-in redundancy và backup
- ✅ Có thể tích hợp với AWS Lambda cho video processing

**Nhược điểm:**
- ⚠️ Cần setup AWS account
- ⚠️ Cần config IAM và permissions
- ⚠️ Chi phí tăng theo storage và bandwidth

**Chi phí ước tính:**
- Storage: ~$0.023/GB/month
- Data transfer out: ~$0.09/GB (first 10TB)
- CloudFront: ~$0.085/GB (first 10TB)

---

### **Option 2: Cloudinary** (Recommended cho MVP/Startup)

**Ưu điểm:**
- ✅ Dễ setup và integrate
- ✅ Built-in video processing (transcoding, compression, thumbnails)
- ✅ Automatic format optimization (WebM, MP4)
- ✅ Adaptive streaming support
- ✅ Free tier: 25GB storage, 25GB bandwidth/month
- ✅ CDN included

**Nhược điểm:**
- ⚠️ Chi phí cao hơn khi scale lớn
- ⚠️ Vendor lock-in

**Chi phí ước tính:**
- Free tier: 25GB storage + 25GB bandwidth
- Paid: $99/month cho 100GB storage + 100GB bandwidth

---

### **Option 3: Google Cloud Storage + Cloud CDN**

**Ưu điểm:**
- ✅ Tương tự AWS S3
- ✅ Tích hợp tốt với Google Cloud ecosystem
- ✅ Competitive pricing

**Nhược điểm:**
- ⚠️ Cần setup Google Cloud account
- ⚠️ Phức tạp hơn Cloudinary

---

### **Option 4: Azure Blob Storage + Azure CDN**

**Ưu điểm:**
- ✅ Tích hợp tốt với Microsoft ecosystem
- ✅ Good pricing cho enterprise

**Nhược điểm:**
- ⚠️ Ít phổ biến hơn AWS/GCS

---

## 🏗️ Kiến trúc đề xuất (Cloudinary)

```
User Upload Video
    ↓
Backend API (NestJS)
    ↓
Cloudinary Upload API
    ↓
Cloudinary Processing:
  - Video compression
  - Format conversion (MP4, WebM)
  - Thumbnail generation
  - Adaptive streaming (HLS)
    ↓
Cloudinary CDN
    ↓
Users watch video (fast, optimized)
```

**Database Schema:**
```typescript
ContentEdit {
  media: {
    videoUrl: string;        // Cloudinary URL
    thumbnailUrl?: string;   // Auto-generated thumbnail
    videoId: string;         // Cloudinary public_id
    format: string;          // mp4, webm
    duration?: number;       // seconds
    size?: number;           // bytes
  }
}
```

---

## 📝 Implementation Plan

### Phase 1: Setup Cloudinary (Quick Win)
1. ✅ Tạo Cloudinary account
2. ✅ Install `@cloudinary/url-gen` và `cloudinary`
3. ✅ Update `FileStorageService` để upload lên Cloudinary
4. ✅ Update database schema để lưu Cloudinary metadata
5. ✅ Test upload và playback

### Phase 2: Video Optimization
1. ✅ Auto-compress videos khi upload
2. ✅ Generate thumbnails tự động
3. ✅ Support multiple formats (MP4, WebM)
4. ✅ Adaptive streaming (HLS) cho mobile

### Phase 3: Advanced Features
1. ✅ Video transcoding queue
2. ✅ Progress tracking cho upload lớn
3. ✅ Video analytics (views, watch time)
4. ✅ Content moderation (AI-based)

---

## 🔧 Code Changes Required

### 1. Install Dependencies
```bash
npm install cloudinary @cloudinary/url-gen
```

### 2. Environment Variables
```env
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

### 3. Update FileStorageService
- Replace local file storage với Cloudinary upload
- Return Cloudinary URL thay vì local path
- Handle video processing options

### 4. Update Frontend
- Video URLs sẽ là Cloudinary CDN URLs
- Có thể sử dụng Cloudinary video player cho better performance

---

## 💰 Cost Estimation (1000 videos/month)

**Scenario:**
- Average video size: 50MB
- Total storage: 50GB
- Monthly bandwidth: 500GB (10 views/video average)

**Cloudinary:**
- Storage: $0 (within free tier)
- Bandwidth: $0 (within free tier)
- **Total: $0/month** (free tier)

**AWS S3 + CloudFront:**
- Storage: 50GB × $0.023 = $1.15/month
- Bandwidth: 500GB × $0.09 = $45/month
- CloudFront: 500GB × $0.085 = $42.50/month
- **Total: ~$88.65/month**

**Khi scale lên 10,000 videos:**
- Cloudinary: ~$99/month (paid plan)
- AWS: ~$886/month

---

## 🚀 Recommendation

**Cho MVP/Startup:** 
→ **Cloudinary** (dễ setup, free tier tốt, built-in features)

**Cho Production Scale:**
→ **AWS S3 + CloudFront** (cost-effective khi scale lớn, more control)

**Hybrid Approach:**
→ Start với Cloudinary, migrate sang AWS khi scale lớn

---

## 📚 Next Steps

1. ✅ Implement Cloudinary integration
2. ✅ Add video compression
3. ✅ Add thumbnail generation
4. ✅ Update frontend để sử dụng Cloudinary URLs
5. ✅ Monitor costs và performance
6. ✅ Plan migration strategy khi scale

