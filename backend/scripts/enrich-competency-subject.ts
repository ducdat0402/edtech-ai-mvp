import 'dotenv/config';
import { Client } from 'pg';
import { randomUUID } from 'crypto';

const SUBJECT_ID = process.argv.includes('--subject-id')
  ? process.argv[process.argv.indexOf('--subject-id') + 1]
  : 'db4f26fe-a555-43e5-b80c-0d75fd6100ff';

const LESSON_TITLES = [
  'Đặt vấn đề và phạm vi quyết định',
  'Xác định tiêu chí đánh giá',
  'Thu thập và kiểm chứng bằng chứng',
  'Nhận diện giả định ẩn',
  'So sánh phương án theo trade-off',
  'Tư duy hệ thống và tác động dây chuyền',
  'Ưu tiên hóa khi nguồn lực hạn chế',
  'Đánh giá rủi ro và phương án dự phòng',
  'Phản biện lập luận phổ biến',
  'Ra quyết định trong tình huống mơ hồ',
  'Theo dõi kết quả sau quyết định',
  'Điều chỉnh chiến lược theo phản hồi',
];

const LOGIC_TYPE_BANK = [
  'inference',
  'compare',
  'sequence',
  'assumption_check',
  'source_reliability',
  'argument_strength',
  'counterexample',
] as const;

type Q = {
  question: string;
  options: Array<{ text: string; explanation: string }>;
  correctAnswer: number;
  logicTypes: string[];
  competencyMix: Record<string, number>;
};

type QuestionTemplate = {
  stem: string;
  options: string[];
  correctAnswer: number;
  explanation: string;
};

function mix(seed: number): Record<string, number> {
  const variants = [
    { logical_thinking: 0.25, practical_application: 0.2, systems_thinking: 0.2, creativity: 0.1, critical_thinking: 0.25 },
    { logical_thinking: 0.2, practical_application: 0.15, systems_thinking: 0.2, creativity: 0.1, critical_thinking: 0.35 },
    { logical_thinking: 0.2, practical_application: 0.2, systems_thinking: 0.3, creativity: 0.1, critical_thinking: 0.2 },
    { logical_thinking: 0.25, practical_application: 0.25, systems_thinking: 0.15, creativity: 0.1, critical_thinking: 0.25 },
  ];
  return variants[seed % variants.length];
}

