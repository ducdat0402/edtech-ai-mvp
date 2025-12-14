// Quick test script để kiểm tra kết nối database
require('dotenv').config();
const { Client } = require('pg');

async function testConnection() {
  // Lấy DATABASE_URL từ env, nếu không có thì dùng default với user mới
  const dbUrl = process.env.DATABASE_URL || 'postgres://ledat0402:Dat1982004!@localhost:5432/edtech_db';
  
  const client = new Client({
    connectionString: dbUrl,
  });

  try {
    console.log('🔌 Đang kết nối đến database...');
    console.log('   User: ledat0402');
    console.log('   Database: edtech_db');
    await client.connect();
    console.log('✅ Kết nối thành công!');

    const result = await client.query('SELECT version()');
    console.log('📊 PostgreSQL version:', result.rows[0].version.split(',')[0]);

    const dbResult = await client.query(
      "SELECT datname FROM pg_database WHERE datname = 'edtech_db'"
    );
    if (dbResult.rows.length > 0) {
      console.log('✅ Database edtech_db tồn tại');
    } else {
      console.log('❌ Database edtech_db không tồn tại');
    }

    const userResult = await client.query(
      "SELECT usename FROM pg_user WHERE usename = 'ledat0402'"
    );
    if (userResult.rows.length > 0) {
      console.log('✅ User ledat0402 tồn tại');
    } else {
      console.log('❌ User ledat0402 không tồn tại');
    }

    // Test quyền trên database
    await client.query('SELECT 1');
    console.log('✅ Có quyền truy cập database');

    await client.end();
    console.log('\n🎉 Tất cả đều OK! Bạn có thể chạy npm run seed và npm start');
  } catch (error) {
    console.error('❌ Lỗi kết nối:', error.message);
    console.error('\n💡 Kiểm tra lại:');
    console.error('   1. PostgreSQL đang chạy');
    console.error('   2. DATABASE_URL trong .env đúng (password có ký tự đặc biệt cần URL encode: ! = %21)');
    console.error('   3. Database edtech_db đã được tạo');
    console.error('   4. User ledat0402 đã được tạo và có quyền trên database edtech_db');
    console.error('\n📝 Format DATABASE_URL đúng:');
    console.error('   postgres://ledat0402:Dat1982004%21@localhost:5432/edtech_db');
    process.exit(1);
  }
}

testConnection();
