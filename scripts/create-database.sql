-- Script tạo database và user cho EdTech MVP
-- Chạy script này với user postgres (superuser)

-- Tạo database
CREATE DATABASE edtech_db;

-- Tạo user
CREATE USER edtech_user WITH PASSWORD 'edtech_pass';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE edtech_db TO edtech_user;

-- Kết nối vào database edtech_db
\c edtech_db

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO edtech_user;

-- Thông báo
\echo 'Database edtech_db và user edtech_user đã được tạo thành công!'