function makeQuestion(title: string, idx: number): Q {
  const logicA = LOGIC_TYPE_BANK[idx % LOGIC_TYPE_BANK.length];
  const logicB = LOGIC_TYPE_BANK[(idx + 2) % LOGIC_TYPE_BANK.length];
  const templates: QuestionTemplate[] = [
    {
      stem: 'Khi mở đầu bài toán quyết định, hành động nào hợp lý nhất?',
      options: [
        'Chốt luôn phương án quen thuộc để tiết kiệm thời gian',
        'Làm rõ mục tiêu, ràng buộc và tiêu chí đánh giá',
        'Đợi người khác quyết định trước rồi làm theo',
        'Trì hoãn đến khi có đủ 100% dữ liệu',
      ],
      correctAnswer: 1,
      explanation: 'Đặt khung mục tiêu-ràng buộc-tiêu chí giúp quyết định có cơ sở ngay từ đầu.',
    },
    {
      stem: 'Khi hai nguồn dữ liệu mâu thuẫn nhau, cách xử lý nào tốt hơn?',
      options: [
        'Chọn nguồn trùng với niềm tin sẵn có',
        'Bỏ cả hai nguồn vì quá rối',
        'Đánh giá độ tin cậy từng nguồn và kiểm tra chéo',
        'Chọn nguồn có ngôn từ thuyết phục hơn',
      ],
      correctAnswer: 2,
      explanation: 'Đánh giá nguồn và kiểm tra chéo giúp giảm thiên lệch xác nhận.',
    },
    {
      stem: 'Khi so sánh 3 phương án đều có ưu/nhược điểm, nên làm gì?',
      options: [
        'Lập bảng trade-off theo tiêu chí ưu tiên',
        'Ưu tiên phương án rẻ nhất trong mọi tình huống',
        'Ưu tiên phương án quen tay nhất',
        'Chọn ngẫu nhiên để tiết kiệm thời gian',
      ],
      correctAnswer: 0,
      explanation: 'Bảng trade-off giúp so sánh minh bạch giữa lợi ích và chi phí.',
    },
    {
      stem: 'Dấu hiệu nào cho thấy một lập luận còn yếu?',
      options: [
        'Nêu giả định và giới hạn kết luận',
        'Kết luận chắc chắn nhưng thiếu dữ kiện',
        'Trình bày phản ví dụ và phản biện',
        'Dẫn nguồn dữ liệu rõ ràng',
      ],
      correctAnswer: 1,
      explanation: 'Kết luận mạnh nhưng thiếu dữ kiện là lỗi lập luận phổ biến.',
    },
    {
      stem: 'Nếu quyết định A có thể gây hệ quả dây chuyền, bạn nên?',
      options: [
        'Xem từng phần tách rời để giảm phức tạp',
        'Bỏ qua tác động bậc hai vì khó đo',
        'Lập bản đồ nguyên nhân-kết quả trước khi chốt',
        'Chỉ tập trung mục tiêu ngắn hạn',
      ],
      correctAnswer: 2,
      explanation: 'Bản đồ nhân quả giúp nhìn toàn hệ thống và giảm rủi ro phát sinh.',
    },
    {
      stem: 'Sau khi triển khai quyết định, bước tiếp theo nên là gì?',
      options: [
        'Không cần theo dõi thêm nếu đã chốt',
        'Theo dõi chỉ số kết quả và điều chỉnh khi lệch mục tiêu',
        'Đợi có vấn đề lớn mới phản ứng',
        'Đổ lỗi cho bối cảnh nếu kết quả xấu',
      ],
      correctAnswer: 1,
      explanation: 'Vòng theo dõi-điều chỉnh là lõi của quyết định chất lượng cao.',
    },
    {
      stem: 'Khi quyết định trước đó cho kết quả kém, cách cải thiện tốt nhất là?',
      options: [
        'Giữ nguyên cách cũ để nhất quán',
        'Tránh đề tài tương tự để đỡ sai',
        'Rút kinh nghiệm từ giả định sai và thử chiến lược khác',
        'Phụ thuộc hoàn toàn vào ý kiến số đông',
      ],
      correctAnswer: 2,
      explanation: 'Học từ sai lầm và thử chiến lược mới thể hiện tư duy tăng trưởng.',
    },
  ];
  const picked = templates[idx % templates.length];
  return {
    question: `Trong bài "${title}", câu ${idx + 1}: ${picked.stem}`,
    options: picked.options.map((opt, optIdx) => ({
      text: opt,
      explanation:
        optIdx === picked.correctAnswer
          ? picked.explanation
          : 'Phương án này chưa tối ưu theo dữ kiện và ràng buộc của đề bài.',
    })),
    correctAnswer: picked.correctAnswer,
    logicTypes: [logicA, logicB],
    competencyMix: mix(idx),
  };
}

function makeEndQuiz(title: string) {
  const questions = Array.from({ length: 7 }, (_, i) => makeQuestion(title, i));
  // đảm bảo có 2 câu critical_thinking cao cho metric
  questions[1].competencyMix = {
    logical_thinking: 0.15,
    practical_application: 0.1,
    systems_thinking: 0.1,
    creativity: 0.05,
    critical_thinking: 0.6,
  };
  questions[4].competencyMix = {
    logical_thinking: 0.15,
    practical_application: 0.15,
    systems_thinking: 0.1,
    creativity: 0.1,
    critical_thinking: 0.5,
  };
  return { questions, passingScore: 70 };
}

