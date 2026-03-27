import 'dotenv/config';
import { Client } from 'pg';
import { randomUUID } from 'crypto';

type SubjectRow = { id: string; name: string };
type DomainRow = { id: string; name: string; order: number };
type TopicRow = { id: string; domainId: string; name: string; order: number };
type NodeRow = { id: string; title: string };

const TARGET_LESSONS_PER_SUBJECT = Number(process.env.SEED_TARGET_LESSONS ?? 60);
const MIN_DOMAINS_PER_SUBJECT = Number(process.env.SEED_MIN_DOMAINS ?? 3);
const TOPICS_PER_DOMAIN = Number(process.env.SEED_TOPICS_PER_DOMAIN ?? 5);
const QUIZ_QUESTIONS_PER_LESSON = 7;

const DOMAIN_THEMES = [
  'Nền tảng tư duy',
  'Phân tích và đánh giá',
  'Ứng dụng thực chiến',
  'Ra quyết định hợp tác',
  'Tối ưu liên tục',
];

const TOPIC_THEMES = [
  'Xác định mục tiêu và ràng buộc',
  'Đọc dữ liệu và bằng chứng',
  'So sánh phương án và trade-off',
  'Nhìn hệ thống và tác động dây chuyền',
  'Theo dõi, phản hồi và cải tiến',
  'Tư duy phản biện tình huống',
  'Ra quyết định khi thiếu thông tin',
  'Ưu tiên nguồn lực giới hạn',
  'Quản trị rủi ro và dự phòng',
  'Cộng tác và thuyết phục nhóm',
];

const LESSON_PATTERNS = [
  'Bài thực hành',
  'Case study',
  'Tình huống mô phỏng',
  'Phân tích sai lầm phổ biến',
  'Khung áp dụng nhanh',
  'Bài tập phản biện',
  'Bản đồ quyết định',
  'Checklist hành động',
  'Kịch bản đa phương án',
  'Tổng hợp chiến lược',
];

const SCENARIOS = [
  'dự án học nhóm trễ tiến độ',
  'chiến dịch truyền thông có ngân sách thấp',
  'ra mắt tính năng mới với dữ liệu chưa đầy đủ',
  'xung đột ưu tiên giữa hai phòng ban',
  'chọn nhà cung cấp trong thời gian gấp',
  'điều chỉnh kế hoạch khi KPI giảm',
  'quyết định mở rộng sản phẩm sang thị trường mới',
  'phản hồi khách hàng trái chiều sau bản cập nhật',
  'sự cố vận hành cần xử lý trong 24 giờ',
  'phân bổ nhân sự cho nhiều đầu việc cùng lúc',
];

const LOGIC_TYPES = [
  'inference',
  'compare',
  'sequence',
  'assumption_check',
  'source_reliability',
  'argument_strength',
  'counterexample',
] as const;

type Option = { text: string; explanation: string };

function competencyMix(seed: number): Record<string, number> {
  const bank = [
    {
      logical_thinking: 0.25,
      practical_application: 0.2,
      systems_thinking: 0.2,
      creativity: 0.1,
      critical_thinking: 0.25,
    },
    {
      logical_thinking: 0.2,
      practical_application: 0.15,
      systems_thinking: 0.25,
      creativity: 0.1,
      critical_thinking: 0.3,
    },
    {
      logical_thinking: 0.2,
      practical_application: 0.25,
      systems_thinking: 0.2,
      creativity: 0.1,
      critical_thinking: 0.25,
    },
    {
      logical_thinking: 0.2,
      practical_application: 0.2,
      systems_thinking: 0.3,
      creativity: 0.1,
      critical_thinking: 0.2,
    },
  ];
  return bank[seed % bank.length];
}

