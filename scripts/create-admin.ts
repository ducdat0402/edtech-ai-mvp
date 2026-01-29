import { DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User } from '../src/users/entities/user.entity';

// Load environment variables
require('dotenv').config();

async function createAdmin() {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    console.error('❌ DATABASE_URL not found in environment variables');
    process.exit(1);
  }

  // Chỉ cần User entity vì chúng ta chỉ tạo/update user
  const dataSource = new DataSource({
    type: 'postgres',
    url: databaseUrl,
    entities: [User],
    synchronize: false, // Tắt synchronize sau khi đã thêm column
    logging: false,
  });

  try {
    await dataSource.initialize();
    console.log('✅ Connected to database');
    
    // Đảm bảo column role tồn tại
    try {
      await dataSource.query(`
        ALTER TABLE users 
        ADD COLUMN IF NOT EXISTS role VARCHAR DEFAULT 'user';
      `);
      await dataSource.query(`
        UPDATE users SET role = 'user' WHERE role IS NULL;
      `);
      console.log('✅ Ensured role column exists');
    } catch (error) {
      // Column might already exist, that's okay
      console.log('⚠️  Role column check:', error.message);
    }

    const userRepository = dataSource.getRepository(User);

    // Lấy email và password từ command line arguments hoặc dùng default
    const email = process.argv[2] || 'admin@edtech.com';
    const password = process.argv[3] || 'admin123';
    const fullName = process.argv[4] || 'Admin User';

    // Check if admin already exists
    const existingAdmin = await userRepository.findOne({
      where: { email },
    });

    if (existingAdmin) {
      // Update existing user to admin
      existingAdmin.role = 'admin';
      const hashedPassword = await bcrypt.hash(password, 10);
      existingAdmin.password = hashedPassword;
      await userRepository.save(existingAdmin);
      console.log(`✅ Updated user ${email} to admin role`);
    } else {
      // Create new admin user
      const hashedPassword = await bcrypt.hash(password, 10);
      const admin = userRepository.create({
        email,
        password: hashedPassword,
        fullName,
        role: 'admin',
      });

      await userRepository.save(admin);
      console.log(`✅ Created admin user:`);
      console.log(`   Email: ${email}`);
      console.log(`   Password: ${password}`);
      console.log(`   Full Name: ${fullName}`);
    }

    await dataSource.destroy();
    console.log('✅ Done!');
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

createAdmin();