function textLesson(title: string) {
  return {
    sections: [
      { title: `${title} - Bối cảnh`, content: `Mô tả bài toán thực tế cần ra quyết định trong chủ đề "${title}".` },
      { title: `${title} - Mục tiêu`, content: 'Xác định mục tiêu chính, mục tiêu phụ, và các ràng buộc bắt buộc.' },
      { title: `${title} - Tiêu chí`, content: 'Thiết kế tiêu chí đo lường để so sánh phương án minh bạch.' },
      { title: `${title} - Bằng chứng`, content: 'Thu thập dữ liệu, đánh giá độ tin cậy nguồn và mức thiên lệch.' },
      { title: `${title} - Trade-off`, content: 'Phân tích lợi ích/chi phí ngắn hạn và dài hạn của từng phương án.' },
      { title: `${title} - Kế hoạch theo dõi`, content: 'Định nghĩa chỉ số theo dõi sau quyết định và cơ chế điều chỉnh.' },
    ],
    inlineQuizzes: [
      {
        afterSectionIndex: 1,
        question: `Trong "${title}", bước nào nên làm trước khi chọn phương án?`,
        options: [
          { text: 'Chọn phương án trực giác', explanation: 'Thiếu cơ sở đánh giá.' },
          { text: 'Xác định tiêu chí đo lường', explanation: 'Đúng vì tạo khung so sánh rõ.' },
          { text: 'Chọn theo số đông', explanation: 'Không luôn phù hợp mục tiêu.' },
          { text: 'Bỏ qua dữ liệu', explanation: 'Rủi ro sai cao.' },
        ],
        correctAnswer: 1,
      },
      {
        afterSectionIndex: 3,
        question: `Khi nguồn dữ liệu mâu thuẫn trong "${title}", nên làm gì?`,
        options: [
          { text: 'Chọn dữ liệu ủng hộ ý mình', explanation: 'Thiên lệch xác nhận.' },
          { text: 'Đánh giá độ tin cậy từng nguồn', explanation: 'Đúng vì giúp lọc dữ liệu tốt hơn.' },
          { text: 'Loại hết dữ liệu', explanation: 'Mất cơ sở quyết định.' },
          { text: 'Đợi vô thời hạn', explanation: 'Không thực tế.' },
        ],
        correctAnswer: 1,
      },
      {
        afterSectionIndex: 5,
        question: `Sau khi triển khai quyết định trong "${title}", điều gì quan trọng nhất?`,
        options: [
          { text: 'Không cần theo dõi thêm', explanation: 'Thiếu vòng phản hồi.' },
          { text: 'Theo dõi chỉ số và điều chỉnh', explanation: 'Đúng vì tạo học tập liên tục.' },
          { text: 'Đổ lỗi nếu kết quả xấu', explanation: 'Không giúp cải thiện hệ thống.' },
          { text: 'Giữ nguyên dù dữ liệu đổi', explanation: 'Rủi ro sai lệch kéo dài.' },
        ],
        correctAnswer: 1,
      },
    ],
    summary: `Tổng kết bài "${title}" với khung phân tích - phản biện - quyết định.`,
    learningObjectives: [
      'Ra quyết định theo mục tiêu và ràng buộc rõ ràng',
      'Đánh giá bằng chứng và lập luận một cách phản biện',
      'Theo dõi kết quả và điều chỉnh sau quyết định',
    ],
  };
}