function makeQuizQuestion(title: string, scenario: string, idx: number) {
  const logicA = LOGIC_TYPES[idx % LOGIC_TYPES.length];
  const logicB = LOGIC_TYPES[(idx + 2) % LOGIC_TYPES.length];
  const pattern = idx % 7;

  const templates = [
    {
      stem: `Bước đầu tiên để xử lý ${scenario} là gì?`,
      options: [
        'Chọn ngay phương án quen thuộc',
        'Làm rõ mục tiêu, ràng buộc và tiêu chí',
        'Đợi toàn bộ dữ liệu hoàn hảo mới bắt đầu',
        'Làm theo ý kiến người nói to nhất',
      ],
      correct: 1,
      explanation: 'Đặt khung mục tiêu-ràng buộc-tiêu chí giúp mọi quyết định sau đó có cơ sở.',
    },
    {
      stem: `Khi dữ liệu về ${scenario} mâu thuẫn, hướng xử lý tốt hơn là?`,
      options: [
        'Ưu tiên dữ liệu hợp với niềm tin sẵn có',
        'Bỏ qua hết dữ liệu để tránh rối',
        'Đánh giá độ tin cậy nguồn và kiểm tra chéo',
        'Chọn dữ liệu mới nhất mà không kiểm chứng',
      ],
      correct: 2,
      explanation: 'Kiểm tra chéo giúp giảm thiên lệch và tăng độ chắc của kết luận.',
    },
    {
      stem: `Khi 3 phương án cho ${scenario} đều có trade-off, bạn nên?`,
      options: [
        'Lập bảng so sánh theo tiêu chí ưu tiên',
        'Chọn phương án dễ triển khai nhất bất kể tác động',
        'Chọn ngẫu nhiên để tiết kiệm thời gian',
        'Đình lại toàn bộ quyết định vô thời hạn',
      ],
      correct: 0,
      explanation: 'Bảng trade-off làm rõ lợi ích-chi phí và tránh quyết định cảm tính.',
    },
    {
      stem: `Dấu hiệu nào cho thấy lập luận về ${scenario} còn yếu?`,
      options: [
        'Có nêu giả định và giới hạn',
        'Kết luận mạnh nhưng thiếu bằng chứng',
        'Đưa thêm phản ví dụ để kiểm tra',
        'Nêu rõ nguồn dữ liệu',
      ],
      correct: 1,
      explanation: 'Kết luận vượt quá dữ kiện là lỗi logic điển hình.',
    },
    {
      stem: `Để tránh hệ quả dây chuyền khi xử lý ${scenario}, nên làm gì?`,
      options: [
        'Tập trung một biến duy nhất cho đơn giản',
        'Bỏ qua tác động bậc hai vì khó đo',
        'Lập bản đồ nguyên nhân-kết quả trong hệ thống',
        'Ưu tiên quyết định nhanh hơn quyết định đúng',
      ],
      correct: 2,
      explanation: 'Bản đồ hệ thống giúp dự đoán tác động lan tỏa và giảm rủi ro.',
    },
    {
      stem: `Sau khi triển khai giải pháp cho ${scenario}, bước tiếp theo là?`,
      options: [
        'Giữ nguyên kế hoạch, không cần theo dõi',
        'Theo dõi KPI và điều chỉnh khi lệch mục tiêu',
        'Chờ đến khi phát sinh sự cố lớn',
        'Đổ lỗi cho bối cảnh nếu kết quả chưa tốt',
      ],
      correct: 1,
      explanation: 'Theo dõi-điều chỉnh tạo vòng học liên tục và tăng chất lượng quyết định.',
    },
    {
      stem: `Khi phương án đầu tiên cho ${scenario} thất bại, bạn nên?`,
      options: [
        'Lặp lại y hệt để giữ nhất quán',
        'Tránh luôn chủ đề tương tự',
        'Xem lại giả định sai và thử chiến lược mới',
        'Giao toàn bộ quyết định cho người khác',
      ],
      correct: 2,
      explanation: 'Học từ sai lầm và thay đổi chiến lược là hành vi cải tiến hiệu quả.',
    },
  ];

  const t = templates[pattern];
  return {
    question: `[${title}] ${t.stem}`,
    options: t.options.map((text: string, optionIdx: number) => ({
      text,
      explanation:
        optionIdx === t.correct
          ? t.explanation
          : 'Phương án này chưa tối ưu theo mục tiêu, ràng buộc và bằng chứng hiện có.',
    })),
    correctAnswer: t.correct,
    logicTypes: [logicA, logicB],
    competencyMix: competencyMix(idx),
  };
}

