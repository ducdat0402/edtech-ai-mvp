import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { DataSource } from 'typeorm';
import { seedDomains } from './seed-domains';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const dataSource = app.get(DataSource);
  
  try {
    await seedDomains(dataSource);
    console.log('✅ Domain seeding completed!');
  } catch (error) {
    console.error('❌ Error seeding domains:', error);
    process.exit(1);
  }
  
  await app.close();
}

bootstrap();