function imageQuizData(nodeId: string, title: string) {
  const slideTemplates = [
    {
      question: 'Nhìn dữ kiện trên hình, bước nào nên làm trước khi chốt quyết định?',
      options: [
        { text: 'Chốt theo phương án quen tay', explanation: 'Thiếu khung phân tích rõ ràng.' },
        { text: 'Xác định mục tiêu và ràng buộc chính', explanation: 'Đúng vì tạo nền để so sánh phương án.' },
        { text: 'Làm theo phương án số đông', explanation: 'Không chắc phù hợp bối cảnh hiện tại.' },
        { text: 'Đợi thêm thật nhiều dữ liệu rồi mới làm', explanation: 'Trì hoãn quá mức có thể bỏ lỡ cơ hội.' },
      ],
      correctAnswer: 1,
      hint: 'Bắt đầu từ mục tiêu, ràng buộc rồi mới so sánh lựa chọn.',
    },
    {
      question: 'Dấu hiệu nào trong hình cho thấy lập luận hiện tại chưa vững?',
      options: [
        { text: 'Có nêu rõ nguồn dữ liệu', explanation: 'Đây là điểm tốt của lập luận.' },
        { text: 'Kết luận chắc chắn nhưng thiếu bằng chứng', explanation: 'Đúng vì thiếu cơ sở xác thực.' },
        { text: 'Có so sánh nhiều phương án', explanation: 'Đây là cách tiếp cận hợp lý.' },
        { text: 'Nêu rõ ràng buộc quyết định', explanation: 'Điều này giúp tăng chất lượng quyết định.' },
      ],
      correctAnswer: 1,
      hint: 'Tìm điểm kết luận vượt quá dữ kiện thực tế.',
    },
    {
      question: 'Trong bối cảnh nguồn lực hạn chế ở hình, chọn cách nào hợp lý hơn?',
      options: [
        { text: 'Làm mọi thứ cùng lúc để khỏi bỏ sót', explanation: 'Dễ quá tải và phân tán nguồn lực.' },
        { text: 'Ưu tiên theo tác động và độ khả thi', explanation: 'Đúng vì tối ưu hiệu quả trong giới hạn nguồn lực.' },
        { text: 'Chọn việc dễ nhất trước', explanation: 'Không nhất thiết tạo giá trị cao nhất.' },
        { text: 'Đợi nguồn lực tăng mới triển khai', explanation: 'Có thể làm mất nhịp tiến độ.' },
      ],
      correctAnswer: 1,
      hint: 'Ưu tiên việc có tác động cao và khả thi nhất.',
    },
    {
      question: 'Nếu chọn phương án A trong hình, yếu tố nào cần kiểm tra thêm?',
      options: [
        { text: 'Tác động dây chuyền lên các nhóm liên quan', explanation: 'Đúng vì giúp tránh hệ quả ngoài ý muốn.' },
        { text: 'Mức độ dễ trình bày trong họp', explanation: 'Chưa phải yếu tố quyết định chất lượng.' },
        { text: 'Cảm giác chủ quan của người ra quyết định', explanation: 'Dễ gây thiên lệch.' },
        { text: 'Mức độ hợp xu hướng mạng xã hội', explanation: 'Không phản ánh hiệu quả thật.' },
      ],
      correctAnswer: 0,
      hint: 'Nhìn rộng ra tác động cấp 2, cấp 3 trong hệ thống.',
    },
    {
      question: 'Sau khi triển khai quyết định từ tình huống trong hình, nên làm gì?',
      options: [
        { text: 'Giữ nguyên kế hoạch dù dữ liệu mới xuất hiện', explanation: 'Thiếu cơ chế học hỏi và điều chỉnh.' },
        { text: 'Theo dõi chỉ số chính và điều chỉnh sớm khi lệch mục tiêu', explanation: 'Đúng vì tạo vòng phản hồi liên tục.' },
        { text: 'Chờ đến cuối kỳ mới đánh giá', explanation: 'Phản hồi chậm làm tăng chi phí sai lệch.' },
        { text: 'Đổ lỗi bối cảnh nếu kết quả chưa tốt', explanation: 'Không giúp cải tiến quyết định.' },
      ],
      correctAnswer: 1,
      hint: 'Ra quyết định tốt luôn đi cùng theo dõi và điều chỉnh.',
    },
  ] as const;
  return {
    slides: Array.from({ length: 5 }, (_, i) => ({
      imageUrl: `https://picsum.photos/seed/${nodeId.slice(0, 8)}-iq-${i + 1}/1200/700`,
      question: `${title} - Tình huống hình ảnh ${i + 1}: ${slideTemplates[i].question}`,
      options: slideTemplates[i].options.map((x) => ({ ...x })),
      correctAnswer: slideTemplates[i].correctAnswer,
      hint: slideTemplates[i].hint,
    })),
  };
}

