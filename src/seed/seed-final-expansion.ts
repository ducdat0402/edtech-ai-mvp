/**
 * Seed: Thêm bài học để đạt đủ 60 bài cho IC3 và Bóng rổ
 * - IC3: +1 bài (Living Online)
 * - Bóng rổ: +12 bài (thêm domain "Thi đấu chuyên nghiệp")
 *
 * CÁCH CHẠY:
 *   cd backend
 *   npx ts-node -r tsconfig-paths/register src/seed/seed-final-expansion.ts
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { DomainsService } from '../domains/domains.service';
import { TopicsService } from '../topics/topics.service';
import { LessonTypeContentsService } from '../lesson-type-contents/lesson-type-contents.service';
import { AiService } from '../ai/ai.service';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { Subject } from '../subjects/entities/subject.entity';
import { Domain } from '../domains/entities/domain.entity';

const SAMPLE_VIDEOS = [
  'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  'https://storage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
  'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
];

function imageUrl(seed: string, w = 800, h = 600): string {
  return `https://picsum.photos/seed/${seed}/${w}/${h}`;
}

function videoUrl(index: number): string {
  return SAMPLE_VIDEOS[index % SAMPLE_VIDEOS.length];
}

async function generateAllLessonTypes(
  aiService: AiService,
  subjectName: string,
  nodeTitle: string,
  nodeDescription: string,
  nodeIndex: number,
): Promise<Record<string, { lessonData: any; endQuiz: any }>> {
  const slug = subjectName.toLowerCase().replace(/\s+/g, '-').replace(/[^\w-]/g, '');
  const imgBase = `${slug}-expand-${nodeIndex}`;

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
    "endQuiz": { "questions": [...], "passingScore": 70 }
  },
  "image_gallery": {
    "images": [{ "description": "Mô tả chi tiết" }],
    "endQuiz": { "questions": [...], "passingScore": 70 }
  },
  "video": {
    "summary": "Tóm tắt",
    "keyPoints": [{ "title": "Tiêu đề", "description": "Chi tiết", "timestamp": 0 }],
    "keywords": ["từ khóa"],
    "endQuiz": { "questions": [...], "passingScore": 70 }
  },
  "text": {
    "sections": [
      {
        "title": "Tiêu đề phần",
        "content": "Nội dung chi tiết",
        "examples": [{ "type": "real_world_scenario", "title": "Tiêu đề ví dụ", "content": "Nội dung ví dụ" }]
      }
    ],
    "inlineQuizzes": [{ "afterSectionIndex": 0, "question": "Câu hỏi", "options": [...], "correctAnswer": 0 }],
    "summary": "Tóm tắt",
    "learningObjectives": ["Mục tiêu 1"],
    "endQuiz": { "questions": [...], "passingScore": 70 }
  }
}

YÊU CẦU:
- Mỗi endQuiz có ĐÚNG 5 câu hỏi, mỗi câu 4 đáp án
- text: 3-4 sections, mỗi section 1-2 examples, 2 inlineQuizzes
- Trả về JSON hợp lệ, KHÔNG markdown
`;

  const raw = await aiService.chatWithJsonMode([{ role: 'user', content: prompt }]);
  const data = JSON.parse(raw);

  if (data.image_quiz?.slides) {
    data.image_quiz.slides = data.image_quiz.slides.map((s: any, i: number) => ({ ...s, imageUrl: imageUrl(`${imgBase}-quiz-${i}`) }));
  }
  if (data.image_gallery?.images) {
    data.image_gallery.images = data.image_gallery.images.map((img: any, i: number) => ({ ...img, url: imageUrl(`${imgBase}-gallery-${i}`) }));
  }
  if (data.video) {
    data.video.videoUrl = videoUrl(nodeIndex);
  }

  return {
    image_quiz: { lessonData: { slides: data.image_quiz?.slides || [] }, endQuiz: data.image_quiz?.endQuiz || { questions: [], passingScore: 70 } },
    image_gallery: { lessonData: { images: data.image_gallery?.images || [] }, endQuiz: data.image_gallery?.endQuiz || { questions: [], passingScore: 70 } },
    video: { lessonData: { videoUrl: data.video?.videoUrl || '', summary: data.video?.summary || '', keyPoints: data.video?.keyPoints || [], keywords: data.video?.keywords || [] }, endQuiz: data.video?.endQuiz || { questions: [], passingScore: 70 } },
    text: { lessonData: { sections: data.text?.sections || [], inlineQuizzes: data.text?.inlineQuizzes || [], summary: data.text?.summary || '', learningObjectives: data.text?.learningObjectives || [] }, endQuiz: data.text?.endQuiz || { questions: [], passingScore: 70 } },
  };
}

async function seed() {
  console.log('═══════════════════════════════════════════════════');
  console.log('  SEED FINAL: Thêm bài để đạt 60 bài cho IC3 & Bóng rổ');
  console.log('═══════════════════════════════════════════════════\n');

  const app = await NestFactory.createApplicationContext(AppModule);

  const domainsService = app.get(DomainsService);
  const topicsService = app.get(TopicsService);
  const lessonTypeContentsService = app.get(LessonTypeContentsService);
  const aiService = app.get(AiService);
  const nodeRepo = app.get<Repository<LearningNode>>(getRepositoryToken(LearningNode));
  const subjectRepo = app.get<Repository<Subject>>(getRepositoryToken(Subject));
  const domainRepo = app.get<Repository<Domain>>(getRepositoryToken(Domain));

  let nodeIndex = 1000; // Start from high number to avoid conflicts

  // ═══ PART 1: Thêm 1 bài cho IC3 Living Online ═══
  console.log('\n📘 PART 1: THÊM 1 BÀI CHO IC3 (Living Online)');
  console.log('━'.repeat(50));

  const ic3 = await subjectRepo.findOne({ where: { name: 'IC3' } });
  if (!ic3) {
    console.log('❌ Không tìm thấy IC3');
  } else {
    const livingOnline = await domainRepo.findOne({
      where: { subjectId: ic3.id, name: 'Living Online' },
    });
    if (!livingOnline) {
      console.log('❌ Không tìm thấy domain Living Online');
    } else {
      // Get "An toàn trực tuyến" topic
      const topics = await topicsService.findByDomain(livingOnline.id);
      const securityTopic = topics.find((t: any) => t.name.includes('An toàn'));
      
      if (securityTopic) {
        console.log(`  📌 Topic: ${securityTopic.name}`);
        const node = nodeRepo.create({
          subjectId: ic3.id,
          domainId: livingOnline.id,
          topicId: securityTopic.id,
          title: 'VPN và mạng riêng ảo',
          description: 'VPN là gì, cách hoạt động, khi nào cần dùng VPN, các dịch vụ VPN phổ biến, bảo mật khi dùng Wi-Fi công cộng',
          order: 6,
          type: 'theory',
          difficulty: 'medium',
          expReward: 60,
          coinReward: 25,
          prerequisites: [],
          contentStructure: { concepts: 4, examples: 10, hiddenRewards: 5, bossQuiz: 1 },
          metadata: { icon: '💻', position: { x: 1200, y: 900 } },
        });
        const savedNode = await nodeRepo.save(node);
        console.log(`    ✅ Node: ${savedNode.title} (${savedNode.id})`);

        try {
          const allTypes = await generateAllLessonTypes(aiService, 'IC3', node.title, node.description, nodeIndex++);
          const types: Array<'image_quiz' | 'image_gallery' | 'video' | 'text'> = ['image_quiz', 'image_gallery', 'video', 'text'];
          for (const lt of types) {
            await lessonTypeContentsService.create({
              nodeId: savedNode.id, lessonType: lt, lessonData: allTypes[lt].lessonData, endQuiz: allTypes[lt].endQuiz,
            });
            console.log(`      ✅ ${lt} - OK`);
          }
          savedNode.lessonType = 'text';
          savedNode.lessonData = allTypes['text'].lessonData;
          savedNode.endQuiz = allTypes['text'].endQuiz;
          await nodeRepo.save(savedNode);
        } catch (err: any) {
          console.log(`      ❌ AI failed: ${err.message}`);
        }
      }
    }
  }

  // ═══ PART 2: Thêm domain mới cho Bóng rổ (12 bài) ═══
  console.log('\n🏀 PART 2: THÊM DOMAIN MỚI CHO BÓNG RỔ (12 BÀI)');
  console.log('━'.repeat(50));

  const basketball = await subjectRepo.findOne({ where: { name: 'Bóng rổ' } });
  if (!basketball) {
    console.log('❌ Không tìm thấy Bóng rổ');
  } else {
    console.log(`  ✅ Tìm thấy Bóng rổ: ${basketball.id}`);

    // Create new domain: "Thi đấu chuyên nghiệp"
    const newDomain = await domainsService.create(basketball.id, {
      name: 'Thi đấu chuyên nghiệp',
      description: 'Kiến thức về thi đấu chuyên nghiệp: NBA, các vị trí, chiến thuật đội',
      order: 5,
      difficulty: 'hard',
      expReward: 700,
      coinReward: 300,
      metadata: { icon: '🏆' },
    });
    console.log(`  📂 Domain: ${newDomain.name} (${newDomain.id})`);

    // Topic 1: Các vị trí trong bóng rổ (6 bài)
    const topic1 = await topicsService.create(newDomain.id, {
      name: 'Các vị trí trong bóng rổ',
      description: 'Point Guard, Shooting Guard, Small Forward, Power Forward, Center',
      order: 0,
      difficulty: 'medium',
      expReward: 350,
      coinReward: 140,
    });
    console.log(`    📌 Topic: ${topic1.name}`);

    const positionNodes = [
      { title: 'Point Guard (PG) - Điều phối viên', description: 'Vai trò PG, kỹ năng cần có (dribble, passing, court vision), các PG nổi tiếng (Curry, CP3, Magic)', order: 0, exp: 60, coin: 25 },
      { title: 'Shooting Guard (SG) - Hậu vệ ghi điểm', description: 'Vai trò SG, kỹ năng ném xa, di chuyển không bóng, các SG huyền thoại (Jordan, Kobe, Wade)', order: 1, exp: 60, coin: 25 },
      { title: 'Small Forward (SF) - Tiền đạo cánh', description: 'Vai trò SF, toàn diện nhất, phòng thủ và tấn công, các SF nổi tiếng (LeBron, Durant, Bird)', order: 2, exp: 60, coin: 25 },
      { title: 'Power Forward (PF) - Tiền đạo mạnh', description: 'Vai trò PF, chơi gần rổ, rebound, các PF huyền thoại (Duncan, Nowitzki, Garnett)', order: 3, exp: 60, coin: 25 },
      { title: 'Center (C) - Trung phong', description: 'Vai trò C, chặn bóng, ghi điểm gần rổ, các C vĩ đại (Shaq, Kareem, Hakeem)', order: 4, exp: 60, coin: 25 },
      { title: 'Positionless Basketball', description: 'Xu hướng mới: không phân biệt vị trí rõ ràng, cầu thủ đa năng, ví dụ Warriors', order: 5, exp: 60, coin: 25 },
    ];

    for (const pNode of positionNodes) {
      const node = nodeRepo.create({
        subjectId: basketball.id,
        domainId: newDomain.id,
        topicId: topic1.id,
        title: pNode.title,
        description: pNode.description,
        order: pNode.order,
        type: 'theory',
        difficulty: 'medium',
        expReward: pNode.exp,
        coinReward: pNode.coin,
        prerequisites: [],
        contentStructure: { concepts: 4, examples: 10, hiddenRewards: 5, bossQuiz: 1 },
        metadata: { icon: '🏀', position: { x: pNode.order * 200, y: 1500 } },
      });
      const saved = await nodeRepo.save(node);
      console.log(`      📖 Node: ${saved.title}`);

      try {
        const allTypes = await generateAllLessonTypes(aiService, 'Bóng rổ', pNode.title, pNode.description, nodeIndex++);
        const types: Array<'image_quiz' | 'image_gallery' | 'video' | 'text'> = ['image_quiz', 'image_gallery', 'video', 'text'];
        for (const lt of types) {
          await lessonTypeContentsService.create({
            nodeId: saved.id, lessonType: lt, lessonData: allTypes[lt].lessonData, endQuiz: allTypes[lt].endQuiz,
          });
          console.log(`        ✅ ${lt} - OK`);
        }
        saved.lessonType = 'text';
        saved.lessonData = allTypes['text'].lessonData;
        saved.endQuiz = allTypes['text'].endQuiz;
        await nodeRepo.save(saved);
      } catch (err: any) {
        console.log(`        ❌ AI failed: ${err.message?.substring(0, 80)}`);
      }
    }

    // Topic 2: Chiến thuật đội và phối hợp (6 bài)
    const topic2 = await topicsService.create(newDomain.id, {
      name: 'Chiến thuật đội và phối hợp',
      description: 'Đội hình, rotation, timeout, coaching',
      order: 1,
      difficulty: 'hard',
      expReward: 350,
      coinReward: 140,
    });
    console.log(`    📌 Topic: ${topic2.name}`);

    const teamNodes = [
      { title: 'Đội hình xuất phát (Starting 5)', description: 'Cách chọn đội hình, balance giữa các vị trí, chemistry, matchup', order: 0, exp: 60, coin: 25 },
      { title: 'Rotation và thay người', description: 'Khi nào thay người, quản lý thời gian thi đấu, bench players, load management', order: 1, exp: 60, coin: 25 },
      { title: 'Timeout và chiến thuật', description: 'Khi nào gọi timeout, vẽ chiến thuật, ATO (After TimeOut) plays, last-second plays', order: 2, exp: 70, coin: 30 },
      { title: 'Giao tiếp trên sân', description: 'Call out defense, communication, hand signals, team chemistry', order: 3, exp: 60, coin: 25 },
      { title: 'Scouting và phân tích đối thủ', description: 'Xem video đối thủ, tìm điểm yếu, game plan, adjustments', order: 4, exp: 70, coin: 30 },
      { title: 'Coaching và leadership', description: 'Vai trò HLV, captain, motivate đội, halftime adjustments, Phil Jackson vs Popovich', order: 5, exp: 70, coin: 30 },
    ];

    for (const tNode of teamNodes) {
      const node = nodeRepo.create({
        subjectId: basketball.id,
        domainId: newDomain.id,
        topicId: topic2.id,
        title: tNode.title,
        description: tNode.description,
        order: tNode.order,
        type: 'theory',
        difficulty: 'hard',
        expReward: tNode.exp,
        coinReward: tNode.coin,
        prerequisites: [],
        contentStructure: { concepts: 4, examples: 10, hiddenRewards: 5, bossQuiz: 1 },
        metadata: { icon: '🏀', position: { x: tNode.order * 200, y: 1800 } },
      });
      const saved = await nodeRepo.save(node);
      console.log(`      📖 Node: ${saved.title}`);

      try {
        const allTypes = await generateAllLessonTypes(aiService, 'Bóng rổ', tNode.title, tNode.description, nodeIndex++);
        const types: Array<'image_quiz' | 'image_gallery' | 'video' | 'text'> = ['image_quiz', 'image_gallery', 'video', 'text'];
        for (const lt of types) {
          await lessonTypeContentsService.create({
            nodeId: saved.id, lessonType: lt, lessonData: allTypes[lt].lessonData, endQuiz: allTypes[lt].endQuiz,
          });
          console.log(`        ✅ ${lt} - OK`);
        }
        saved.lessonType = 'text';
        saved.lessonData = allTypes['text'].lessonData;
        saved.endQuiz = allTypes['text'].endQuiz;
        await nodeRepo.save(saved);
      } catch (err: any) {
        console.log(`        ❌ AI failed: ${err.message?.substring(0, 80)}`);
      }
    }
  }

  console.log('\n═══════════════════════════════════════════════════');
  console.log('  ✅ SEED HOÀN THÀNH!');
  console.log('  IC3: +1 bài (tổng 60)');
  console.log('  Bóng rổ: +12 bài (tổng 60)');
  console.log('═══════════════════════════════════════════════════\n');

  await app.close();
}

seed().catch((err) => {
  console.error('❌ Seed thất bại:', err);
  process.exit(1);
});
