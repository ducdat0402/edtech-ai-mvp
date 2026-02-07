# Hướng Dẫn Deploy Backend lên Vercel

Hướng dẫn chi tiết để deploy NestJS backend lên Vercel serverless platform.

## 📋 Mục Lục

1. [Yêu Cầu Tiên Quyết](#yêu-cầu-tiên-quyết)
2. [Chuẩn Bị](#chuẩn-bị)
3. [Cấu Hình Vercel](#cấu-hình-vercel)
4. [Thiết Lập Environment Variables](#thiết-lập-environment-variables)
5. [Deploy](#deploy)
6. [Khởi Tạo Database](#khởi-tạo-database)
7. [Kiểm Tra Deployment](#kiểm-tra-deployment)
8. [Troubleshooting](#troubleshooting)

---

## 🎯 Yêu Cầu Tiên Quyết

- Tài khoản Vercel (đăng ký tại [vercel.com](https://vercel.com))
- Tài khoản Neon DB (hoặc PostgreSQL database khác)
- Tài khoản Cloudinary (cho file uploads - **BẮT BUỘC** trên serverless)
- Git repository đã có code backend
- Node.js và npm đã cài đặt trên máy local

---

## 📦 Chuẩn Bị

### 1. Kiểm Tra Cấu Trúc Project

Đảm bảo project có các file sau:

```
backend/
├── api/
│   └── index.ts          # Vercel serverless entry point
├── vercel.json           # Vercel configuration
├── package.json          # Dependencies
├── tsconfig.json         # TypeScript config
└── src/                 # Source code
```

### 2. Kiểm Tra `vercel.json`

File `vercel.json` đã được cấu hình sẵn:

```json
{
  "version": 2,
  "builds": [
    {
      "src": "api/index.ts",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "api/index.ts"
    }
  ]
}
```

### 3. Kiểm Tra `api/index.ts`

File này đã được tạo và cấu hình để hoạt động với Vercel serverless functions.

---

## ⚙️ Cấu Hình Vercel

### Cách 1: Deploy qua Vercel Dashboard (Khuyến nghị)

1. **Đăng nhập Vercel**
   - Truy cập [vercel.com](https://vercel.com)
   - Đăng nhập bằng GitHub/GitLab/Bitbucket

2. **Import Project**
   - Click **"Add New..."** → **"Project"**
   - Chọn repository chứa code backend
   - Chọn **Root Directory**: `backend`
   - Framework Preset: **Other** hoặc **Node.js**

3. **Cấu Hình Build Settings**
   - Build Command: `npm run build`
   - Output Directory: `dist`
   - Install Command: `npm install`

### Cách 2: Deploy qua Vercel CLI

```bash
# Cài đặt Vercel CLI
npm i -g vercel

# Đăng nhập
vercel login

# Deploy (từ thư mục backend)
cd backend
vercel

# Deploy production
vercel --prod
```

---

## 🔐 Thiết Lập Environment Variables

**QUAN TRỌNG**: Tất cả environment variables phải được cấu hình trên Vercel Dashboard, không sử dụng file `.env` trên production.

### Bước 1: Truy Cập Environment Variables

1. Vào project trên Vercel Dashboard
2. Chọn tab **Settings** → **Environment Variables**

### Bước 2: Thêm Các Biến Môi Trường

Thêm các biến sau (click **Add** cho mỗi biến):

#### 🔴 BẮT BUỘC

| Tên Biến | Mô Tả | Ví Dụ |
|----------|-------|-------|
| `DATABASE_URL` | Connection string PostgreSQL (Neon DB) | `postgresql://user:pass@host/db?sslmode=require` |
| `JWT_SECRET` | Secret key cho JWT tokens (tối thiểu 32 ký tự) | `your-super-secret-jwt-key-change-this-in-production-min-32-chars` |
| `JWT_EXPIRES_IN` | Thời gian hết hạn JWT token | `7d` |
| `NODE_ENV` | Môi trường chạy | `production` |

#### 🟡 KHUYẾN NGHỊ (Cho File Uploads)

| Tên Biến | Mô Tả | Ví Dụ |
|----------|-------|-------|
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud name | `your-cloud-name` |
| `CLOUDINARY_API_KEY` | Cloudinary API key | `123456789012345` |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret | `abcdefghijklmnopqrstuvwxyz` |

**⚠️ LƯU Ý**: Trên serverless (Vercel), filesystem là **read-only**. Bạn **PHẢI** cấu hình Cloudinary để upload files. Nếu không, các API upload sẽ báo lỗi.

#### 🟢 TÙY CHỌN

| Tên Biến | Mô Tả | Mặc Định |
|----------|-------|-----------|
| `CORS_ORIGIN` | CORS allowed origins (dấu phẩy phân cách) | `*` (cho phép tất cả) |
| `OPENAI_API_KEY` | OpenAI API key cho AI features | Không có (AI features sẽ không hoạt động) |
| `PORT` | Port server (không cần trên Vercel) | `3000` |
| `ENABLE_SYNC` | Bật TypeORM synchronize để tạo tables (chỉ dùng lần đầu) | `false` |

### Bước 3: Chọn Environment

Khi thêm mỗi biến, chọn environment:
- ✅ **Production**
- ✅ **Preview** (cho pull requests)
- ✅ **Development** (nếu cần test local)

### Bước 4: Lấy Neon DB Connection String

1. Đăng nhập [Neon Console](https://console.neon.tech)
2. Chọn project → **Connection Details**
3. Copy **Connection string** (pooled) - có dạng:
   ```
   postgresql://user:password@ep-xxx-pooler.region.aws.neon.tech/dbname?sslmode=require
   ```
4. Paste vào `DATABASE_URL` trên Vercel

### Bước 5: Lấy Cloudinary Credentials

1. Đăng nhập [Cloudinary Dashboard](https://cloudinary.com/console)
2. Vào **Settings** → **Access Keys**
3. Copy:
   - **Cloud name**
   - **API Key**
   - **API Secret**
4. Thêm vào Vercel Environment Variables

---

## 🚀 Deploy

### Lần Đầu Deploy

1. **Thiết Lập Database Sync** (chỉ lần đầu):
   - Thêm biến: `ENABLE_SYNC` = `true`
   - Deploy để TypeORM tự động tạo tables

2. **Deploy Project**:
   - Nếu dùng Dashboard: Click **Deploy**
   - Nếu dùng CLI: `vercel --prod`

3. **Chờ Build Hoàn Tất**:
   - Xem logs trong Vercel Dashboard
   - Đảm bảo build thành công

4. **Tắt Database Sync** (sau khi tables đã tạo):
   - Xóa biến `ENABLE_SYNC` hoặc set = `false`
   - Redeploy để bảo mật

### Các Lần Deploy Sau

- **Tự động**: Mỗi khi push code lên `main` branch
- **Thủ công**: Click **Redeploy** trên Vercel Dashboard
- **CLI**: `vercel --prod`

---

## 🗄️ Khởi Tạo Database

### Cách 1: Dùng TypeORM Synchronize (Lần Đầu)

1. Thêm `ENABLE_SYNC=true` trên Vercel
2. Deploy
3. Sau khi deploy thành công, kiểm tra logs:
   ```
   query: CREATE TABLE "user" ...
   query: CREATE TABLE "subject" ...
   ...
   ```

4. **Tắt ngay**: Xóa `ENABLE_SYNC` hoặc set = `false`
5. Redeploy

### Cách 2: Dùng Migrations (Khuyến nghị cho Production)

```bash
# Tạo migration
npm run migration:generate -- -n InitialSchema

# Chạy migration
npm run migration:run
```

**Lưu ý**: Migrations cần chạy từ máy local hoặc CI/CD, không chạy trực tiếp trên Vercel.

---

## ✅ Kiểm Tra Deployment

### 1. Kiểm Tra Health Endpoint

```bash
curl https://your-project.vercel.app/api/v1/health
```

Kết quả mong đợi:
```json
{
  "status": "ok",
  "database": "connected"
}
```

### 2. Kiểm Tra Swagger Documentation

Truy cập: `https://your-project.vercel.app/api/v1/docs`

### 3. Test API Endpoints

```bash
# Test registration
curl -X POST https://your-project.vercel.app/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "name": "Test User"
  }'
```

### 4. Kiểm Tra Logs

- Vào Vercel Dashboard → **Deployments** → Chọn deployment → **Functions** → Xem logs
- Hoặc dùng CLI: `vercel logs`

---

## 🔧 Troubleshooting

### Lỗi: `TypeError: JwtStrategy requires a secret or key`

**Nguyên nhân**: Thiếu `JWT_SECRET` trong Environment Variables.

**Giải pháp**:
1. Vào Vercel → Settings → Environment Variables
2. Thêm `JWT_SECRET` với giá trị bất kỳ (tối thiểu 32 ký tự)
3. Redeploy

---

### Lỗi: `Error: ENOENT: no such file or directory, mkdir '/var/task/uploads'`

**Nguyên nhân**: Code đang cố ghi file vào local filesystem trên serverless (read-only).

**Giải pháp**:
1. Cấu hình Cloudinary:
   - Thêm `CLOUDINARY_CLOUD_NAME`
   - Thêm `CLOUDINARY_API_KEY`
   - Thêm `CLOUDINARY_API_SECRET`
2. Redeploy

**Lưu ý**: Code đã được cấu hình để tự động detect serverless environment và yêu cầu Cloudinary. Nếu vẫn lỗi, kiểm tra lại các biến Cloudinary.

---

### Lỗi: `Error [ERR_REQUIRE_ESM]: require() of ES Module`

**Nguyên nhân**: Package `uuid` version 13+ chỉ hỗ trợ ESM, nhưng NestJS dùng CommonJS.

**Giải pháp**: Đã được fix trong `package.json` - sử dụng `uuid@^9.0.0`. Nếu vẫn lỗi:
```bash
cd backend
npm install uuid@^9.0.0
git commit -am "Fix uuid version"
git push
```

---

### Lỗi: `500 Internal Server Error` khi register/login

**Nguyên nhân có thể**:
1. Database chưa có tables
2. Database connection string sai
3. Thiếu environment variables

**Giải pháp**:
1. Kiểm tra `DATABASE_URL` đúng chưa
2. Kiểm tra logs trên Vercel để xem lỗi cụ thể
3. Nếu chưa có tables:
   - Thêm `ENABLE_SYNC=true` (tạm thời)
   - Deploy
   - Sau khi tables tạo xong, xóa `ENABLE_SYNC`
   - Redeploy

---

### Lỗi: Database Connection Timeout

**Nguyên nhân**: Neon DB connection string không đúng hoặc firewall.

**Giải pháp**:
1. Kiểm tra connection string có `?sslmode=require` ở cuối
2. Dùng **pooled connection** (có `-pooler` trong URL)
3. Kiểm tra Neon DB có cho phép connections từ Vercel IPs

---

### Build Failed: TypeScript Errors

**Giải pháp**:
1. Test build local trước:
   ```bash
   cd backend
   npm run build
   ```
2. Fix các lỗi TypeScript
3. Commit và push lại

---

### Function Timeout

**Nguyên nhân**: Function chạy quá lâu (>10s cho Hobby plan, >60s cho Pro).

**Giải pháp**:
1. Tối ưu code (giảm database queries, cache)
2. Upgrade Vercel plan
3. Hoặc tách logic nặng ra background jobs

---

### CORS Errors

**Giải pháp**:
1. Thêm `CORS_ORIGIN` trên Vercel:
   ```
   https://your-frontend-domain.com,https://another-domain.com
   ```
2. Hoặc để `*` nếu cho phép tất cả (không khuyến nghị production)

---

## 📝 Checklist Trước Khi Deploy

- [ ] Đã thêm tất cả Environment Variables trên Vercel
- [ ] `DATABASE_URL` đúng và có `?sslmode=require`
- [ ] `JWT_SECRET` đã set (tối thiểu 32 ký tự)
- [ ] Cloudinary đã cấu hình (nếu cần upload files)
- [ ] `vercel.json` đã có trong project
- [ ] `api/index.ts` đã tồn tại
- [ ] Build thành công local (`npm run build`)
- [ ] Database đã có tables (hoặc set `ENABLE_SYNC=true` tạm thời)

---

## 🔗 Liên Kết Hữu Ích

- [Vercel Documentation](https://vercel.com/docs)
- [NestJS Deployment](https://docs.nestjs.com/faq/serverless)
- [Neon DB Documentation](https://neon.tech/docs)
- [Cloudinary Documentation](https://cloudinary.com/documentation)

---

## 📞 Hỗ Trợ

Nếu gặp vấn đề không có trong guide này:
1. Kiểm tra logs trên Vercel Dashboard
2. Kiểm tra logs local: `vercel logs`
3. Xem [Vercel Community](https://github.com/vercel/vercel/discussions)

---

**Chúc bạn deploy thành công! 🎉**
