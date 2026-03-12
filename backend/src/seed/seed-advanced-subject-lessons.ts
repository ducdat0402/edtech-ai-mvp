/**
 * Seed: Tạo thêm nhiều bài học cho các môn chuyên sâu (tương tự IC3 / Bóng rổ)
 *
 * CÁCH CHẠY:
 *   cd backend
 *   npx ts-node -r tsconfig-paths/register src/seed/seed-advanced-subject-lessons.ts
 *
 * LƯU Ý:
 * - Script này giả định các môn đã được tạo sẵn bởi seed-new-subjects.ts
 * - Mục tiêu: ~50+ bài học / môn, dùng AI để generate nội dung 4 dạng bài học
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

interface SubjectPlan {
  name: string;
  icon: string;
}

// Danh sách các môn cần mở rộng bài học
const SUBJECT_PLANS: SubjectPlan[] = [
  { name: 'Lập trình hướng đối tượng', icon: '🧱' },
  { name: 'Quản trị học (Principles of Management)', icon: '📊' },
  { name: 'Digital Marketing', icon: '📣' },
  { name: 'Nguyên lý kế toán', icon: '📚' },
  { name: 'Phân tích tài chính doanh nghiệp', icon: '💼' },
  { name: 'Biên phiên dịch (Translation and Interpreting)', icon: '🗣️' },
  { name: 'Quản trị chuỗi cung ứng (Supply Chain Management)', icon: '🚚' },
  { name: 'Giải phẫu học (Human Anatomy)', icon: '🧠' },
  { name: 'Cơ học kỹ thuật', icon: '⚙️' },
  { name: 'Luật dân sự', icon: '⚖️' },
];

// Một ít video mẫu + helper tạo URL ảnh ngẫu nhiên
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

// Gọi AI để generate nội dung đầy đủ cho 4 dạng bài học
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
      {
        "title": "Tiêu đề phần",
        "content": "Nội dung chi tiết (có thể dài)",
        "examples": [
          { "type": "real_world_scenario", "title": "Tiêu đề ví dụ", "content": "Nội dung ví dụ chi tiết" }
        ]
      }
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
- text: Tạo 3-4 sections nội dung chi tiết, mỗi section có 1-2 examples (loại: real_world_scenario, everyday_analogy, step_by_step, comparison, story_narrative), 2 inlineQuizzes, summary, 3 learningObjectives, endQuiz 5 câu
- Mỗi endQuiz có ĐÚNG 5 câu hỏi, mỗi câu 4 đáp án
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

  // Inject media URLs
  if (data.image_quiz?.slides) {
    data.image_quiz.slides = data.image_quiz.slides.map(
      (slide: any, i: number) => ({
        ...slide,
        imageUrl: imageUrl(`${imgBase}-quiz-${i}`),
      }),
    );
  }
  if (data.image_gallery?.images) {
    data.image_gallery.images = data.image_gallery.images.map(
      (img: any, i: number) => ({
        ...img,
        url: imageUrl(`${imgBase}-gallery-${i}`),
      }),
    );
  }
  if (data.video) {
    data.video.videoUrl = videoUrl(nodeIndex);
  }

  const result: Record<string, { lessonData: any; endQuiz: any }> = {};

  result['image_quiz'] = {
    lessonData: { slides: data.image_quiz?.slides || [] },
    endQuiz: data.image_quiz?.endQuiz || { questions: [], passingScore: 70 },
  };
  result['image_gallery'] = {
    lessonData: { images: data.image_gallery?.images || [] },
    endQuiz:
      data.image_gallery?.endQuiz || { questions: [], passingScore: 70 },
  };
  result['video'] = {
    lessonData: {
      videoUrl: data.video?.videoUrl || '',
      summary: data.video?.summary || '',
      keyPoints: data.video?.keyPoints || [],
      keywords: data.video?.keywords || [],
    },
    endQuiz: data.video?.endQuiz || { questions: [], passingScore: 70 },
  };
  result['text'] = {
    lessonData: {
      sections: data.text?.sections || [],
      inlineQuizzes: data.text?.inlineQuizzes || [],
      summary: data.text?.summary || '',
      learningObjectives: data.text?.learningObjectives || [],
    },
    endQuiz: data.text?.endQuiz || { questions: [], passingScore: 70 },
  };

  return result;
}

// Tạo domain/topic/node cho 1 subject theo cấu trúc auto (3 domain x 3 topic x 6 node = 54 bài)
async function createAutoDomainsForSubject(
  subjectId: string,
  subjectName: string,
  subjectIcon: string,
  domainsService: any,
  topicsService: any,
  lessonTypeContentsService: any,
  aiService: AiService,
  nodeRepo: Repository<LearningNode>,
  startNodeIndex: number,
): Promise<number> {
  let globalNodeIndex = startNodeIndex;

  const domainDefs: DomainDef[] = [
    {
      name: `Cơ bản ${subjectName}`,
      description: `Những khái niệm cơ bản nhất cho người mới bắt đầu môn ${subjectName}.`,
      order: 0,
      difficulty: 'easy',
      expReward: 600,
      coinReward: 200,
      icon: subjectIcon,
      topics: [],
    },
    {
      name: `Ứng dụng thực tế ${subjectName}`,
      description: `Ứng dụng ${subjectName} vào các tình huống đời sống và công việc thực tế.`,
      order: 1,
      difficulty: 'medium',
      expReward: 800,
      coinReward: 300,
      icon: subjectIcon,
      topics: [],
    },
    {
      name: `Nâng cao & chuyên sâu ${subjectName}`,
      description: `Các chủ đề nâng cao và chuyên sâu, phù hợp người đã có nền tảng ${subjectName}.`,
      order: 2,
      difficulty: 'hard',
      expReward: 900,
      coinReward: 350,
      icon: subjectIcon,
      topics: [],
    },
  ];

  // Auto-generate topics + nodes
  for (const domain of domainDefs) {
    const topics: TopicDef[] = [];
    for (let t = 0; t < 3; t++) {
      const topicIndex = t + 1;
      const topicName = `Chủ đề ${topicIndex} - ${subjectName}`;
      const topicDesc =
        domain.order === 0
          ? `Giới thiệu các khái niệm nền tảng của ${subjectName} (phần ${topicIndex}).`
          : domain.order === 1
          ? `Ứng dụng ${subjectName} trong các bối cảnh thực tế (phần ${topicIndex}).`
          : `Các kỹ thuật/chủ đề nâng cao của ${subjectName} (phần ${topicIndex}).`;

      const topicDef: TopicDef = {
        name: topicName,
        description: topicDesc,
        order: topicIndex - 1,
        difficulty: domain.difficulty,
        expReward: 300,
        coinReward: 120,
        nodes: [],
      };

      // 6 bài / topic
      for (let n = 0; n < 6; n++) {
        const nodeOrder = n;
        const nodeNumber = topicIndex * 10 + n + 1;
        const nodeTitle =
          domain.order === 0
            ? `Bài ${nodeNumber}: Khái niệm ${subjectName} - phần ${nodeNumber}`
            : domain.order === 1
            ? `Bài ${nodeNumber}: Ứng dụng ${subjectName} trong thực tế - phần ${nodeNumber}`
            : `Bài ${nodeNumber}: Chủ đề nâng cao ${subjectName} - phần ${nodeNumber}`;

        const nodeDesc =
          domain.order === 0
            ? `Giải thích chi tiết một khái niệm nền tảng quan trọng trong ${subjectName}.`
            : domain.order === 1
            ? `Phân tích một tình huống ứng dụng ${subjectName} trong đời sống hoặc công việc.`
            : `Trình bày một kỹ thuật/chủ đề nâng cao trong ${subjectName} với ví dụ minh họa.`;

        const nodeDef: NodeDef = {
          title: nodeTitle,
          description: nodeDesc,
          order: nodeOrder,
          difficulty:
            domain.order === 0 ? 'easy' : domain.order === 1 ? 'medium' : 'hard',
          type:
            domain.order === 0
              ? 'theory'
              : domain.order === 1
              ? 'practice'
              : 'assessment',
          expReward: domain.order === 0 ? 50 : domain.order === 1 ? 70 : 90,
          coinReward: domain.order === 0 ? 20 : domain.order === 1 ? 25 : 30,
        };
        topicDef.nodes.push(nodeDef);
      }
      topics.push(topicDef);
    }
    domain.topics = topics;
  }

  // Tạo domain/topic/node + generate nội dung
  for (const domainDef of domainDefs) {
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
            icon: subjectIcon,
            position: {
              x: nodeDef.order * 220,
              y: domainDef.order * 320 + topicDef.order * 160,
            },
          },
        });
        const savedNode = await nodeRepo.save(node);
        console.log(`        ✅ Node ID: ${savedNode.id}`);

        try {
          const allTypes = await generateAllLessonTypes(
            aiService,
            subjectName,
            nodeDef.title,
            nodeDef.description,
            globalNodeIndex,
          );
          const types: Array<'image_quiz' | 'image_gallery' | 'video' | 'text'> =
            ['image_quiz', 'image_gallery', 'video', 'text'];
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
          // Set text làm lessonType chính (để tương thích các chỗ cũ nếu còn dùng)
          savedNode.lessonType = 'text';
          savedNode.lessonData = allTypes['text']?.lessonData || {};
          savedNode.endQuiz = allTypes['text']?.endQuiz || null;
          await nodeRepo.save(savedNode);
        } catch (err: any) {
          console.log(
            `        ❌ AI generation failed: ${err.message?.substring(
              0,
              120,
            )}`,
          );
        }

        globalNodeIndex++;
      }
    }
  }

  return globalNodeIndex;
}

async function seedAdvancedSubjects() {
  console.log('═══════════════════════════════════════════════════');
  console.log('  SEED: Tạo thêm bài học cho các môn chuyên sâu');
  console.log('═══════════════════════════════════════════════════\n');

  const app = await NestFactory.createApplicationContext(AppModule);

  const subjectsService = app.get(SubjectsService);
  const domainsService = app.get(DomainsService);
  const topicsService = app.get(TopicsService);
  const lessonTypeContentsService = app.get(LessonTypeContentsService);
  const aiService = app.get(AiService);
  const nodeRepo = app.get<Repository<LearningNode>>(
    getRepositoryToken(LearningNode),
  );
  const subjectRepo = app.get<Repository<Subject>>(getRepositoryToken(Subject));

  let globalNodeIndex = 0;

  for (const plan of SUBJECT_PLANS) {
    console.log('\n---------------------------------------------------');
    console.log(`📚 MÔN: ${plan.name}`);
    console.log('---------------------------------------------------');

    const subject = await subjectRepo.findOne({
      where: { name: plan.name },
    });

    if (!subject) {
      console.log(
        `  ❌ Không tìm thấy subject "${plan.name}" (hãy chạy seed-new-subjects.ts trước).`,
      );
      continue;
    }

    console.log(`  ✅ Subject ID: ${subject.id}`);

    // Kiểm tra nếu đã có nhiều learning_nodes rồi thì cảnh báo (tránh seed trùng)
    const existingCount = await nodeRepo.count({
      where: { subjectId: subject.id },
    });
    if (existingCount > 0) {
      console.log(
        `  ⚠️  Subject "${plan.name}" đã có ${existingCount} learning_nodes. Vẫn tiếp tục thêm mới (không xóa cũ).`,
      );
    }

    const before = globalNodeIndex;
    globalNodeIndex = await createAutoDomainsForSubject(
      subject.id,
      plan.name,
      plan.icon,
      domainsService,
      topicsService,
      lessonTypeContentsService,
      aiService,
      nodeRepo,
      globalNodeIndex,
    );
    const added = globalNodeIndex - before;
    console.log(`\n  📊 ĐÃ TẠO THÊM ${added} BÀI HỌC CHO "${plan.name}"`);
  }

  console.log('\n═══════════════════════════════════════════════════');
  console.log('  ✅ SEED HOÀN THÀNH!');
  console.log(`  Tổng số nodes tạo thêm: ${globalNodeIndex}`);
  console.log('═══════════════════════════════════════════════════\n');

  await app.close();
}

seedAdvancedSubjects().catch((err) => {
  console.error('❌ Seed thất bại:', err);
  process.exit(1);
});

