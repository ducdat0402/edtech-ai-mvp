# 👤 Hướng Dẫn Tạo Tài Khoản Admin

## 🎯 Tổng Quan

Hệ thống đã được tích hợp phân quyền admin. Admin có thể:
- ✅ Approve/Reject các community edits
- ✅ Xem danh sách pending edits
- ✅ Quản lý nội dung

---

## 📋 Cách 1: Tạo Admin User bằng Script (Khuyến nghị)

### Bước 1: Chạy script tạo admin

```bash
cd backend
npm run create-admin
```

**Mặc định sẽ tạo:**
- Email: `admin@edtech.com`
- Password: `admin123`
- Full Name: `Admin User`

### Bước 2: Tạo admin với thông tin tùy chỉnh

```bash
npm run create-admin <email> <password> <fullName>
```

**Ví dụ:**
```bash
npm run create-admin admin@example.com MySecurePass123 "Admin Name"
```

### Bước 3: Nếu user đã tồn tại

Script sẽ tự động update user đó thành admin role.

---

## 📋 Cách 2: Tạo Admin trực tiếp trong Database

### Bước 1: Mở pgAdmin hoặc psql

### Bước 2: Tìm user bạn muốn làm admin

```sql
SELECT id, email, "fullName", role FROM users;
```

### Bước 3: Update role thành admin

```sql
UPDATE users 
SET role = 'admin' 
WHERE email = 'your-email@example.com';
```

**Hoặc tạo admin mới:**

```sql
-- Hash password trước (dùng bcrypt với salt rounds = 10)
-- Password: admin123 → Hash: $2b$10$...
-- Hoặc dùng script để hash

INSERT INTO users (id, email, password, "fullName", role, "currentStreak", "totalXP", "createdAt", "updatedAt")
VALUES (
  gen_random_uuid(),
  'admin@edtech.com',
  '$2b$10$YourHashedPasswordHere',  -- Cần hash password trước
  'Admin User',
  'admin',
  0,
  0,
  NOW(),
  NOW()
);
```

---

## 📋 Cách 3: Tạo Admin qua API (Nếu có endpoint)

**Lưu ý:** Hiện tại chưa có endpoint public để tạo admin. Chỉ có thể dùng script hoặc database.

---

## 🔐 Đăng Nhập với Admin Account

### Bước 1: Login như user thường

```bash
POST /api/v1/auth/login
{
  "email": "admin@edtech.com",
  "password": "admin123"
}
```

### Bước 2: Nhận JWT token

Response:
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "...",
    "email": "admin@edtech.com",
    "fullName": "Admin User"
  }
}
```

### Bước 3: Sử dụng token để gọi Admin APIs

**Approve edit:**
```bash
PUT /api/v1/content-edits/:id/approve
Headers:
  Authorization: Bearer <token>
```

**Reject edit:**
```bash
PUT /api/v1/content-edits/:id/reject
Headers:
  Authorization: Bearer <token>
```

**Xem pending edits:**
```bash
GET /api/v1/content-edits/pending/list
Headers:
  Authorization: Bearer <token>
```

---

## ✅ Kiểm Tra Admin Role

### Cách 1: Check trong Database

```sql
SELECT email, role FROM users WHERE role = 'admin';
```

### Cách 2: Check qua API (nếu có endpoint)

Hoặc login và thử gọi admin endpoint, nếu không phải admin sẽ nhận lỗi:
```json
{
  "statusCode": 403,
  "message": "Admin access required"
}
```

---

## 🛡️ Admin Guard

Các endpoints được bảo vệ bởi `AdminGuard`:

1. `PUT /content-edits/:id/approve` - Approve edit
2. `PUT /content-edits/:id/reject` - Reject edit  
3. `GET /content-edits/pending/list` - Xem pending edits

**AdminGuard sẽ:**
- Check user đã authenticated (JWT token hợp lệ)
- Check user có role = 'admin'
- Nếu không phải admin → Throw `ForbiddenException`

---

## 🔄 Migration Database

Nếu database đã có users, cần migration để thêm column `role`:

```sql
-- Thêm column role nếu chưa có
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS role VARCHAR DEFAULT 'user';

-- Set tất cả users hiện tại thành 'user'
UPDATE users SET role = 'user' WHERE role IS NULL;
```

---

## 📝 Ví Dụ Sử Dụng

### Scenario: Admin approve một edit

1. **User submit edit:**
   ```bash
   POST /api/v1/content-edits/content/:contentId/submit
   → Status: PENDING
   ```

2. **Admin login:**
   ```bash
   POST /api/v1/auth/login
   → Nhận token
   ```

3. **Admin xem pending edits:**
   ```bash
   GET /api/v1/content-edits/pending/list
   Headers: Authorization: Bearer <admin-token>
   ```

4. **Admin approve:**
   ```bash
   PUT /api/v1/content-edits/:editId/approve
   Headers: Authorization: Bearer <admin-token>
   → Status: APPROVED
   → Media được thêm vào ContentItem
   ```

---

## ⚠️ Lưu Ý Bảo Mật

1. **Đổi password mặc định ngay sau khi tạo admin**
2. **Không commit admin credentials vào git**
3. **Sử dụng environment variables cho admin email trong production**
4. **Giới hạn số lượng admin accounts**
5. **Log tất cả admin actions để audit**

---

## 🚀 Quick Start

```bash
# 1. Tạo admin với thông tin mặc định
cd backend
npm run create-admin

# 2. Login với admin account
# Email: admin@edtech.com
# Password: admin123

# 3. Sử dụng token để approve/reject edits
```

---

## 📚 Related Files

- `backend/src/users/entities/user.entity.ts` - User entity với role field
- `backend/src/auth/guards/admin.guard.ts` - Admin guard
- `backend/scripts/create-admin.ts` - Script tạo admin
- `backend/src/content-edits/content-edits.controller.ts` - Admin endpoints

