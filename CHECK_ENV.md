# Kiểm tra file .env

## Bước 1: Kiểm tra DATABASE_URL trong file .env

Mở file `backend/.env` và đảm bảo có dòng:

```env
DATABASE_URL=postgres://edtech_user:edtech_pass@localhost:5432/edtech_db
```

**Lưu ý quan trọng:**
- `edtech_pass` phải KHỚP với password bạn đã đặt khi tạo user trong pgAdmin
- Nếu bạn đặt password khác (ví dụ: `mypassword123`), thì sửa thành:
  ```env
  DATABASE_URL=postgres://edtech_user:mypassword123@localhost:5432/edtech_db
  ```

## Bước 2: Nếu quên password hoặc muốn đổi

### Cách 1: Đổi password trong pgAdmin
1. Mở pgAdmin
2. Servers → PostgreSQL → Login/Group Roles → Right-click `edtech_user` → Properties
3. Tab "Definition" → Đổi password → Save
4. Cập nhật lại trong file `.env`

### Cách 2: Tạo lại user với password mới
Trong pgAdmin → Query Tool, chạy:
```sql
DROP USER IF EXISTS edtech_user;
CREATE USER edtech_user WITH PASSWORD 'your_new_password';
GRANT ALL PRIVILEGES ON DATABASE edtech_db TO edtech_user;
\c edtech_db
GRANT ALL ON SCHEMA public TO edtech_user;
```

Sau đó cập nhật `.env` với password mới.

## Bước 3: Test lại

```bash
cd backend
npm run test:db
```

Nếu thành công, bạn sẽ thấy:
```
✅ Kết nối thành công!
✅ Database edtech_db tồn tại
✅ User edtech_user tồn tại
```

