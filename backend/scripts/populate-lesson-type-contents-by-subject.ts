import 'dotenv/config';
import { Client } from 'pg';
import { randomUUID } from 'crypto';

type NodeRow = {
  id: string;
  title: string;
  end_quiz: any;
};

function makeImageQuizLessonData(nodeId: string, title: string) {
  return {
    slides: [
      {
        imageUrl: `https://picsum.photos/seed/${nodeId.slice(0, 8)}-a/900/520`,
        question: `${title}: đâu là nhận định hợp lý nhất theo ngữ cảnh?`,
        options: [
          { text: 'Phương án A', explanation: 'A thiếu bằng chứng hỗ trợ.' },
          { text: 'Phương án B', explanation: 'B có cơ sở tốt hơn trong bối cảnh.' },
          { text: 'Phương án C', explanation: 'C bỏ qua ràng buộc chính.' },
          { text: 'Phương án D', explanation: 'D chưa xử lý tác động phụ.' },
        ],
        correctAnswer: 1,
        hint: 'Ưu tiên phương án có bằng chứng và phù hợp ràng buộc.',
      },
      {
        imageUrl: `https://picsum.photos/seed/${nodeId.slice(0, 8)}-b/900/520`,
        question: `Trong bài "${title}", bước nào nên làm trước?`,
        options: [
          { text: 'Chọn nhanh theo trực giác', explanation: 'Thiếu phân tích.' },
          { text: 'Xác định mục tiêu/ràng buộc', explanation: 'Thiết lập khung quyết định đúng.' },
          { text: 'Làm theo số đông', explanation: 'Không đảm bảo phù hợp ngữ cảnh.' },
          { text: 'Bỏ qua tiêu chí đánh giá', explanation: 'Dễ sai lệch quyết định.' },
        ],
        correctAnswer: 1,
        hint: 'Bắt đầu từ mục tiêu và ràng buộc trước khi so sánh lựa chọn.',
      },
    ],
  };
}

function makeImageGalleryLessonData(nodeId: string, title: string) {
  return {
    images: [
      {
        url: `https://picsum.photos/seed/${nodeId.slice(0, 8)}-g1/1200/720`,
        description: `${title}: sơ đồ minh họa mối quan hệ nguyên nhân - kết quả.`,
      },
      {
        url: `https://picsum.photos/seed/${nodeId.slice(0, 8)}-g2/1200/720`,
        description: `${title}: ví dụ so sánh 2 phương án và trade-off.`,
      },
      {
        url: `https://picsum.photos/seed/${nodeId.slice(0, 8)}-g3/1200/720`,
        description: `${title}: checklist đánh giá bằng chứng trước khi kết luận.`,
      },
    ],
  };
}

function makeVideoLessonData(nodeId: string, title: string) {
  return {
    videoUrl: `https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4`,
    summary: `${title}: video tổng hợp cách phân tích, phản biện và chọn phương án phù hợp.`,
    keyPoints: [
      { title: 'Xác định mục tiêu và ràng buộc', description: 'Tránh đánh giá mơ hồ', timestamp: 12 },
      { title: 'So sánh bằng chứng', description: 'Ưu tiên dữ liệu đáng tin', timestamp: 48 },
      { title: 'Chốt phương án + kế hoạch theo dõi', description: 'Có cơ chế điều chỉnh', timestamp: 93 },
    ],
    keywords: ['critical thinking', 'decision making', 'trade-off', 'evidence'],
  };
}

function makeTextLessonData(title: string) {
  return {
    sections: [
      {
        title: `${title} - Khung phân tích`,
        content:
          'Xác định mục tiêu, ràng buộc, tiêu chí đo lường và nguồn dữ liệu trước khi ra quyết định.',
      },
      {
        title: `${title} - So sánh phương án`,
        content:
          'Đánh giá từng phương án theo bằng chứng, trade-off và rủi ro hệ quả dây chuyền.',
      },
      {
        title: `${title} - Điều chỉnh sau phản hồi`,
        content:
          'Theo dõi kết quả thực tế, tìm giả định sai và cập nhật phương án cho lần sau.',
      },
    ],
    inlineQuizzes: [],
    summary: `Tóm tắt ${title}`,
    learningObjectives: [
      'Biết đặt khung đánh giá trước khi quyết định',
      'So sánh phương án theo bằng chứng thay vì cảm tính',
      'Điều chỉnh quyết định khi có dữ liệu mới',
    ],
  };
}

