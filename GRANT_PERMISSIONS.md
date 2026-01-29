# Cấp quyền cho user ledat0402

## Vấn đề
Lỗi: `permission denied for schema public` - User `ledat0402` không có quyền tạo tables trong schema public.

## Giải pháp

### Cách 1: Dùng pgAdmin (Khuyến nghị)

1. Mở **pgAdmin 4**
2. Kết nối vào PostgreSQL server với user `postgres`
3. Mở **Query Tool** (Tools → Query Tool)
4. Chọn database `edtech_db` trong dropdown
5. Copy và paste script sau:

```sql
-- Cấp quyền trên schema public
GRANT CREATE ON SCHEMA public TO ledat0402;
GRANT USAGE ON SCHEMA public TO ledat0402;
GRANT ALL ON SCHEMA public TO ledat0402;

-- Cấp quyền trên tables hiện tại và tương lai
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ledat0402;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ledat0402;

-- Cấp quyền tạo extension
ALTER USER ledat0402 WITH CREATEDB;
```

6. Click **Execute** (F5)
7. Nếu thành công, bạn sẽ thấy: "Query returned successfully"

### Cách 2: Dùng psql command line

```bash
# Tìm psql (thường ở C:\Program Files\PostgreSQL\18\bin\psql.exe)
# Login với user postgres
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d edtech_db -f backend\scripts\grant-permissions.sql
```

### Cách 3: Chạy trực tiếp trong pgAdmin Query Tool

1. Mở pgAdmin → Query Tool
2. Đảm bảo đang ở database `edtech_db`
3. Paste và chạy:

```sql
GRANT CREATE ON SCHEMA public TO ledat0402;
GRANT USAGE ON SCHEMA public TO ledat0402;
GRANT ALL ON SCHEMA public TO ledat0402;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ledat0402;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ledat0402;
ALTER USER ledat0402 WITH CREATEDB;
```

## Sau khi cấp quyền

Chạy lại seed:
```bash
cd backend
npm run seed
```

Nếu thành công, bạn sẽ thấy:
```
✅ Seed completed!
   - Created 2 subjects (1 Explorer, 1 Scholar)
   - Created 1 learning node
   - Created 20 content items
   - Created 5 sample questions for placement test
```

