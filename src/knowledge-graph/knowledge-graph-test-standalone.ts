import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { KnowledgeGraphTestService } from './knowledge-graph-test.service';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const testService = app.get(KnowledgeGraphTestService);

  try {
    await testService.runTests();
    console.log('✅ Knowledge Graph tests completed successfully!');
  } catch (error) {
    console.error('❌ Error during tests:', error);
    process.exit(1);
  }

  await app.close();
}

bootstrap();

