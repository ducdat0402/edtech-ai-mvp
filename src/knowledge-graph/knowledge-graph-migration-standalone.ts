import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { KnowledgeGraphMigrationService } from './knowledge-graph-migration.service';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const migrationService = app.get(KnowledgeGraphMigrationService);

  try {
    await migrationService.migrateAll();
    console.log('✅ Knowledge Graph migration completed successfully!');
  } catch (error) {
    console.error('❌ Error during migration:', error);
    process.exit(1);
  }

  await app.close();
}

bootstrap();