function imageGalleryData(nodeId: string, title: string) {
  return {
    images: Array.from({ length: 6 }, (_, i) => ({
      url: `https://picsum.photos/seed/${nodeId.slice(0, 8)}-ig-${i + 1}/1280/720`,
      description: `${title} - Minh họa ${i + 1}: phân tích tín hiệu, rủi ro và trade-off trong quyết định.`,
    })),
  };
}

function videoData(title: string) {
  return {
    videoUrl:
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
    summary: `${title}: video phân tích tình huống, phản biện lập luận và ra quyết định có cơ sở.`,
    keyPoints: [
      { title: 'Đặt khung bài toán', description: 'Mục tiêu, ràng buộc, tiêu chí', timestamp: 15 },
      { title: 'Đánh giá bằng chứng', description: 'Nguồn tin, độ tin cậy, thiên lệch', timestamp: 45 },
      { title: 'So sánh phương án', description: 'Trade-off và tác động hệ thống', timestamp: 85 },
      { title: 'Quyết định & theo dõi', description: 'Đặt chỉ số và vòng phản hồi', timestamp: 120 },
    ],
    keywords: ['critical thinking', 'evidence', 'decision', 'trade-off', 'systems thinking'],
  };
}

async function ensureStructure(client: Client, subjectId: string) {
  const subjectRs = await client.query(
    `select id, name from subjects where id = $1 limit 1`,
    [subjectId],
  );
  if (!subjectRs.rows.length) throw new Error(`Subject not found: ${subjectId}`);

  let domainId = '';
  const dRs = await client.query(
    `select id from domains where "subjectId" = $1 order by "order" asc limit 1`,
    [subjectId],
  );
  if (dRs.rows.length) {
    domainId = dRs.rows[0].id;
  } else {
    domainId = randomUUID();
    await client.query(
      `insert into domains (id, "subjectId", name, description, "order", difficulty, "expReward", "coinReward", metadata, "createdAt", "updatedAt")
       values ($1, $2, $3, $4, 1, 'medium', 150, 80, $5::jsonb, now(), now())`,
      [
        domainId,
        subjectId,
        'Năng lực quyết định',
        'Domain luyện phân tích, phản biện và cộng tác trong quyết định.',
        JSON.stringify({ icon: '🧭', color: '#6C63FF', estimatedDays: 21 }),
      ],
    );
  }

  let topicId = '';
  const tRs = await client.query(
    `select id from topics where "domainId" = $1 order by "order" asc limit 1`,
    [domainId],
  );
  if (tRs.rows.length) {
    topicId = tRs.rows[0].id;
  } else {
    topicId = randomUUID();
    await client.query(
      `insert into topics (id, "domainId", name, description, "order", difficulty, "expReward", "coinReward", metadata, "createdAt", "updatedAt")
       values ($1, $2, $3, $4, 1, 'medium', 90, 45, $5::jsonb, now(), now())`,
      [
        topicId,
        domainId,
        'Chuỗi bài thực chiến',
        'Topic gồm các bài tập quyết định đa bối cảnh với phản hồi chi tiết.',
        JSON.stringify({ icon: '🧩', color: '#5D5FEF' }),
      ],
    );
  }
  return { domainId, topicId };
}

