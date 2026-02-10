/**
 * Seed: Tạo môn Bóng rổ và Thuế với đầy đủ nội dung bài học (4 dạng)
 *
 * Mỗi bài học có đủ 4 dạng: image_quiz, image_gallery, video, text
 * Nội dung + câu hỏi được AI (OpenAI) sinh tự động
 *
 * CÁCH CHẠY:
 *   cd backend
 *   npx ts-node -r tsconfig-paths/register src/seed/seed-basketball-tax.ts
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { SubjectsService } from '../subjects/subjects.service';
import { DomainsService } from '../domains/domains.service';
import { TopicsService } from '../topics/topics.service';
import { LessonTypeContentsService } from '../lesson-type-contents/lesson-type-contents.service';
import { AiService } from '../ai/ai.service';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { Subject } from '../subjects/entities/subject.entity';

// ═══════════════════════════════════════════════════════════════
// TYPES
// ═══════════════════════════════════════════════════════════════

interface NodeDef {
  title: string;
  description: string;
  order: number;
  difficulty: 'easy' | 'medium' | 'hard';
  type: 'theory' | 'practice' | 'assessment';
  expReward: number;
  coinReward: number;
}

interface TopicDef {
  name: string;
  description: string;
  order: number;
  difficulty: 'easy' | 'medium' | 'hard';
  expReward: number;
  coinReward: number;
  nodes: NodeDef[];
}

interface DomainDef {
  name: string;
  description: string;
  order: number;
  difficulty: 'easy' | 'medium' | 'hard';
  expReward: number;
  coinReward: number;
  icon: string;
  topics: TopicDef[];
}

interface SubjectDef {
  name: string;
  description: string;
  track: 'explorer' | 'scholar';
  icon: string;
  color: string;
  domains: DomainDef[];
}

// ═══════════════════════════════════════════════════════════════
// SUBJECT DEFINITIONS
// ═══════════════════════════════════════════════════════════════

const SUBJECTS: SubjectDef[] = [
  // ─────── BÓNG RỔ ───────
  {
    name: 'Bóng rổ',
    description:
      'Học chơi bóng rổ từ cơ bản đến nâng cao, bao gồm kỹ thuật, chiến thuật và luật thi đấu',
    track: 'explorer',
    icon: '🏀',
    color: '#FF6B35',
    domains: [
      {
        name: 'Kỹ thuật cơ bản',
        description:
          'Nắm vững các kỹ thuật nền tảng của bóng rổ: dribble, ném rổ, chuyền bóng',
        order: 0,
        difficulty: 'easy',
        expReward: 500,
        coinReward: 200,
        icon: '🎯',
        topics: [
          {
            name: 'Dribble & Di chuyển',
            description: 'Kỹ thuật dribble bóng và di chuyển trên sân',
            order: 0,
            difficulty: 'easy',
            expReward: 200,
            coinReward: 80,
            nodes: [
              {
                title: 'Dribble cơ bản',
                description:
                  'Học cách dribble bóng rổ đúng kỹ thuật: tư thế, tay đặt bóng, nhịp nảy',
                order: 0,
                difficulty: 'easy',
                type: 'theory',
                expReward: 50,
                coinReward: 20,
              },
              {
                title: 'Dribble nâng cao - Crossover',
                description:
                  'Kỹ thuật crossover, behind-the-back, between-the-legs để vượt qua đối thủ',
                order: 1,
                difficulty: 'medium',
                type: 'practice',
                expReward: 70,
                coinReward: 30,
              },
            ],
          },
          {
            name: 'Ném rổ',
            description: 'Kỹ thuật ném rổ từ cơ bản đến nâng cao',
            order: 1,
            difficulty: 'medium',
            expReward: 250,
            coinReward: 100,
            nodes: [
              {
                title: 'Kỹ thuật ném rổ cơ bản',
                description:
                  'Tư thế ném, cách cầm bóng, góc tay và follow-through khi ném rổ',
                order: 0,
                difficulty: 'easy',
                type: 'theory',
                expReward: 50,
                coinReward: 20,
              },
              {
                title: 'Lay-up và ném 3 điểm',
                description:
                  'Kỹ thuật lay-up khi chạy vào rổ và ném 3 điểm từ xa',
                order: 1,
                difficulty: 'medium',
                type: 'practice',
                expReward: 80,
                coinReward: 30,
              },
            ],
          },
        ],
      },
      {
        name: 'Chiến thuật & Thi đấu',
        description:
          'Chiến thuật thi đấu bóng rổ: tấn công, phòng thủ và luật chơi',
        order: 1,
        difficulty: 'medium',
        expReward: 600,
        coinReward: 250,
        icon: '📋',
        topics: [
          {
            name: 'Chiến thuật tấn công',
            description:
              'Các hệ thống tấn công cơ bản trong bóng rổ',
            order: 0,
            difficulty: 'medium',
            expReward: 300,
            coinReward: 120,
            nodes: [
              {
                title: 'Pick and Roll',
                description:
                  'Chiến thuật Pick and Roll - một trong những lối chơi phổ biến nhất trong bóng rổ',
                order: 0,
                difficulty: 'medium',
                type: 'theory',
                expReward: 80,
                coinReward: 30,
              },
              {
                title: 'Fast Break - Phản công nhanh',
                description:
                  'Chiến thuật tấn công nhanh khi đội bạn vừa cướp được bóng',
                order: 1,
                difficulty: 'medium',
                type: 'practice',
                expReward: 80,
                coinReward: 30,
              },
            ],
          },
          {
            name: 'Phòng thủ & Luật chơi',
            description:
              'Chiến thuật phòng thủ cá nhân/khu vực và luật thi đấu bóng rổ',
            order: 1,
            difficulty: 'medium',
            expReward: 300,
            coinReward: 120,
            nodes: [
              {
                title: 'Phòng thủ cá nhân (Man-to-Man)',
                description:
                  'Kỹ thuật phòng thủ kèm người 1-1: footwork, stance, stealing',
                order: 0,
                difficulty: 'medium',
                type: 'theory',
                expReward: 80,
                coinReward: 30,
              },
              {
                title: 'Luật thi đấu bóng rổ',
                description:
                  'Các luật cơ bản trong bóng rổ: lỗi, ném phạt, thời gian, khu vực sân',
                order: 1,
                difficulty: 'easy',
                type: 'theory',
                expReward: 60,
                coinReward: 25,
              },
            ],
          },
        ],
      },
    ],
  },

  // ─────── THUẾ ───────
  {
    name: 'Thuế',
    description:
      'Tìm hiểu hệ thống thuế Việt Nam: thuế cá nhân, doanh nghiệp, kê khai và nghĩa vụ thuế',
    track: 'explorer',
    icon: '💰',
    color: '#2ECC71',
    domains: [
      {
        name: 'Thuế cá nhân',
        description:
          'Hiểu về thuế thu nhập cá nhân và các loại thuế liên quan đến cá nhân',
        order: 0,
        difficulty: 'easy',
        expReward: 500,
        coinReward: 200,
        icon: '🧑',
        topics: [
          {
            name: 'Khái niệm cơ bản về thuế',
            description:
              'Thuế là gì, tại sao phải nộp thuế, các loại thuế phổ biến',
            order: 0,
            difficulty: 'easy',
            expReward: 200,
            coinReward: 80,
            nodes: [
              {
                title: 'Thuế là gì?',
                description:
                  'Khái niệm thuế, vai trò của thuế trong nền kinh tế, lịch sử thuế',
                order: 0,
                difficulty: 'easy',
                type: 'theory',
                expReward: 50,
                coinReward: 20,
              },
              {
                title: 'Hệ thống thuế Việt Nam',
                description:
                  'Tổng quan các loại thuế ở Việt Nam: thuế trực thu, gián thu, thuế đặc biệt',
                order: 1,
                difficulty: 'easy',
                type: 'theory',
                expReward: 50,
                coinReward: 20,
              },
            ],
          },
          {
            name: 'Thuế thu nhập cá nhân (TNCN)',
            description:
              'Chi tiết về thuế TNCN: đối tượng, cách tính, giảm trừ',
            order: 1,
            difficulty: 'medium',
            expReward: 250,
            coinReward: 100,
            nodes: [
              {
                title: 'Cách tính thuế TNCN',
                description:
                  'Biểu thuế lũy tiến, thu nhập chịu thuế, thu nhập không chịu thuế',
                order: 0,
                difficulty: 'medium',
                type: 'theory',
                expReward: 70,
                coinReward: 30,
              },
              {
                title: 'Giảm trừ gia cảnh và các khoản giảm trừ',
                description:
                  'Giảm trừ cho bản thân, người phụ thuộc, bảo hiểm, từ thiện',
                order: 1,
                difficulty: 'medium',
                type: 'practice',
                expReward: 80,
                coinReward: 30,
              },
            ],
          },
        ],
      },
      {
        name: 'Thuế doanh nghiệp & Kê khai',
        description:
          'Thuế doanh nghiệp, thuế GTGT và quy trình kê khai thuế',
        order: 1,
        difficulty: 'medium',
        expReward: 600,
        coinReward: 250,
        icon: '🏢',
        topics: [
          {
            name: 'Thuế doanh nghiệp',
            description:
              'Thuế thu nhập doanh nghiệp và thuế giá trị gia tăng',
            order: 0,
            difficulty: 'medium',
            expReward: 300,
            coinReward: 120,
            nodes: [
              {
                title: 'Thuế thu nhập doanh nghiệp (TNDN)',
                description:
                  'Đối tượng nộp thuế, thuế suất, thu nhập chịu thuế, chi phí được trừ',
                order: 0,
                difficulty: 'medium',
                type: 'theory',
                expReward: 80,
                coinReward: 30,
              },
              {
                title: 'Thuế giá trị gia tăng (VAT)',
                description:
                  'Thuế GTGT: đối tượng, mức thuế suất 0%, 5%, 8%, 10%, phương pháp tính',
                order: 1,
                difficulty: 'medium',
                type: 'theory',
                expReward: 80,
                coinReward: 30,
              },
            ],
          },
          {
            name: 'Kê khai và nộp thuế',
            description:
              'Quy trình kê khai, nộp thuế và hóa đơn điện tử',
            order: 1,
            difficulty: 'hard',
            expReward: 300,
            coinReward: 120,
            nodes: [
              {
                title: 'Kê khai thuế trực tuyến',
                description:
                  'Hướng dẫn kê khai thuế qua mạng: đăng ký, kê khai, nộp thuế trên hệ thống eTax',
                order: 0,
                difficulty: 'hard',
                type: 'practice',
                expReward: 100,
                coinReward: 40,
              },
              {
                title: 'Hóa đơn điện tử',
                description:
                  'Quy định về hóa đơn điện tử, cách phát hành, lưu trữ và xử lý sai sót',
                order: 1,
                difficulty: 'hard',
                type: 'theory',
                expReward: 100,
                coinReward: 40,
              },
            ],
          },
        ],
      },
    ],
  },
];

// ═══════════════════════════════════════════════════════════════
// MEDIA HELPERS
// ═══════════════════════════════════════════════════════════════

const SAMPLE_VIDEOS = [
  'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  'https://storage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
  'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
  'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
  'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
];

function imageUrl(seed: string, w = 800, h = 600): string {
  return `https://picsum.photos/seed/${seed}/${w}/${h}`;
}

function videoUrl(index: number): string {
  return SAMPLE_VIDEOS[index % SAMPLE_VIDEOS.length];
}

// ═══════════════════════════════════════════════════════════════
// AI CONTENT GENERATION
// ═══════════════════════════════════════════════════════════════

async function generateAllLessonTypes(
  aiService: AiService,
  subjectName: string,
  nodeTitle: string,
  nodeDescription: string,
  nodeIndex: number,
): Promise<Record<string, { lessonData: any; endQuiz: any }>> {
  const slug = subjectName
    .toLowerCase()
    .replace(/\s+/g, '-')
    .replace(/[^\w-]/g, '');
  const imgBase = `${slug}-${nodeIndex}`;

  const prompt = `
Bạn là chuyên gia giáo dục. Hãy tạo nội dung bài học BẰNG TIẾNG VIỆT cho chủ đề sau:

Môn học: ${subjectName}
Bài học: ${nodeTitle}
Mô tả: ${nodeDescription}

Tạo nội dung cho ĐẦY ĐỦ 4 dạng bài học, trả về JSON theo format:

{
  "image_quiz": {
    "slides": [
      {
        "question": "Câu hỏi liên quan đến hình ảnh",
        "options": [
          { "text": "Đáp án A", "explanation": "Giải thích A" },
          { "text": "Đáp án B", "explanation": "Giải thích B" },
          { "text": "Đáp án C", "explanation": "Giải thích C" },
          { "text": "Đáp án D", "explanation": "Giải thích D" }
        ],
        "correctAnswer": 0,
        "hint": "Gợi ý"
      }
    ],
    "endQuiz": {
      "questions": [
        {
          "question": "Câu hỏi ôn tập",
          "options": [
            { "text": "A", "explanation": "..." },
            { "text": "B", "explanation": "..." },
            { "text": "C", "explanation": "..." },
            { "text": "D", "explanation": "..." }
          ],
          "correctAnswer": 0
        }
      ],
      "passingScore": 70
    }
  },
  "image_gallery": {
    "images": [
      { "description": "Mô tả chi tiết cho hình ảnh minh họa" }
    ],
    "endQuiz": {
      "questions": [...],
      "passingScore": 70
    }
  },
  "video": {
    "summary": "Tóm tắt nội dung video",
    "keyPoints": [
      { "title": "Tiêu đề", "description": "Chi tiết", "timestamp": 0 }
    ],
    "keywords": ["từ khóa 1", "từ khóa 2"],
    "endQuiz": {
      "questions": [...],
      "passingScore": 70
    }
  },
  "text": {
    "sections": [
      { "title": "Tiêu đề phần", "content": "Nội dung chi tiết (có thể dài)" }
    ],
    "inlineQuizzes": [
      {
        "afterSectionIndex": 0,
        "question": "Câu hỏi xen kẽ",
        "options": [
          { "text": "A", "explanation": "..." },
          { "text": "B", "explanation": "..." },
          { "text": "C", "explanation": "..." },
          { "text": "D", "explanation": "..." }
        ],
        "correctAnswer": 0
      }
    ],
    "summary": "Tóm tắt bài học",
    "learningObjectives": ["Mục tiêu 1", "Mục tiêu 2"],
    "endQuiz": {
      "questions": [...],
      "passingScore": 70
    }
  }
}

YÊU CẦU:
- image_quiz: Tạo 4-5 slides, mỗi slide 1 câu hỏi với 4 đáp án, endQuiz 5 câu
- image_gallery: Tạo 5-6 images với mô tả chi tiết, endQuiz 5 câu
- video: Tạo summary, 4-5 keyPoints với timestamp tăng dần (giây), 5 keywords, endQuiz 5 câu
- text: Tạo 3-4 sections nội dung chi tiết, 2 inlineQuizzes, summary, 3 learningObjectives, endQuiz 5 câu
- Mỗi endQuiz có ĐÚng 5 câu hỏi, mỗi câu 4 đáp án
- correctAnswer là index (0-3)
- Nội dung phải chính xác, hữu ích, phù hợp trình độ người học
- KHÔNG thêm imageUrl hay videoUrl, chỉ tạo nội dung text
- Trả về JSON hợp lệ, KHÔNG markdown
`;

  console.log(`    🤖 Đang gọi AI tạo nội dung cho "${nodeTitle}"...`);
  const raw = await aiService.chatWithJsonMode([
    { role: 'user', content: prompt },
  ]);

  const data = JSON.parse(raw);

  // ── Inject media URLs ──

  // image_quiz: add imageUrl to each slide
  if (data.image_quiz?.slides) {
    data.image_quiz.slides = data.image_quiz.slides.map(
      (slide: any, i: number) => ({
        ...slide,
        imageUrl: imageUrl(`${imgBase}-quiz-${i}`),
      }),
    );
  }

  // image_gallery: add url to each image
  if (data.image_gallery?.images) {
    data.image_gallery.images = data.image_gallery.images.map(
      (img: any, i: number) => ({
        ...img,
        url: imageUrl(`${imgBase}-gallery-${i}`),
      }),
    );
  }

  // video: add videoUrl
  if (data.video) {
    data.video.videoUrl = videoUrl(nodeIndex);
  }

  // ── Build result ──
  const result: Record<string, { lessonData: any; endQuiz: any }> = {};

  // image_quiz
  const iqEndQuiz = data.image_quiz?.endQuiz || {
    questions: [],
    passingScore: 70,
  };
  result['image_quiz'] = {
    lessonData: { slides: data.image_quiz?.slides || [] },
    endQuiz: iqEndQuiz,
  };

  // image_gallery
  const igEndQuiz = data.image_gallery?.endQuiz || {
    questions: [],
    passingScore: 70,
  };
  result['image_gallery'] = {
    lessonData: { images: data.image_gallery?.images || [] },
    endQuiz: igEndQuiz,
  };

  // video
  const vEndQuiz = data.video?.endQuiz || {
    questions: [],
    passingScore: 70,
  };
  result['video'] = {
    lessonData: {
      videoUrl: data.video?.videoUrl || '',
      summary: data.video?.summary || '',
      keyPoints: data.video?.keyPoints || [],
      keywords: data.video?.keywords || [],
    },
    endQuiz: vEndQuiz,
  };

  // text
  const tEndQuiz = data.text?.endQuiz || {
    questions: [],
    passingScore: 70,
  };
  result['text'] = {
    lessonData: {
      sections: data.text?.sections || [],
      inlineQuizzes: data.text?.inlineQuizzes || [],
      summary: data.text?.summary || '',
      learningObjectives: data.text?.learningObjectives || [],
    },
    endQuiz: tEndQuiz,
  };

  return result;
}

// ═══════════════════════════════════════════════════════════════
// MAIN SEED FUNCTION
// ═══════════════════════════════════════════════════════════════

async function seed() {
  console.log('═══════════════════════════════════════════');
  console.log('  SEED: Bóng rổ + Thuế');
  console.log('═══════════════════════════════════════════\n');

  const app = await NestFactory.createApplicationContext(AppModule);

  const subjectsService = app.get(SubjectsService);
  const domainsService = app.get(DomainsService);
  const topicsService = app.get(TopicsService);
  const lessonTypeContentsService = app.get(LessonTypeContentsService);
  const aiService = app.get(AiService);
  const nodeRepo = app.get<Repository<LearningNode>>(
    getRepositoryToken(LearningNode),
  );
  const subjectRepo = app.get<Repository<Subject>>(
    getRepositoryToken(Subject),
  );

  let globalNodeIndex = 0;

  for (const subjectDef of SUBJECTS) {
    console.log(`\n📚 Đang xử lý môn: ${subjectDef.name}`);
    console.log('─'.repeat(50));

    // ── Clean up existing data if subject already exists ──
    const existingSubject = await subjectRepo.findOne({
      where: { name: subjectDef.name },
    });

    if (existingSubject) {
      console.log(`  🗑️  Subject "${subjectDef.name}" đã tồn tại. Xóa dữ liệu cũ...`);
      const sid = existingSubject.id;
      // Delete in correct order to respect FK constraints
      await nodeRepo.manager.query(
        `DELETE FROM lesson_type_contents WHERE "nodeId" IN (SELECT id FROM learning_nodes WHERE "subjectId" = $1)`,
        [sid],
      ).catch(() => {});
      await nodeRepo.manager.query(
        `DELETE FROM lesson_type_content_versions WHERE "nodeId" IN (SELECT id FROM learning_nodes WHERE "subjectId" = $1)`,
        [sid],
      ).catch(() => {});
      await nodeRepo.manager.query(
        `DELETE FROM user_progress WHERE "nodeId" IN (SELECT id FROM learning_nodes WHERE "subjectId" = $1)`,
        [sid],
      ).catch(() => {});
      await nodeRepo.manager.query(
        `DELETE FROM learning_nodes WHERE "subjectId" = $1`,
        [sid],
      );
      await nodeRepo.manager.query(
        `DELETE FROM topics WHERE "domainId" IN (SELECT id FROM domains WHERE "subjectId" = $1)`,
        [sid],
      );
      await nodeRepo.manager.query(
        `DELETE FROM domains WHERE "subjectId" = $1`,
        [sid],
      );
      await subjectRepo.delete(sid);
      console.log(`  ✅ Đã xóa sạch dữ liệu cũ.`);
    }

    // ── Create subject ──
    const subject = await subjectsService.createIfNotExists(
      subjectDef.name,
      subjectDef.description,
      subjectDef.track,
    );
    subject.metadata = {
      icon: subjectDef.icon,
      color: subjectDef.color,
      estimatedDays: 30,
    };
    subject.unlockConditions = { minCoin: 0 };
    await subjectRepo.save(subject);
    console.log(`  ✅ Đã tạo subject: ${subjectDef.name} (ID: ${subject.id})`);

    const subjectId = subject.id;

    // ── Create domains → topics → nodes ──
    for (const domainDef of subjectDef.domains) {
      console.log(`\n  📂 Domain: ${domainDef.name}`);

      const domain = await domainsService.create(subjectId, {
        name: domainDef.name,
        description: domainDef.description,
        order: domainDef.order,
        difficulty: domainDef.difficulty,
        expReward: domainDef.expReward,
        coinReward: domainDef.coinReward,
        metadata: { icon: domainDef.icon },
      });
      console.log(`    ✅ Domain ID: ${domain.id}`);

      for (const topicDef of domainDef.topics) {
        console.log(`\n    📌 Topic: ${topicDef.name}`);

        const topic = await topicsService.create(domain.id, {
          name: topicDef.name,
          description: topicDef.description,
          order: topicDef.order,
          difficulty: topicDef.difficulty,
          expReward: topicDef.expReward,
          coinReward: topicDef.coinReward,
        });
        console.log(`      ✅ Topic ID: ${topic.id}`);

        for (const nodeDef of topicDef.nodes) {
          console.log(`\n      📖 Node: ${nodeDef.title}`);

          // Create learning node
          const node = nodeRepo.create({
            subjectId,
            domainId: domain.id,
            topicId: topic.id,
            title: nodeDef.title,
            description: nodeDef.description,
            order: nodeDef.order,
            type: nodeDef.type,
            difficulty: nodeDef.difficulty,
            expReward: nodeDef.expReward,
            coinReward: nodeDef.coinReward,
            prerequisites: [],
            contentStructure: {
              concepts: 4,
              examples: 10,
              hiddenRewards: 5,
              bossQuiz: 1,
            },
            metadata: {
              icon: subjectDef.icon,
              position: {
                x: nodeDef.order * 200,
                y: domainDef.order * 300 + topicDef.order * 150,
              },
            },
          });
          const savedNode = await nodeRepo.save(node);
          console.log(`        ✅ Node ID: ${savedNode.id}`);

          // Generate AI content
          try {
            const allTypes = await generateAllLessonTypes(
              aiService,
              subjectDef.name,
              nodeDef.title,
              nodeDef.description,
              globalNodeIndex,
            );

            // Create 4 lesson type contents
            const types: Array<
              'image_quiz' | 'image_gallery' | 'video' | 'text'
            > = ['image_quiz', 'image_gallery', 'video', 'text'];

            for (const lt of types) {
              const content = allTypes[lt];
              if (!content) {
                console.log(`        ⚠️  Thiếu nội dung cho dạng ${lt}`);
                continue;
              }

              try {
                await lessonTypeContentsService.create({
                  nodeId: savedNode.id,
                  lessonType: lt,
                  lessonData: content.lessonData,
                  endQuiz: content.endQuiz,
                });
                console.log(`        ✅ ${lt} - OK`);
              } catch (err: any) {
                console.log(
                  `        ❌ ${lt} - Lỗi: ${err.message?.substring(0, 80)}`,
                );
              }
            }

            // Also set the legacy lessonType/lessonData on the node (first type)
            savedNode.lessonType = 'text';
            savedNode.lessonData = allTypes['text']?.lessonData || {};
            savedNode.endQuiz = allTypes['text']?.endQuiz || null;
            await nodeRepo.save(savedNode);
          } catch (err: any) {
            console.log(
              `        ❌ AI generation failed: ${err.message?.substring(0, 120)}`,
            );
          }

          globalNodeIndex++;
        }
      }
    }
  }

  console.log('\n═══════════════════════════════════════════');
  console.log('  ✅ SEED HOÀN THÀNH!');
  console.log(`  Tổng số nodes đã xử lý: ${globalNodeIndex}`);
  console.log('═══════════════════════════════════════════\n');

  await app.close();
}

seed().catch((err) => {
  console.error('❌ Seed thất bại:', err);
  process.exit(1);
});
