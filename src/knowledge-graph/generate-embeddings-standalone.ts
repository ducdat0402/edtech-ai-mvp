import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { GenerateEmbeddingsService } from './generate-embeddings.service';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const generateEmbeddingsService = app.get(GenerateEmbeddingsService);

  try {
    console.log('🚀 Starting embedding generation...');
    await generateEmbeddingsService.generateEmbeddingsForAllNodes();
    console.log('✅ Embedding generation completed successfully!');
  } catch (error) {
    console.error('❌ Error during embedding generation:', error);
    process.exit(1);
  }

  await app.close();
}

bootstrap();

