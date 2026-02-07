/**
 * Script to pre-generate boss quizzes for all learning nodes
 * 
 * Boss quiz = quiz tổng hợp kiến thức của cả learning node
 * 
 * Usage:
 *   npx ts-node src/seed/generate-boss-quizzes.ts [options]
 * 
 * Options:
 *   --limit=N     Maximum number of boss quizzes to generate (default: 50)
 *   --dry-run     Show what would be generated without actually generating
 *   --force       Regenerate even if boss quiz already exists
 */

import { DataSource } from 'typeorm';
import { config } from 'dotenv';
import OpenAI from 'openai';

// Import all entities
import { User } from '../users/entities/user.entity';
import { Subject } from '../subjects/entities/subject.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { UserProgress } from '../user-progress/entities/user-progress.entity';
import { UserCurrency } from '../user-currency/entities/user-currency.entity';
import { UnlockTransaction } from '../unlock-transactions/entities/unlock-transaction.entity';
import { PlacementTest } from '../placement-test/entities/placement-test.entity';
import { Question } from '../placement-test/entities/question.entity';
import { Quest } from '../quests/entities/quest.entity';
import { UserQuest } from '../quests/entities/user-quest.entity';
import { SkillTree } from '../skill-tree/entities/skill-tree.entity';
import { SkillNode } from '../skill-tree/entities/skill-node.entity';
import { UserSkillProgress } from '../skill-tree/entities/user-skill-progress.entity';
import { ContentEdit } from '../content-edits/entities/content-edit.entity';
import { EditHistory } from '../content-edits/entities/edit-history.entity';
import { ContentVersion } from '../content-edits/entities/content-version.entity';
import { Domain } from '../domains/entities/domain.entity';
import { KnowledgeNode } from '../knowledge-graph/entities/knowledge-node.entity';
import { KnowledgeEdge } from '../knowledge-graph/entities/knowledge-edge.entity';
import { UserBehavior } from '../ai-agents/entities/user-behavior.entity';
import { RewardTransaction } from '../user-currency/entities/reward-transaction.entity';
import { Achievement } from '../achievements/entities/achievement.entity';
import { UserAchievement } from '../achievements/entities/user-achievement.entity';
import { PersonalMindMap } from '../personal-mind-map/entities/personal-mind-map.entity';
import { Quiz, QuizQuestion } from '../quiz/entities/quiz.entity';

config();

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  console.error('❌ DATABASE_URL not found in .env');
  process.exit(1);
}

const dataSource = new DataSource({
  type: 'postgres',
  url: databaseUrl,
  entities: [
    User, Subject, LearningNode, ContentItem, UserProgress, UserCurrency,
    UnlockTransaction, PlacementTest, Question, Quest, UserQuest,
    SkillTree, SkillNode, UserSkillProgress, ContentEdit, EditHistory,
    ContentVersion, Domain, KnowledgeNode, KnowledgeEdge, UserBehavior,
    RewardTransaction, Achievement, UserAchievement, PersonalMindMap, Quiz,
  ],
  synchronize: true,
});

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

function extractContentText(contentItem: ContentItem): string {
  const parts: string[] = [];

  if (contentItem.content) {
    parts.push(contentItem.content);
  }

  if (contentItem.richContent) {
    try {
      if (Array.isArray(contentItem.richContent)) {
        const text = contentItem.richContent
          .map((block: any) => block.insert || '')
          .join('');
        if (text.trim()) parts.push(text);
      }
    } catch (e) {
      // Ignore
    }
  }

  if (contentItem.media) {
    if (contentItem.media.imageDescription) {
      parts.push(contentItem.media.imageDescription);
    }
    if (contentItem.media.videoDescription) {
      parts.push(contentItem.media.videoDescription);
    }
  }

  return parts.join('\n\n');
}

async function generateBossQuiz(
  node: LearningNode,
  contentItems: ContentItem[],
): Promise<QuizQuestion[]> {
  // Combine all content from the node
  const combinedContent = contentItems
    .map((item) => `## ${item.title}\n${extractContentText(item)}`)
    .join('\n\n');

  if (combinedContent.length < 100) {
    console.log(`   ⚠️  Not enough content for node "${node.title}"`);
    return [];
  }

  const prompt = `Bạn là chuyên gia thiết kế bài kiểm tra tổng hợp (Boss Quiz).

BÀI HỌC: ${node.title}
${node.description ? `Mô tả: ${node.description}` : ''}

NỘI DUNG BÀI HỌC:
${combinedContent}

YÊU CẦU:
- Tạo 10-15 câu hỏi trắc nghiệm tổng hợp kiến thức cả bài
- Mỗi câu có 4 lựa chọn (A, B, C, D), chỉ 1 đáp án đúng
- Câu hỏi phải bao quát được nhiều phần của bài học
- Độ khó: vừa phải đến khó (đây là Boss Quiz - kiểm tra tổng kết)
- Câu hỏi phải kiểm tra hiểu bản chất, không học thuộc

PHÂN BỐ CÂU HỎI:
- 3-4 câu: Kiểm tra khái niệm cốt lõi
- 3-4 câu: Liên kết giữa các khái niệm trong bài  
- 2-3 câu: Áp dụng vào tình huống thực tế
- 2-3 câu: Phân biệt/so sánh các khái niệm

Trả về JSON:
{
  "questions": [
    {
      "id": "q1",
      "question": "Câu hỏi...",
      "options": { "A": "...", "B": "...", "C": "...", "D": "..." },
      "correctAnswer": "A",
      "explanation": "Giải thích chi tiết vì sao đáp án đúng",
      "category": "core_concept|connection|application|comparison",
      "difficulty": "medium|hard"
    }
  ]
}`;

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      {
        role: 'system',
        content: 'Bạn là chuyên gia thiết kế bài kiểm tra giáo dục. Luôn trả về JSON hợp lệ.',
      },
      { role: 'user', content: prompt },
    ],
    response_format: { type: 'json_object' },
    temperature: 0.7,
  });

  const content = response.choices[0]?.message?.content || '{}';
  const parsed = JSON.parse(content);
  return parsed.questions || [];
}

