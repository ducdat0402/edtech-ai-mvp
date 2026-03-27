import 'dotenv/config';
import { Client } from 'pg';
import { randomUUID } from 'crypto';

type QuizQuestion = {
  question: string;
  options: Array<{ text: string; explanation: string }>;
  correctAnswer: number;
  logicTypes: string[];
  competencyMix: Record<string, number>;
};

const SUBJECT_NAME = 'Tư duy ra quyết định';
const SUBJECT_DESC =
  'Môn học luyện phân tích vấn đề, phản biện và ra quyết định dựa trên bằng chứng.';

function makeQuestion(
  question: string,
  options: string[],
  correctAnswer: number,
  explanation: string,
  logicTypes: string[],
  competencyMix: Record<string, number>,
): QuizQuestion {
  return {
    question,
    options: options.map((t, i) => ({
      text: t,
      explanation: i === correctAnswer ? explanation : 'Phương án này chưa tối ưu trong ngữ cảnh đề bài.',
    })),
    correctAnswer,
    logicTypes,
    competencyMix,
  };
}

function makeEndQuiz(seed: string): { questions: QuizQuestion[]; passingScore: number } {
  const q1 = makeQuestion(
    `[${seed}] Khi đánh giá một phương án, bước nào nên làm trước?`,
    [
      'Chọn phương án quen tay nhất',
      'Xác định mục tiêu và ràng buộc',
      'Hỏi ý kiến ngẫu nhiên',
      'Triển khai ngay để thử vận may',
    ],
    1,
    'Xác định mục tiêu và ràng buộc giúp khung đánh giá rõ ràng trước khi so sánh phương án.',
    ['inference', 'sequence'],
    {
      logical_thinking: 0.25,
      practical_application: 0.2,
      systems_thinking: 0.2,
      creativity: 0.1,
      critical_thinking: 0.25,
    },
  );
  const q2 = makeQuestion(
    `[${seed}] Dấu hiệu nào cho thấy một lập luận yếu?`,
    [
      'Có nêu nguồn bằng chứng',
      'Có nêu phản ví dụ',
      'Kết luận mạnh nhưng thiếu dữ kiện',
      'So sánh nhiều phương án',
    ],
    2,
    'Kết luận mạnh nhưng thiếu dữ kiện là dấu hiệu lập luận chưa đáng tin.',
    ['assumption_check', 'source_reliability'],
    {
      logical_thinking: 0.2,
      practical_application: 0.15,
      systems_thinking: 0.15,
      creativity: 0.1,
      critical_thinking: 0.4,
    },
  );
  const q3 = makeQuestion(
    `[${seed}] Khi một thay đổi có thể gây hiệu ứng dây chuyền, bạn nên làm gì?`,
    [
      'Bỏ qua tác động phụ',
      'Xem riêng từng phần độc lập',
      'Lập bản đồ quan hệ nguyên nhân - kết quả',
      'Ưu tiên giải pháp rẻ nhất',
    ],
    2,
    'Bản đồ quan hệ giúp nhìn toàn cục và giảm rủi ro hệ quả ngoài ý muốn.',
    ['inference', 'compare'],
    {
      logical_thinking: 0.2,
      practical_application: 0.15,
      systems_thinking: 0.35,
      creativity: 0.1,
      critical_thinking: 0.2,
    },
  );
  const q4 = makeQuestion(
    `[${seed}] Nếu cả 2 phương án đều có ưu/nhược rõ ràng, cách chọn tốt hơn là?`,
    [
      'Chọn phương án có vẻ nhanh nhất',
      'Lập bảng trade-off theo tiêu chí ưu tiên',
      'Chọn theo số đông',
      'Giữ nguyên hiện trạng mãi mãi',
    ],
    1,
    'So sánh trade-off theo tiêu chí ưu tiên giúp quyết định minh bạch và có cơ sở.',
    ['compare', 'inference'],
    {
      logical_thinking: 0.25,
      practical_application: 0.25,
      systems_thinking: 0.2,
      creativity: 0.1,
      critical_thinking: 0.2,
    },
  );
  const q5 = makeQuestion(
    `[${seed}] Sau khi quyết định sai, hành động nào thể hiện tư duy tăng trưởng tốt nhất?`,
    [
      'Đổ lỗi cho hoàn cảnh',
      'Ngừng thử lại',
      'Xem lại giả định sai và thử cách tiếp cận mới',
      'Tránh chủ đề tương tự',
    ],
    2,
    'Phân tích sai lầm và thử lại bằng chiến lược mới là hành vi học tập tiến bộ.',
    ['assumption_check', 'sequence'],
    {
      logical_thinking: 0.25,
      practical_application: 0.2,
      systems_thinking: 0.15,
      creativity: 0.15,
      critical_thinking: 0.25,
    },
  );
  return { questions: [q1, q2, q3, q4, q5], passingScore: 70 };
}

