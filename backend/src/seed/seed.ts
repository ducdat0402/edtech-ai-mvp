import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { SeedModule } from './seed.module';
import { SeedService } from './seed.service';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const seedService = app.select(SeedModule).get(SeedService);
  await seedService.seed();
  await app.close();
}

bootstrap();

