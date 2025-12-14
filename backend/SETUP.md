# Setup Guide

## Prerequisites

- Node.js 18+ 
- PostgreSQL 15+ (hoặc dùng Docker)
- Redis (optional, cho caching)

## Quick Start với Docker

### 1. Start PostgreSQL và Redis

```bash
# Từ root directory của project
docker-compose up -d
```

### 2. Tạo file .env

```bash
cd backend
cp .env.example .env
```

Sửa file `.env` với thông tin từ docker-compose:

```env
DATABASE_URL=postgres://edtech_user:edtech_pass@localhost:5432/edtech_db
REDIS_URL=redis://localhost:6379
JWT_SECRET=your-secret-key-here
JWT_EXPIRES_IN=7d
GEMINI_API_KEY=your-gemini-api-key
PORT=3000
NODE_ENV=development
CORS_ORIGIN=http://localhost:3000
```

### 3. Cài đặt dependencies

```bash
npm install
```

### 4. Chạy seed data

```bash
npm run seed
```

### 5. Start server

```bash
npm start
```

Server sẽ chạy tại `http://localhost:3000`

## Setup PostgreSQL thủ công

### 1. Cài đặt PostgreSQL

**Windows:**
- Download từ https://www.postgresql.org/download/windows/
- Hoặc dùng Chocolatey: `choco install postgresql`

**Mac:**
```bash
brew install postgresql@15
brew services start postgresql@15
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

### 2. Tạo database và user

#### Option 1: Dùng script tự động (Windows)

```bash
cd backend
scripts\setup-database.bat
```

#### Option 2: Dùng pgAdmin (GUI - Dễ nhất)

1. Mở **pgAdmin 4** (thường có trong Start Menu sau khi cài PostgreSQL)
2. Kết nối vào PostgreSQL server (password bạn đã đặt khi cài)
3. Right-click vào **Databases** → **Create** → **Database**
   - Name: `edtech_db`
   - Owner: `postgres`
4. Right-click vào **Login/Group Roles** → **Create** → **Login/Group Role**
   - Name: `edtech_user`
   - Password: `edtech_pass`
   - Tab **Privileges**: Enable "Can login?"
5. Right-click vào database `edtech_db` → **Properties** → **Security**
   - Add user `edtech_user` với ALL privileges

#### Option 3: Dùng psql command line

```bash
# Tìm psql (thường ở C:\Program Files\PostgreSQL\[version]\bin\psql.exe)
# Hoặc thêm vào PATH

# Login vào PostgreSQL
psql -U postgres

# Chạy các lệnh sau:
CREATE DATABASE edtech_db;
CREATE USER edtech_user WITH PASSWORD 'edtech_pass';
GRANT ALL PRIVILEGES ON DATABASE edtech_db TO edtech_user;
\c edtech_db
GRANT ALL ON SCHEMA public TO edtech_user;
\q
```

#### Option 4: Dùng script SQL

```bash
cd backend
# Tìm psql và chạy:
"C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -f scripts\create-database.sql
```

### 3. Cập nhật .env

```env
DATABASE_URL=postgres://edtech_user:edtech_pass@localhost:5432/edtech_db
```

## Kiểm tra kết nối

```bash
# Test PostgreSQL connection
psql -U edtech_user -d edtech_db -h localhost

# Hoặc test từ Node.js
cd backend
npm start
# Nếu không có lỗi connection, database đã sẵn sàng
```

## Troubleshooting

### Lỗi: "password authentication failed"
- Kiểm tra username/password trong .env
- Kiểm tra file `pg_hba.conf` của PostgreSQL

### Lỗi: "database does not exist"
- Tạo database: `CREATE DATABASE edtech_db;`

### Lỗi: "connection refused"
- Kiểm tra PostgreSQL đang chạy: `pg_isready` hoặc `sudo systemctl status postgresql`
- Kiểm tra port 5432: `netstat -an | grep 5432`

### Reset database (development)

```bash
# Drop và tạo lại database
psql -U postgres -c "DROP DATABASE IF EXISTS edtech_db;"
psql -U postgres -c "CREATE DATABASE edtech_db;"

# Chạy lại seed
npm run seed
```