async function main() {
  // Parse arguments
  const args = process.argv.slice(2);
  let limit = 50;
  let dryRun = false;
  let force = false;

  for (const arg of args) {
    if (arg.startsWith('--limit=')) {
      limit = parseInt(arg.split('=')[1]);
    } else if (arg === '--dry-run') {
      dryRun = true;
    } else if (arg === '--force') {
      force = true;
    }
  }

  console.log('🎮 Starting Boss Quiz Generation...');
  console.log(`   Limit: ${limit}`);
  console.log(`   Dry run: ${dryRun}`);
  console.log(`   Force regenerate: ${force}`);
  console.log('');

  await dataSource.initialize();
  console.log('✅ Database connected\n');

  const nodeRepo = dataSource.getRepository(LearningNode);
  const contentRepo = dataSource.getRepository(ContentItem);
  const quizRepo = dataSource.getRepository(Quiz);

  // Find learning nodes
  let query = nodeRepo
    .createQueryBuilder('node')
    .leftJoin('quizzes', 'quiz', 'quiz.learningNodeId = node.id AND quiz.type = :type', { type: 'boss' });

  if (!force) {
    query = query.where('quiz.id IS NULL');
  }

  const nodes = await query.take(limit).getMany();

  console.log(`📚 Found ${nodes.length} learning nodes ${force ? '(force mode)' : 'without boss quiz'}\n`);

  if (dryRun) {
    console.log('Dry run - would generate boss quizzes for:');
    for (const node of nodes) {
      const contentCount = await contentRepo.count({
        where: { nodeId: node.id },
      });
      console.log(`  - ${node.title} (${contentCount} content items)`);
    }
    await dataSource.destroy();
    return;
  }

  let generated = 0;
  let failed = 0;
  let skipped = 0;

  for (let i = 0; i < nodes.length; i++) {
    const node = nodes[i];

    // Get all content items for this node
    const contentItems = await contentRepo.find({
      where: { nodeId: node.id },
      order: { order: 'ASC' },
    });

    if (contentItems.length === 0) {
      console.log(`⏭️  [${i + 1}/${nodes.length}] Skipping "${node.title}" - no content items`);
      skipped++;
      continue;
    }

    try {
      console.log(`🎮 [${i + 1}/${nodes.length}] Generating boss quiz for: ${node.title}`);
      console.log(`   Content items: ${contentItems.length}`);

      const questions = await generateBossQuiz(node, contentItems);

      if (questions.length === 0) {
        console.log(`   ⚠️  No questions generated`);
        failed++;
        continue;
      }

      // Delete existing if force mode
      if (force) {
        await quizRepo.delete({ learningNodeId: node.id, type: 'boss' });
      }

      // Save quiz
      const quiz = quizRepo.create({
        learningNodeId: node.id,
        type: 'boss',
        questions,
        totalQuestions: questions.length,
        passingScore: 80, // Boss quiz requires 80%
        title: `Boss Quiz: ${node.title}`,
        generatedAt: new Date(),
        generationModel: 'gpt-4o-mini',
      });

      await quizRepo.save(quiz);
      console.log(`   ✅ Saved ${questions.length} questions (passing: 80%)`);
      generated++;

      // Rate limiting
      if (i < nodes.length - 1) {
        await new Promise(resolve => setTimeout(resolve, 2000));
      }
    } catch (error: any) {
      console.log(`   ❌ Error: ${error.message}`);
      failed++;
    }
  }

  console.log('\n========================================');
  console.log('📊 Boss Quiz Generation Summary:');
  console.log(`   ✅ Generated: ${generated}`);
  console.log(`   ❌ Failed: ${failed}`);
  console.log(`   ⏭️  Skipped: ${skipped}`);
  console.log('========================================\n');

  // Show stats
  const [totalBoss, totalLesson] = await Promise.all([
    quizRepo.count({ where: { type: 'boss' } }),
    quizRepo.count({ where: { type: 'lesson' } }),
  ]);

  console.log('📊 Current Quiz Stats:');
  console.log(`   Boss quizzes: ${totalBoss}`);
  console.log(`   Lesson quizzes: ${totalLesson}`);
  console.log(`   Total: ${totalBoss + totalLesson}`);

  await dataSource.destroy();
  console.log('\n✅ Done!');
}

main().catch(console.error);
