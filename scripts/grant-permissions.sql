-- Script cấp quyền cho user ledat0402 trên database edtech_db
-- Chạy script này với user postgres (superuser)

-- Kết nối vào database edtech_db
\c edtech_db

-- Cấp quyền CREATE trên schema public
GRANT CREATE ON SCHEMA public TO ledat0402;

-- Cấp quyền USAGE trên schema public
GRANT USAGE ON SCHEMA public TO ledat0402;

-- Cấp quyền ALL trên schema public (để tạo tables, indexes, etc.)
GRANT ALL ON SCHEMA public TO ledat0402;

-- Cấp quyền trên tất cả tables hiện tại và tương lai
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ledat0402;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ledat0402;

-- Cấp quyền tạo extension (cho uuid_generate_v4)
ALTER USER ledat0402 WITH CREATEDB;

-- Thông báo
\echo 'Quyen da duoc cap thanh cong cho user ledat0402!'

