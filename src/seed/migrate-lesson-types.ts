/**
 * Migration script: Move existing LearningNode lessonType/lessonData/endQuiz
 * into the new lesson_type_contents table.
 *
 * Run: npx ts-node -r tsconfig-paths/register src/seed/migrate-lesson-types.ts
 */

import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';

dotenv.config();

async function migrate() {
  const dataSource = new DataSource({
    type: 'postgres',
    url: process.env.DATABASE_URL,
    synchronize: false,
    logging: true,
  });

  await dataSource.initialize();
  console.log('Connected to database');

  const queryRunner = dataSource.createQueryRunner();
  await queryRunner.connect();
  await queryRunner.startTransaction();

  try {
    // Find all learning nodes that have lessonType data
    const nodesWithContent = await queryRunner.query(`
      SELECT id, "lessonType", "lessonData", "endQuiz"
      FROM learning_nodes
      WHERE "lessonType" IS NOT NULL
        AND "lessonData" IS NOT NULL
    `);

    console.log(`Found ${nodesWithContent.length} nodes with lesson type content to migrate`);

    let migrated = 0;
    let skipped = 0;

    for (const node of nodesWithContent) {
      // Check if already migrated
      const existing = await queryRunner.query(
        `SELECT id FROM lesson_type_contents WHERE "nodeId" = $1 AND "lessonType" = $2`,
        [node.id, node.lessonType],
      );

      if (existing.length > 0) {
        console.log(`  Skipping node ${node.id} (${node.lessonType}) - already migrated`);
        skipped++;
        continue;
      }

      // Insert into lesson_type_contents
      await queryRunner.query(
        `INSERT INTO lesson_type_contents (id, "nodeId", "lessonType", "lessonData", "endQuiz", "createdAt", "updatedAt")
         VALUES (gen_random_uuid(), $1, $2, $3, $4, NOW(), NOW())`,
        [
          node.id,
          node.lessonType,
          JSON.stringify(node.lessonData),
          JSON.stringify(node.endQuiz || { questions: [], passingScore: 70 }),
        ],
      );

      migrated++;
      console.log(`  Migrated node ${node.id} (${node.lessonType})`);
    }

    await queryRunner.commitTransaction();
    console.log(`\nMigration complete: ${migrated} migrated, ${skipped} skipped`);
  } catch (error) {
    console.error('Migration failed:', error);
    await queryRunner.rollbackTransaction();
    throw error;
  } finally {
    await queryRunner.release();
    await dataSource.destroy();
  }
}

migrate().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
