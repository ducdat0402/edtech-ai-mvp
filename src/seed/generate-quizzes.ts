/**
 * Script to generate quizzes for all content items
 * 
 * Usage:
 *   npx ts-node src/seed/generate-quizzes.ts [options]
 * 
 * Options:
 *   --limit=N     Maximum number of quizzes to generate (default: 50)
 *   --type=TYPE   Only generate for specific type: 'concept' or 'example'
 *   --dry-run     Show what would be generated without actually generating
 */

import { DataSource } from 'typeorm';
import { config } from 'dotenv';
import OpenAI from 'openai';

// Import all entities to avoid relation errors
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

// Use DATABASE_URL from .env (same as main app)
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
  synchronize: true, // Auto-create quiz table if not exists
});

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

async function generateQuizForContent(
  contentItem: ContentItem,
): Promise<QuizQuestion[]> {
  const contentType = contentItem.type as 'concept' | 'example';
  const contentText = extractContentText(contentItem);
  
  let prompt: string;
  
  if (contentType === 'concept') {
    prompt = `Bạn là người thiết kế bài kiểm tra kiến thức.

Kiến thức cần kiểm tra (KHÁI NIỆM):
Tiêu đề: ${contentItem.title}
Nội dung: ${contentText}

Yêu cầu chung:
– Câu hỏi trắc nghiệm 4 lựa chọn (A, B, C, D)
– Chỉ có 1 đáp án đúng
– Không dùng câu hỏi yêu cầu nhớ nguyên văn định nghĩa
– Tránh câu quá dễ hoặc đánh đố vô lý

Mục tiêu: kiểm tra người học hiểu đúng bản chất, không học thuộc.

Tạo 5 câu hỏi:
- 2-3 câu: chọn định nghĩa đúng hoặc nhận diện mô tả đúng bản chất khái niệm
- 2-3 câu: phân biệt khái niệm này với các khái niệm gần giống, dễ nhầm lẫn

Trả về JSON với format:
{
  "questions": [
    {
      "id": "q1",
      "question": "Câu hỏi...",
      "options": { "A": "...", "B": "...", "C": "...", "D": "..." },
      "correctAnswer": "A",
      "explanation": "Giải thích vì sao A đúng và các đáp án khác sai",
      "category": "definition|distinction"
    }
  ]
}`;
  } else {
    prompt = `Bạn là người thiết kế bài kiểm tra kiến thức.

Kiến thức cần kiểm tra (VÍ DỤ / VẬN DỤNG):
Tiêu đề: ${contentItem.title}
Nội dung: ${contentText}

Yêu cầu chung:
– Câu hỏi trắc nghiệm 4 lựa chọn (A, B, C, D)
– Chỉ có 1 đáp án đúng
– Không dùng câu hỏi yêu cầu nhớ nguyên văn định nghĩa
– Tránh câu quá dễ hoặc đánh đố vô lý

Mục tiêu: kiểm tra khả năng áp dụng và nhận diện đúng/sai.

Tạo 7 câu hỏi:
- 3-4 câu: chọn ví dụ đúng với khái niệm
- 2-3 câu: chọn ví dụ sai / không phù hợp
- 1-2 câu: tình huống ngắn (mini-case), yêu cầu xác định cách hiểu hoặc áp dụng đúng

Trả về JSON với format:
{
  "questions": [
    {
      "id": "q1", 
      "question": "Câu hỏi...",
      "options": { "A": "...", "B": "...", "C": "...", "D": "..." },
      "correctAnswer": "A",
      "explanation": "Giải thích vì sao A đúng và các đáp án khác sai",
      "category": "correct_example|wrong_example|mini_case"
    }
  ]
}`;
  }

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      {
        role: 'system',
        content: 'Bạn là chuyên gia thiết kế bài kiểm tra. Luôn trả về JSON hợp lệ.',
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

function extractContentText(contentItem: ContentItem): string {
  const parts: string[] = [];

  // Add main content
  if (contentItem.content) {
    parts.push(contentItem.content);
  }

  // Add rich content if available (convert to plain text)
  if (contentItem.richContent) {
    try {
      if (Array.isArray(contentItem.richContent)) {
        const text = contentItem.richContent
          .map((block: any) => block.insert || '')
          .join('');
        if (text.trim()) parts.push(text);
      }
    } catch (e) {
      // Ignore rich content parsing errors
    }
  }

  // Add media descriptions if available
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

async function main() {
  // Parse command line arguments
  const args = process.argv.slice(2);
  let limit = 50;
  let filterType: string | null = null;
  let dryRun = false;

  for (const arg of args) {
    if (arg.startsWith('--limit=')) {
      limit = parseInt(arg.split('=')[1]);
    } else if (arg.startsWith('--type=')) {
      filterType = arg.split('=')[1];
    } else if (arg === '--dry-run') {
      dryRun = true;
    }
  }

  console.log('🚀 Starting quiz generation...');
  console.log(`   Limit: ${limit}`);
  console.log(`   Filter type: ${filterType || 'all'}`);
  console.log(`   Dry run: ${dryRun}`);
  console.log('');

  await dataSource.initialize();
  console.log('✅ Database connected\n');

  const contentRepo = dataSource.getRepository(ContentItem);
  const quizRepo = dataSource.getRepository(Quiz);

  // Find content items without quizzes
  let query = contentRepo
    .createQueryBuilder('content')
    .leftJoin('quizzes', 'quiz', 'quiz.contentItemId = content.id')
    .where('content.type IN (:...types)', { types: ['concept', 'example'] })
    .andWhere('quiz.id IS NULL');

  if (filterType) {
    query = query.andWhere('content.type = :type', { type: filterType });
  }

  const contentItems = await query.take(limit).getMany();

  console.log(`📝 Found ${contentItems.length} content items without quizzes\n`);

  if (dryRun) {
    console.log('Dry run - would generate quizzes for:');
    for (const item of contentItems) {
      console.log(`  - [${item.type}] ${item.title}`);
    }
    await dataSource.destroy();
    return;
  }

  let generated = 0;
  let failed = 0;
  let skipped = 0;

  for (let i = 0; i < contentItems.length; i++) {
    const item = contentItems[i];
    const contentText = extractContentText(item);

    // Skip if not enough content
    if (contentText.length < 50) {
      console.log(`⏭️  [${i + 1}/${contentItems.length}] Skipping "${item.title}" - not enough content`);
      skipped++;
      continue;
    }

    try {
      console.log(`📝 [${i + 1}/${contentItems.length}] Generating quiz for: ${item.title}`);
      
      const questions = await generateQuizForContent(item);
      
      if (questions.length === 0) {
        console.log(`   ⚠️  No questions generated`);
        failed++;
        continue;
      }

      // Save quiz to database
      const quiz = quizRepo.create({
        contentItemId: item.id,
        type: 'lesson',
        contentType: item.type as 'concept' | 'example',
        questions,
        totalQuestions: questions.length,
        passingScore: 70,
        title: item.title,
        generatedAt: new Date(),
        generationModel: 'gpt-4o-mini',
      });

      await quizRepo.save(quiz);
      console.log(`   ✅ Saved ${questions.length} questions`);
      generated++;

      // Rate limiting - wait 1.5 seconds between API calls
      if (i < contentItems.length - 1) {
        await new Promise(resolve => setTimeout(resolve, 1500));
      }
    } catch (error: any) {
      console.log(`   ❌ Error: ${error.message}`);
      failed++;
    }
  }

  console.log('\n========================================');
  console.log('📊 Quiz Generation Summary:');
  console.log(`   ✅ Generated: ${generated}`);
  console.log(`   ❌ Failed: ${failed}`);
  console.log(`   ⏭️  Skipped: ${skipped}`);
  console.log('========================================\n');

  // Show current stats
  const stats = await quizRepo
    .createQueryBuilder('quiz')
    .select('quiz.contentType', 'contentType')
    .addSelect('COUNT(*)', 'count')
    .groupBy('quiz.contentType')
    .getRawMany();

  console.log('📊 Current Quiz Stats:');
  for (const stat of stats) {
    console.log(`   ${stat.contentType || 'boss'}: ${stat.count} quizzes`);
  }

  await dataSource.destroy();
  console.log('\n✅ Done!');
}

main().catch(console.error);