async function upsertNode(client: Client, params: {
  subjectId: string;
  domainId: string;
  topicId: string;
  order: number;
  title: string;
  prevNodeId?: string;
}) {
  const exist = await client.query(
    `select id from learning_nodes where "subjectId" = $1 and title = $2 limit 1`,
    [params.subjectId, params.title],
  );
  const id = exist.rows[0]?.id ?? randomUUID();
  const endQuiz = makeEndQuiz(params.title);
  const prereq = params.prevNodeId ? [params.prevNodeId] : [];
  const lessonData = textLesson(params.title);
  if (exist.rows.length) {
    await client.query(
      `update learning_nodes
       set "domainId" = $1, "topicId" = $2, "order" = $3, prerequisites = $4::jsonb,
           "lessonType" = 'text', "lessonData" = $5::jsonb, "endQuiz" = $6::jsonb, "updatedAt" = now()
       where id = $7`,
      [
        params.domainId,
        params.topicId,
        params.order,
        JSON.stringify(prereq),
        JSON.stringify(lessonData),
        JSON.stringify(endQuiz),
        id,
      ],
    );
  } else {
    await client.query(
      `insert into learning_nodes (
        id, "subjectId", "domainId", "topicId", title, description, "order", prerequisites,
        "contentStructure", metadata, type, difficulty, "expReward", "coinReward",
        "lessonType", "lessonData", "endQuiz", "createdAt", "updatedAt"
      ) values (
        $1, $2, $3, $4, $5, $6, $7, $8::jsonb,
        $9::jsonb, $10::jsonb, 'theory', 'medium', 35, 12,
        'text', $11::jsonb, $12::jsonb, now(), now()
      )`,
      [
        id,
        params.subjectId,
        params.domainId,
        params.topicId,
        params.title,
        `Bài học chuyên sâu: ${params.title}`,
        params.order,
        JSON.stringify(prereq),
        JSON.stringify({ concepts: 5, examples: 8, hiddenRewards: 0, bossQuiz: 1 }),
        JSON.stringify({ icon: '🧠', position: { x: params.order * 120, y: 0 } }),
        JSON.stringify(lessonData),
        JSON.stringify(endQuiz),
      ],
    );
  }

  const lessonTypeRows = [
    { lessonType: 'image_quiz', lessonData: imageQuizData(id, params.title) },
    { lessonType: 'image_gallery', lessonData: imageGalleryData(id, params.title) },
    { lessonType: 'video', lessonData: videoData(params.title) },
    { lessonType: 'text', lessonData },
  ];
  for (const row of lessonTypeRows) {
    const r = await client.query(
      `select id from lesson_type_contents where "nodeId" = $1 and "lessonType" = $2 limit 1`,
      [id, row.lessonType],
    );
    if (r.rows.length) {
      await client.query(
        `update lesson_type_contents
         set "lessonData" = $1::jsonb, "endQuiz" = $2::jsonb, "updatedAt" = now()
         where id = $3`,
        [JSON.stringify(row.lessonData), JSON.stringify(endQuiz), r.rows[0].id],
      );
    } else {
      await client.query(
        `insert into lesson_type_contents (id, "nodeId", "lessonType", "lessonData", "endQuiz", "createdAt", "updatedAt")
         values ($1, $2, $3, $4::jsonb, $5::jsonb, now(), now())`,
        [randomUUID(), id, row.lessonType, JSON.stringify(row.lessonData), JSON.stringify(endQuiz)],
      );
    }
  }
  return id;
}

async function main() {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) throw new Error('Missing DATABASE_URL');
  if (!SUBJECT_ID) throw new Error('Missing --subject-id');

  const client = new Client({
    connectionString: databaseUrl,
    ssl: { rejectUnauthorized: false },
  });
  await client.connect();
  try {
    const { domainId, topicId } = await ensureStructure(client, SUBJECT_ID);
    let prevNodeId = '';
    for (let i = 0; i < LESSON_TITLES.length; i++) {
      const nodeId = await upsertNode(client, {
        subjectId: SUBJECT_ID,
        domainId,
        topicId,
        order: i + 1,
        title: LESSON_TITLES[i],
        prevNodeId: prevNodeId || undefined,
      });
      prevNodeId = nodeId;
    }
    console.log('✅ Enriched subject to full 4-type lesson structure');
    console.log(`subjectId: ${SUBJECT_ID}`);
    console.log(`total lesson titles ensured: ${LESSON_TITLES.length}`);
  } finally {
    await client.end();
  }
}

main().catch((e) => {
  console.error('Enrich failed:', e);
  process.exit(1);
});