function makeEndQuiz(title: string, scenario: string) {
  const questions = Array.from({ length: QUIZ_QUESTIONS_PER_LESSON }, (_, i) =>
    makeQuizQuestion(title, scenario, i),
  );
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

function makeTextLessonData(title: string, scenario: string) {
  return {
    sections: [
      {
        title: `${title} - Bối cảnh`,
        content: `Tình huống: ${scenario}. Bài học giúp bạn bóc tách vấn đề trước khi ra quyết định.`,
      },
      {
        title: `${title} - Mục tiêu và ràng buộc`,
        content:
          'Xác định mục tiêu chính/phụ, ràng buộc bắt buộc, và tiêu chí đánh giá kết quả để tránh quyết định mơ hồ.',
      },
      {
        title: `${title} - Bằng chứng và giả định`,
        content:
          'Phân loại dữ liệu theo độ tin cậy, phát hiện giả định ẩn và kiểm tra khả năng thiên lệch xác nhận.',
      },
      {
        title: `${title} - So sánh phương án`,
        content:
          'Lập bảng trade-off giữa lợi ích, chi phí, rủi ro, tác động ngắn hạn-dài hạn để chọn phương án phù hợp.',
      },
      {
        title: `${title} - Theo dõi và điều chỉnh`,
        content:
          'Thiết lập KPI theo dõi sau quyết định, định nghĩa ngưỡng cảnh báo và cơ chế điều chỉnh nhanh.',
      },
    ],
    inlineQuizzes: [
      {
        question: `Trong tình huống "${scenario}", nên bắt đầu từ đâu?`,
        options: [
          { text: 'Chốt nhanh theo kinh nghiệm cũ', explanation: 'Thiếu khung đánh giá rõ.' },
          { text: 'Làm rõ mục tiêu và ràng buộc', explanation: 'Đúng vì tạo nền cho quyết định.' },
          { text: 'Đợi thêm ý kiến số đông', explanation: 'Có thể làm chậm và lệch mục tiêu.' },
          { text: 'Tập trung trình bày đẹp', explanation: 'Không giải quyết cốt lõi bài toán.' },
        ],
        correctAnswer: 1,
      },
      {
        question: `Khi có dữ liệu mâu thuẫn cho "${scenario}", nên làm gì?`,
        options: [
          { text: 'Bỏ qua dữ liệu khó hiểu', explanation: 'Mất thông tin quan trọng.' },
          { text: 'Ưu tiên dữ liệu hợp ý mình', explanation: 'Thiên lệch xác nhận.' },
          { text: 'Đánh giá nguồn và kiểm tra chéo', explanation: 'Đúng vì tăng độ chắc kết luận.' },
          { text: 'Đình toàn bộ quyết định', explanation: 'Không thực tế trong vận hành.' },
        ],
        correctAnswer: 2,
      },
      {
        question: `Sau khi chọn phương án cho "${scenario}", điều gì quan trọng nhất?`,
        options: [
          { text: 'Không cần theo dõi thêm', explanation: 'Thiếu vòng phản hồi.' },
          { text: 'Theo dõi KPI và điều chỉnh', explanation: 'Đúng vì tạo cải tiến liên tục.' },
          { text: 'Đợi sự cố lớn mới xử lý', explanation: 'Chi phí sửa sai cao hơn.' },
          { text: 'Đổ lỗi cho hoàn cảnh', explanation: 'Không tạo năng lực hệ thống.' },
        ],
        correctAnswer: 1,
      },
    ],
    summary: `Tổng kết ${title}: đi từ phân tích vấn đề -> phản biện dữ liệu -> quyết định -> theo dõi cải tiến.`,
    learningObjectives: [
      'Đặt khung mục tiêu và ràng buộc rõ ràng',
      'Đánh giá bằng chứng và kiểm tra giả định',
      'So sánh trade-off giữa các phương án',
      'Theo dõi kết quả và điều chỉnh dựa trên dữ liệu',
    ],
  };
}

function makeImageQuizLessonData(nodeId: string, title: string, scenario: string) {
  const templates = [
    {
      question: `Trong ảnh về "${scenario}", bước nào nên làm trước?`,
      options: [
        { text: 'Chọn ngay phương án quen thuộc', explanation: 'Thiếu khung phân tích.' },
        { text: 'Xác định mục tiêu và ràng buộc', explanation: 'Đúng vì tạo nền quyết định.' },
        { text: 'Đợi thêm thật nhiều dữ liệu', explanation: 'Dễ trì hoãn quá mức.' },
        { text: 'Làm theo số đông', explanation: 'Không chắc phù hợp bối cảnh.' },
      ],
      correctAnswer: 1,
      hint: 'Bắt đầu bằng mục tiêu, ràng buộc, rồi mới so sánh lựa chọn.',
    },
    {
      question: `Dấu hiệu lập luận yếu trong tình huống "${scenario}" là gì?`,
      options: [
        { text: 'Nêu rõ nguồn dữ liệu', explanation: 'Đây là điểm tốt.' },
        { text: 'Có phản ví dụ để kiểm tra', explanation: 'Giúp lập luận chắc hơn.' },
        { text: 'Kết luận mạnh nhưng thiếu dữ kiện', explanation: 'Đúng vì thiếu cơ sở.' },
        { text: 'So sánh nhiều phương án', explanation: 'Đây là cách tiếp cận tốt.' },
      ],
      correctAnswer: 2,
      hint: 'Tìm kết luận vượt quá bằng chứng hiện có.',
    },
    {
      question: `Nếu nguồn lực hạn chế trong "${scenario}", bạn nên?`,
      options: [
        { text: 'Làm mọi việc cùng lúc', explanation: 'Dễ phân tán nguồn lực.' },
        { text: 'Ưu tiên việc có tác động cao và khả thi', explanation: 'Đúng vì tối ưu hiệu quả.' },
        { text: 'Chọn việc dễ trình bày nhất', explanation: 'Không đảm bảo giá trị cao.' },
        { text: 'Đợi đủ nguồn lực mới làm', explanation: 'Có thể bỏ lỡ cơ hội.' },
      ],
      correctAnswer: 1,
      hint: 'Ưu tiên theo tác động và khả thi, không chỉ theo độ dễ.',
    },
    {
      question: `Khi chọn phương án A cho "${scenario}", cần kiểm tra thêm gì?`,
      options: [
        { text: 'Tác động dây chuyền lên các bên liên quan', explanation: 'Đúng vì tránh hệ quả ngoài ý muốn.' },
        { text: 'Mức độ hợp trend mạng xã hội', explanation: 'Không phản ánh hiệu quả thật.' },
        { text: 'Độ hấp dẫn khi thuyết trình', explanation: 'Không phải tiêu chí cốt lõi.' },
        { text: 'Cảm tính của người ra quyết định', explanation: 'Dễ thiên lệch.' },
      ],
      correctAnswer: 0,
      hint: 'Nhìn hệ thống: tác động cấp 2, cấp 3 thường bị bỏ qua.',
    },
    {
      question: `Sau triển khai quyết định cho "${scenario}", nên làm gì tiếp?`,
      options: [
        { text: 'Giữ nguyên dù có dữ liệu mới', explanation: 'Thiếu cải tiến liên tục.' },
        { text: 'Theo dõi chỉ số và điều chỉnh sớm', explanation: 'Đúng vì tạo vòng phản hồi.' },
        { text: 'Chờ đến cuối kỳ mới xem xét', explanation: 'Phản hồi quá chậm.' },
        { text: 'Đổ lỗi nếu kết quả xấu', explanation: 'Không giúp nâng chất hệ thống.' },
      ],
      correctAnswer: 1,
      hint: 'Quyết định tốt luôn đi cùng theo dõi và điều chỉnh.',
    },
  ];

  return {
    slides: templates.map((t, i) => ({
      imageUrl: `https://picsum.photos/seed/${nodeId.slice(0, 8)}-iq-${i + 1}/1200/700`,
      question: `${title}: ${t.question}`,
      options: t.options,
      correctAnswer: t.correctAnswer,
      hint: t.hint,
    })),
  };
}

function makeImageGalleryLessonData(nodeId: string, title: string, scenario: string) {
  const points = [
    'bối cảnh vấn đề',
    'xung đột mục tiêu',
    'dữ liệu và tín hiệu chính',
    'so sánh 2 phương án',
    'rủi ro hệ quả dây chuyền',
    'kế hoạch theo dõi sau quyết định',
  ];
  return {
    images: points.map((point, i) => ({
      url: `https://picsum.photos/seed/${nodeId.slice(0, 8)}-ig-${i + 1}/1280/720`,
      title: `${title} - Minh họa ${i + 1}`,
      description: `Tình huống ${scenario}: hình này tập trung vào ${point} để hỗ trợ phân tích và phản biện.`,
    })),
  };
}

function makeVideoLessonData(title: string, scenario: string) {
  return {
    videoUrl:
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
    summary: `${title}: video phân tích tình huống "${scenario}" theo khung mục tiêu - bằng chứng - trade-off - theo dõi.`,
    keyPoints: [
      { title: 'Đặt khung bài toán', description: 'Mục tiêu, ràng buộc, tiêu chí', timestamp: 15 },
      { title: 'Đọc dữ liệu có kiểm chứng', description: 'Nguồn tin, thiên lệch, giả định', timestamp: 45 },
      { title: 'So sánh phương án', description: 'Trade-off ngắn hạn và dài hạn', timestamp: 80 },
      { title: 'Ra quyết định & điều chỉnh', description: 'KPI theo dõi và vòng phản hồi', timestamp: 120 },
    ],
    keywords: ['critical thinking', 'decision making', 'evidence', 'trade-off', 'systems thinking'],
  };
}

function makeLessonTitle(topicName: string, indexInTopic: number, globalSeed: number) {
  const pattern = LESSON_PATTERNS[(globalSeed + indexInTopic) % LESSON_PATTERNS.length];
  return `${topicName} - ${pattern} ${indexInTopic + 1}`;
}

async function ensureDomain(
  client: Client,
  subject: SubjectRow,
  order: number,
): Promise<DomainRow> {
  const name = `${DOMAIN_THEMES[(order - 1) % DOMAIN_THEMES.length]} ${order}`;
  const id = randomUUID();
  await client.query(
    `insert into domains (id, "subjectId", name, description, "order", difficulty, "expReward", "coinReward", metadata, "createdAt", "updatedAt")
     values ($1, $2, $3, $4, $5, 'medium', 120, 60, $6::jsonb, now(), now())`,
    [
      id,
      subject.id,
      name,
      `Domain ${order} của môn ${subject.name}: luyện năng lực phân tích, phản biện và ra quyết định.`,
      order,
      JSON.stringify({ icon: '🧭', color: '#6C63FF' }),
    ],
  );
  return { id, name, order };
}

async function ensureTopic(
  client: Client,
  domain: DomainRow,
  subjectName: string,
  order: number,
): Promise<TopicRow> {
  const base = TOPIC_THEMES[(order - 1) % TOPIC_THEMES.length];
  const name = `${base} ${order}`;
  const id = randomUUID();
  await client.query(
    `insert into topics (id, "domainId", name, description, "order", difficulty, "expReward", "coinReward", metadata, "createdAt", "updatedAt")
     values ($1, $2, $3, $4, $5, 'medium', 80, 40, $6::jsonb, now(), now())`,
    [
      id,
      domain.id,
      name,
      `Topic ${order} trong ${domain.name} của môn ${subjectName}.`,
      order,
      JSON.stringify({ icon: '🧩', color: '#5D5FEF' }),
    ],
  );
  return { id, domainId: domain.id, name, order };
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
    const subjectsRs = await client.query(
      `select id, name from subjects order by "createdAt" asc`,
    );
    const subjects = subjectsRs.rows as SubjectRow[];
    if (!subjects.length) throw new Error('No subjects found');

    for (const subject of subjects) {
      const domainsRs = await client.query(
        `select id, name, "order" from domains where "subjectId" = $1 order by "order" asc`,
        [subject.id],
      );
      const existingDomains = domainsRs.rows as DomainRow[];
      const domains: DomainRow[] = [...existingDomains];
      while (domains.length < MIN_DOMAINS_PER_SUBJECT) {
        const newDomain = await ensureDomain(client, subject, domains.length + 1);
        domains.push(newDomain);
      }

      const topicsByDomain = new Map<string, TopicRow[]>();
      for (const domain of domains) {
        const topicsRs = await client.query(
          `select id, name, "order", "domainId" from topics where "domainId" = $1 order by "order" asc`,
          [domain.id],
        );
        const domainTopics = topicsRs.rows as TopicRow[];
        const ensured: TopicRow[] = [...domainTopics];
        while (ensured.length < TOPICS_PER_DOMAIN) {
          const newTopic = await ensureTopic(client, domain, subject.name, ensured.length + 1);
          ensured.push(newTopic);
        }
        topicsByDomain.set(domain.id, ensured.slice(0, TOPICS_PER_DOMAIN));
      }

      const countRs = await client.query(
        `select count(*)::int as cnt from learning_nodes where "subjectId" = $1`,
        [subject.id],
      );
      const existingCount = Number(countRs.rows[0]?.cnt ?? 0);
      const needToAdd = Math.max(0, TARGET_LESSONS_PER_SUBJECT - existingCount);
      if (needToAdd === 0) {
        console.log(`• ${subject.name}: already ${existingCount} lessons, skipped`);
        continue;
      }

      const topicsFlat: TopicRow[] = [];
      for (const domain of domains) {
        const arr = topicsByDomain.get(domain.id) ?? [];
        for (const topic of arr) topicsFlat.push(topic);
      }
      if (!topicsFlat.length) throw new Error(`No topics found for subject ${subject.name}`);

      const orderRs = await client.query(
        `select coalesce(max("order"), 0)::int as max_order from learning_nodes where "subjectId" = $1`,
        [subject.id],
      );
      let nextOrder = Number(orderRs.rows[0]?.max_order ?? 0) + 1;
      let prevNodeId = '';
      const lastNodeRs = await client.query(
        `select id from learning_nodes where "subjectId" = $1 order by "order" desc limit 1`,
        [subject.id],
      );
      if (lastNodeRs.rows.length) prevNodeId = String(lastNodeRs.rows[0].id);

      let createdNodes = 0;
      for (let i = 0; i < needToAdd; i++) {
        const topic = topicsFlat[i % topicsFlat.length];
        const scenario = SCENARIOS[(i + existingCount) % SCENARIOS.length];
        const title = makeLessonTitle(topic.name, Math.floor(i / topicsFlat.length), i);
        const nodeId = randomUUID();
        const endQuiz = makeEndQuiz(title, scenario);
        const textData = makeTextLessonData(title, scenario);
        const imgQuizData = makeImageQuizLessonData(nodeId, title, scenario);
        const galleryData = makeImageGalleryLessonData(nodeId, title, scenario);
        const videoData = makeVideoLessonData(title, scenario);
        const prereq = prevNodeId ? [prevNodeId] : [];

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
            nodeId,
            subject.id,
            topic.domainId,
            topic.id,
            title,
            `Bài học thực chiến: ${title} (bối cảnh ${scenario}).`,
            nextOrder,
            JSON.stringify(prereq),
            JSON.stringify({ concepts: 5, examples: 8, hiddenRewards: 0, bossQuiz: 1 }),
            JSON.stringify({ icon: '🧠', position: { x: nextOrder * 50, y: 0 } }),
            JSON.stringify(textData),
            JSON.stringify(endQuiz),
          ],
        );

        const lessonTypes = [
          { lessonType: 'image_quiz', lessonData: imgQuizData },
          { lessonType: 'image_gallery', lessonData: galleryData },
          { lessonType: 'video', lessonData: videoData },
          { lessonType: 'text', lessonData: textData },
        ];
        for (const row of lessonTypes) {
          await client.query(
            `insert into lesson_type_contents (id, "nodeId", "lessonType", "lessonData", "endQuiz", "createdAt", "updatedAt")
             values ($1, $2, $3, $4::jsonb, $5::jsonb, now(), now())`,
            [randomUUID(), nodeId, row.lessonType, JSON.stringify(row.lessonData), JSON.stringify(endQuiz)],
          );
        }

        createdNodes++;
        nextOrder++;
        prevNodeId = nodeId;
      }

      console.log(
        `• ${subject.name}: +${createdNodes} lessons (${existingCount} -> ${existingCount + createdNodes})`,
      );
    }

    console.log('✅ Finished seeding rich lessons for all subjects');
    console.log(`Target lessons/subject: ${TARGET_LESSONS_PER_SUBJECT}`);
    console.log(
      `Rules: min domains ${MIN_DOMAINS_PER_SUBJECT}, topics/domain ${TOPICS_PER_DOMAIN}, 4 lesson types per lesson`,
    );
  } finally {
    await client.end();
  }
}

main().catch((e) => {
  console.error('Seed rich lessons failed:', e);
  process.exit(1);
});
