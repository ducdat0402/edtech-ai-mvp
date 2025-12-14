import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/http-exception.filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Global exception filter
  app.useGlobalFilters(new AllExceptionsFilter());

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // CORS
  app.enableCors({
    origin: process.env.CORS_ORIGIN || '*',
    credentials: true,
  });

  // API prefix
  app.setGlobalPrefix('api/v1');

  // Swagger Documentation
  const config = new DocumentBuilder()
    .setTitle('EdTech AI MVP API')
    .setDescription('API documentation for EdTech AI MVP - Personalized learning platform with AI')
    .setVersion('1.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        name: 'JWT',
        description: 'Enter JWT token',
        in: 'header',
      },
      'JWT-auth',
    )
    .addTag('auth', 'Authentication endpoints')
    .addTag('users', 'User management')
    .addTag('subjects', 'Learning subjects')
    .addTag('progress', 'User progress tracking')
    .addTag('quests', 'Daily quests system')
    .addTag('leaderboard', 'Leaderboard rankings')
    .addTag('test', 'Placement test')
    .addTag('roadmap', 'Learning roadmap')
    .addTag('onboarding', 'AI onboarding chat')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/v1/docs', app, document, {
    swaggerOptions: {
      persistAuthorization: true,
    },
  });

  const port = process.env.PORT || 3000;
  // Listen on 0.0.0.0 to allow connections from emulator/network devices
  await app.listen(port, '0.0.0.0');
  console.log(`🚀 Server running on http://0.0.0.0:${port}/api/v1`);
  console.log(`📚 Swagger docs available at http://localhost:${port}/api/v1/docs`);
  console.log(`🌐 Accessible from network: http://YOUR_IP:${port}/api/v1`);
}

bootstrap();

