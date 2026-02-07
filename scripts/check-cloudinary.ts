import { config } from 'dotenv';
import * as path from 'path';

// Load environment variables
config({ path: path.join(__dirname, '../.env') });

const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
const apiKey = process.env.CLOUDINARY_API_KEY;
const apiSecret = process.env.CLOUDINARY_API_SECRET;

console.log('\n🔍 Cloudinary Configuration Check\n');
console.log('='.repeat(50));

if (cloudName && apiKey && apiSecret) {
  console.log('✅ All Cloudinary environment variables are set:');
  console.log(`   CLOUDINARY_CLOUD_NAME: ${cloudName}`);
  console.log(`   CLOUDINARY_API_KEY: ${apiKey.substring(0, 10)}...`);
  console.log(`   CLOUDINARY_API_SECRET: ${apiSecret.substring(0, 10)}...`);
  console.log('\n✅ Cloudinary should be enabled in the backend.');
  console.log('   Make sure to restart the backend server after setting these variables.');
} else {
  console.log('❌ Missing Cloudinary environment variables:');
  if (!cloudName) console.log('   ❌ CLOUDINARY_CLOUD_NAME is missing');
  if (!apiKey) console.log('   ❌ CLOUDINARY_API_KEY is missing');
  if (!apiSecret) console.log('   ❌ CLOUDINARY_API_SECRET is missing');
  console.log('\n⚠️  Backend will use local storage instead of Cloudinary.');
}

console.log('\n' + '='.repeat(50));
console.log('\n💡 To fix:');
console.log('   1. Check your .env file in the backend directory');
console.log('   2. Make sure all three variables are set');
console.log('   3. Restart the backend server: npm run start:dev');
console.log('\n');