function makeLessonData(title: string) {
  return {
    sections: [
      {
        title: `${title} - Khái niệm`,
        content: `Bài học giúp bạn ra quyết định có cấu trúc khi gặp vấn đề trong thực tế.`,
      },
      {
        title: `${title} - Áp dụng`,
        content:
          'Áp dụng khung mục tiêu, ràng buộc, bằng chứng và trade-off để chọn phương án hợp lý.',
      },
    ],
    inlineQuizzes: [],
    summary: `Tổng kết ${title}`,
    learningObjectives: [
      'Xác định mục tiêu và ràng buộc rõ ràng',
      'So sánh phương án theo bằng chứng',
      'Điều chỉnh quyết định sau phản hồi',
    ],
  };
}

async function main() {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) throw new Error('Missing DATABASE_URL');

  const client = new Client({
    connectionString: databaseUrl,
    ssl: { rejectUnauthorized: false },
  });
  await client.connect();
  try {
    const existing = await client.query(
      `select id from subjects where name = $1 limit 1`,
      [SUBJECT_NAME],
    );
    if (existing.rows.length) {
      console.log(`Subject already exists: ${SUBJECT_NAME} [${existing.rows[0].id}]`);
      return;
    }

    const subjectId = randomUUID();
    const domainId = randomUUID();
    const topicId = randomUUID();

    await client.query(
      `insert into subjects (id, name, description, track, metadata, "unlockConditions", "createdAt", "updatedAt")
       values ($1, $2, $3, 'explorer', $4::jsonb, $5::jsonb, now(), now())`,
      [
        subjectId,
        SUBJECT_NAME,
        SUBJECT_DESC,
        JSON.stringify({ icon: '🧠', color: '#6C63FF', estimatedDays: 14 }),
        JSON.stringify({ minCoin: 0 }),
      ],
    );

    await client.query(
      `insert into domains (id, "subjectId", name, description, "order", difficulty, "expReward", "coinReward", metadata, "createdAt", "updatedAt")
       values ($1, $2, $3, $4, 1, 'medium', 120, 60, $5::jsonb, now(), now())`,
      [
        domainId,
        subjectId,
        'Phân tích và ra quyết định',
        'Từ xác định vấn đề đến ra quyết định dựa trên bằng chứng.',
        JSON.stringify({ icon: '📌', color: '#6C63FF', estimatedDays: 10 }),
      ],
    );

    await client.query(
      `insert into topics (id, "domainId", name, description, "order", difficulty, "expReward", "coinReward", metadata, "createdAt", "updatedAt")
       values ($1, $2, $3, $4, 1, 'medium', 80, 40, $5::jsonb, now(), now())`,
      [
        topicId,
        domainId,
        'Khung quyết định thực chiến',
        'Ứng dụng logic, phản biện và hệ thống vào quyết định thực tế.',
        JSON.stringify({ icon: '🧩', color: '#5D5FEF' }),
      ],
    );

    const nodeTitles = [
      'Xác định vấn đề đúng cách',
      'Đánh giá bằng chứng và nguồn tin',
      'So sánh phương án bằng trade-off',
      'Nhìn hệ thống và hệ quả dây chuyền',
      'Điều chỉnh quyết định sau phản hồi',
    ];

    const createdNodeIds: string[] = [];
    for (let i = 0; i < nodeTitles.length; i++) {
      const id = randomUUID();
      const title = nodeTitles[i];
      const prerequisites = i === 0 ? [] : [createdNodeIds[i - 1]];
      const endQuiz = makeEndQuiz(title);
      const lessonData = makeLessonData(title);
      await client.query(
        `insert into learning_nodes (
          id, "subjectId", "domainId", "topicId", title, description, "order", prerequisites,
          "contentStructure", metadata, type, difficulty, "expReward", "coinReward",
          "lessonType", "lessonData", "endQuiz", "createdAt", "updatedAt"
        ) values (
          $1, $2, $3, $4, $5, $6, $7, $8::jsonb,
          $9::jsonb, $10::jsonb, 'theory', 'medium', 30, 10,
          'text', $11::jsonb, $12::jsonb, now(), now()
        )`,
        [
          id,
          subjectId,
          domainId,
          topicId,
          title,
          `Bài học: ${title}`,
          i + 1,
          JSON.stringify(prerequisites),
          JSON.stringify({ concepts: 3, examples: 5, hiddenRewards: 0, bossQuiz: 1 }),
          JSON.stringify({ icon: '🧠', position: { x: i * 120, y: 0 } }),
          JSON.stringify(lessonData),
          JSON.stringify(endQuiz),
        ],
      );
      createdNodeIds.push(id);
    }

    console.log('✅ Created competency-ready subject');
    console.log(`Subject: ${SUBJECT_NAME}`);
    console.log(`subjectId: ${subjectId}`);
    console.log(`domainId: ${domainId}`);
    console.log(`topicId: ${topicId}`);
    console.log(`nodes: ${createdNodeIds.length}`);
  } finally {
    await client.end();
  }
}

main().catch((e) => {
  console.error('Create subject failed:', e);
  process.exit(1);
});

