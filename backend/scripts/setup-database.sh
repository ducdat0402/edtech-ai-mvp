#!/bin/bash

echo "========================================"
echo "Setup PostgreSQL Database for EdTech MVP"
echo "========================================"
echo ""

# Nhập password cho user postgres
echo "Nhập password cho user postgres:"
read -s POSTGRES_PASSWORD

# Tạo database và user
psql -U postgres -c "CREATE DATABASE edtech_db;" 2>/dev/null || echo "Database edtech_db đã tồn tại hoặc có lỗi"
psql -U postgres -c "CREATE USER edtech_user WITH PASSWORD 'edtech_pass';" 2>/dev/null || echo "User edtech_user đã tồn tại hoặc có lỗi"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE edtech_db TO edtech_user;"
psql -U postgres -d edtech_db -c "GRANT ALL ON SCHEMA public TO edtech_user;"

echo ""
echo "========================================"
echo "Database đã được tạo thành công!"
echo "========================================"