function ensureEndQuiz(endQuiz: any, title: string) {
  if (endQuiz && Array.isArray(endQuiz.questions) && endQuiz.questions.length >= 5) {
    return {
      ...endQuiz,
      passingScore: Number(endQuiz.passingScore) > 0 ? endQuiz.passingScore : 70,
    };
  }
  return {
    passingScore: 70,
    questions: [
      {
        question: `[${title}] Bước đầu tiên khi ra quyết định nên là gì?`,
        options: [
          { text: 'Chọn nhanh theo cảm tính', explanation: 'Thiếu cơ sở phân tích.' },
          { text: 'Xác định mục tiêu/ràng buộc', explanation: 'Đúng vì tạo khung đánh giá rõ.' },
          { text: 'Đợi số đông chọn trước', explanation: 'Không phù hợp mọi ngữ cảnh.' },
          { text: 'Bỏ qua tiêu chí', explanation: 'Dễ dẫn đến quyết định sai.' },
        ],
        correctAnswer: 1,
        logicTypes: ['inference'],
        competencyMix: {
          logical_thinking: 0.3,
          practical_application: 0.2,
          systems_thinking: 0.2,
          creativity: 0.1,
          critical_thinking: 0.2,
        },
      },
      {
        question: `[${title}] Dấu hiệu của lập luận yếu là gì?`,
        options: [
          { text: 'Có dẫn nguồn rõ', explanation: 'Đây là điểm cộng.' },
          { text: 'Có phản ví dụ', explanation: 'Thường giúp lập luận mạnh hơn.' },
          { text: 'Kết luận mạnh nhưng thiếu dữ kiện', explanation: 'Đúng vì thiếu bằng chứng.' },
          { text: 'So sánh nhiều phương án', explanation: 'Đây là cách tiếp cận tốt.' },
        ],
        correctAnswer: 2,
        logicTypes: ['assumption_check', 'source_reliability'],
        competencyMix: {
          logical_thinking: 0.2,
          practical_application: 0.15,
          systems_thinking: 0.15,
          creativity: 0.1,
          critical_thinking: 0.4,
        },
      },
      {
        question: `[${title}] Khi có trade-off, bạn nên làm gì?`,
        options: [
          { text: 'Chọn phương án nhanh nhất', explanation: 'Chưa chắc phù hợp mục tiêu.' },
          { text: 'Lập bảng so sánh theo tiêu chí ưu tiên', explanation: 'Đúng vì minh bạch quyết định.' },
          { text: 'Chọn theo cảm nhận cá nhân', explanation: 'Dễ thiên lệch.' },
          { text: 'Trì hoãn vô thời hạn', explanation: 'Không giải quyết vấn đề.' },
        ],
        correctAnswer: 1,
        logicTypes: ['compare'],
        competencyMix: {
          logical_thinking: 0.25,
          practical_application: 0.25,
          systems_thinking: 0.2,
          creativity: 0.1,
          critical_thinking: 0.2,
        },
      },
      {
        question: `[${title}] Vì sao cần xem tác động dây chuyền?`,
        options: [
          { text: 'Để làm phân tích phức tạp hơn', explanation: 'Không phải mục tiêu chính.' },
          { text: 'Để tránh hệ quả ngoài ý muốn', explanation: 'Đúng vì giúp nhìn hệ thống.' },
          { text: 'Để trì hoãn quyết định', explanation: 'Sai hướng.' },
          { text: 'Để bỏ qua dữ liệu trái chiều', explanation: 'Phản tác dụng.' },
        ],
        correctAnswer: 1,
        logicTypes: ['inference'],
        competencyMix: {
          logical_thinking: 0.2,
          practical_application: 0.15,
          systems_thinking: 0.35,
          creativity: 0.1,
          critical_thinking: 0.2,
        },
      },
      {
        question: `[${title}] Sau khi quyết định sai, hành động nào tốt nhất?`,
        options: [
          { text: 'Bỏ qua và chuyển chủ đề', explanation: 'Mất cơ hội học từ sai lầm.' },
          { text: 'Đổ lỗi hoàn cảnh', explanation: 'Không cải thiện kỹ năng.' },
          { text: 'Xem lại giả định sai và thử chiến lược mới', explanation: 'Đúng vì có điều chỉnh.' },
          { text: 'Giữ nguyên cách cũ', explanation: 'Dễ lặp lại lỗi.' },
        ],
        correctAnswer: 2,
        logicTypes: ['sequence'],
        competencyMix: {
          logical_thinking: 0.25,
          practical_application: 0.2,
          systems_thinking: 0.15,
          creativity: 0.15,
          critical_thinking: 0.25,
        },
      },
    ],
  };
}

function parseArgs(argv: string[]) {
  let subjectId = '';
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--subject-id' && argv[i + 1]) {
      subjectId = argv[i + 1];
      i++;
    }
  }
  return { subjectId };
}

async function main() {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) throw new Error('Missing DATABASE_URL');
  const { subjectId } = parseArgs(process.argv.slice(2));
  if (!subjectId) {
    throw new Error('Missing --subject-id <uuid>');
  }

  const client = new Client({
    connectionString: databaseUrl,
    ssl: { rejectUnauthorized: false },
  });
  await client.connect();
  try {
    const subjectRs = await client.query(
      `select id, name from subjects where id = $1 limit 1`,
      [subjectId],
    );
    if (!subjectRs.rows.length) throw new Error(`Subject not found: ${subjectId}`);

    const nodeRs = await client.query(
      `select id, title, "endQuiz" as end_quiz from learning_nodes where "subjectId" = $1 order by "order" asc`,
      [subjectId],
    );
    const nodes = nodeRs.rows as NodeRow[];
    if (!nodes.length) throw new Error('No learning nodes found for subject');

    let created = 0;
    let updated = 0;
    for (const node of nodes) {
      const endQuiz = ensureEndQuiz(node.end_quiz, node.title);
      const typePayloads = [
        { lessonType: 'image_quiz', lessonData: makeImageQuizLessonData(node.id, node.title) },
        { lessonType: 'image_gallery', lessonData: makeImageGalleryLessonData(node.id, node.title) },
        { lessonType: 'video', lessonData: makeVideoLessonData(node.id, node.title) },
        { lessonType: 'text', lessonData: makeTextLessonData(node.title) },
      ];

      for (const p of typePayloads) {
        const existing = await client.query(
          `select id from lesson_type_contents where "nodeId" = $1 and "lessonType" = $2 limit 1`,
          [node.id, p.lessonType],
        );
        if (existing.rows.length) {
          await client.query(
            `update lesson_type_contents
             set "lessonData" = $1::jsonb, "endQuiz" = $2::jsonb, "updatedAt" = now()
             where id = $3`,
            [JSON.stringify(p.lessonData), JSON.stringify(endQuiz), existing.rows[0].id],
          );
          updated++;
        } else {
          await client.query(
            `insert into lesson_type_contents (id, "nodeId", "lessonType", "lessonData", "endQuiz", "createdAt", "updatedAt")
             values ($1, $2, $3, $4::jsonb, $5::jsonb, now(), now())`,
            [randomUUID(), node.id, p.lessonType, JSON.stringify(p.lessonData), JSON.stringify(endQuiz)],
          );
          created++;
        }
      }
    }

    console.log('✅ Populated lesson_type_contents by subject');
    console.log(`subjectId: ${subjectId}`);
    console.log(`nodes: ${nodes.length}`);
    console.log(`created rows: ${created}`);
    console.log(`updated rows: ${updated}`);
  } finally {
    await client.end();
  }
}

main().catch((e) => {
  console.error('Populate lesson types failed:', e);
  process.exit(1);
});

