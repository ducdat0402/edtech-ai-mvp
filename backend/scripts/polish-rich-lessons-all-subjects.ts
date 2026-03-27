import 'dotenv/config';
import { Client } from 'pg';

type SubjectRow = { id: string; name: string };
type NodeRow = {
  id: string;
  title: string;
  order: number;
  subjectName: string;
  domainName: string | null;
  topicName: string | null;
};

const LOGIC_TYPES = [
  'inference',
  'compare',
  'sequence',
  'assumption_check',
  'source_reliability',
  'argument_strength',
  'counterexample',
] as const;

type SubjectPack = {
  scenarios: string[];
  vocab: {
    actor: string;
    resource: string;
    output: string;
    metric: string;
  };
};

const PACKS: Record<string, SubjectPack> = {
  'Bóng rổ': {
    scenarios: [
      'chia phút thi đấu cho đội hình chính và dự bị',
      'chọn chiến thuật phòng ngự khi đối thủ ném 3 điểm tốt',
      'điều chỉnh nhịp tấn công khi bị dẫn điểm cuối trận',
      'phân công kèm người trong tình huống pick-and-roll',
      'xử lý khi đội liên tục turnover ở hiệp 2',
      'lựa chọn thời điểm xin hội ý để ngắt đà đối thủ',
    ],
    vocab: { actor: 'HLV', resource: 'thời gian thi đấu', output: 'chiến thuật', metric: 'hiệu suất ghi điểm' },
  },
  'Lập trình hướng đối tượng': {
    scenarios: [
      'thiết kế class để giảm duplicate code',
      'chọn giữa composition và inheritance cho module mới',
      'tách responsibilities khi class đang quá tải',
      'xử lý bug do coupling chặt giữa các service',
      'mở rộng tính năng mà không phá vỡ API cũ',
      'review code để giảm side effects không mong muốn',
    ],
    vocab: { actor: 'dev team', resource: 'thời gian refactor', output: 'thiết kế class', metric: 'độ ổn định code' },
  },
  'Digital Marketing': {
    scenarios: [
      'phân bổ ngân sách giữa Facebook Ads và Google Ads',
      'chọn thông điệp chính cho landing page mới',
      'tối ưu funnel khi tỷ lệ chuyển đổi giảm',
      'ra quyết định A/B test cho tiêu đề quảng cáo',
      'xử lý mâu thuẫn giữa reach cao nhưng conversion thấp',
      'điều chỉnh chiến dịch theo phản hồi khách hàng',
    ],
    vocab: { actor: 'marketer', resource: 'ngân sách ads', output: 'chiến dịch', metric: 'tỷ lệ chuyển đổi' },
  },
  'Luật dân sự': {
    scenarios: [
      'xác định căn cứ pháp lý trong tranh chấp hợp đồng',
      'đánh giá chứng cứ khi lời khai mâu thuẫn',
      'chọn hướng tư vấn để giảm rủi ro kiện tụng',
      'đối chiếu điều khoản hợp đồng với quy định hiện hành',
      'xử lý tình huống vi phạm nghĩa vụ dân sự',
      'đề xuất phương án thương lượng trước khi khởi kiện',
    ],
    vocab: { actor: 'luật sư', resource: 'hồ sơ chứng cứ', output: 'phương án tư vấn', metric: 'mức độ tuân thủ pháp lý' },
  },
  'Tư duy ra quyết định': {
    scenarios: [
      'ưu tiên mục tiêu khi nguồn lực hạn chế',
      'chọn phương án trong bối cảnh dữ liệu chưa đầy đủ',
      'đánh giá rủi ro hệ quả dây chuyền',
      'cân bằng lợi ích ngắn hạn và dài hạn',
      'điều chỉnh quyết định sau phản hồi thực tế',
      'phản biện giả định ẩn trước khi kết luận',
    ],
    vocab: { actor: 'người ra quyết định', resource: 'nguồn lực giới hạn', output: 'phương án tối ưu', metric: 'độ phù hợp mục tiêu' },
  },
};

function fallbackPack(subjectName: string): SubjectPack {
  return {
    scenarios: [
      `điều chỉnh kế hoạch học tập trong môn ${subjectName}`,
      `xử lý dữ liệu mâu thuẫn khi ra quyết định ở môn ${subjectName}`,
      `chọn phương án phù hợp nhất với mục tiêu môn ${subjectName}`,
      `đánh giá trade-off trong một bài toán của môn ${subjectName}`,
    ],
    vocab: { actor: 'người học', resource: 'thời gian và dữ liệu', output: 'phương án', metric: 'chất lượng kết quả' },
  };
}

function competencyMix(seed: number): Record<string, number> {
  const bank = [
    { logical_thinking: 0.25, practical_application: 0.2, systems_thinking: 0.2, creativity: 0.1, critical_thinking: 0.25 },
    { logical_thinking: 0.2, practical_application: 0.25, systems_thinking: 0.2, creativity: 0.1, critical_thinking: 0.25 },
    { logical_thinking: 0.2, practical_application: 0.15, systems_thinking: 0.25, creativity: 0.1, critical_thinking: 0.3 },
    { logical_thinking: 0.2, practical_application: 0.2, systems_thinking: 0.3, creativity: 0.1, critical_thinking: 0.2 },
  ];
  return bank[seed % bank.length];
}

function makeEndQuiz(title: string, scenario: string, pack: SubjectPack, seed: number) {
  const actor = pack.vocab.actor;
  const metric = pack.vocab.metric;
  const templates = [
    `Trong tình huống "${scenario}", bước đầu tiên của ${actor} nên là gì?`,
    `Khi dữ liệu cho "${scenario}" mâu thuẫn, cách xử lý nào đáng tin hơn?`,
    `Để tối ưu ${metric} trong "${scenario}", lựa chọn nào hợp lý nhất?`,
    `Dấu hiệu nào cho thấy lập luận hiện tại về "${scenario}" còn yếu?`,
    `Nếu quyết định hiện tại có thể gây hệ quả dây chuyền trong "${scenario}", nên làm gì?`,
    `Sau khi triển khai phương án cho "${scenario}", bước theo dõi nào quan trọng nhất?`,
    `Nếu phương án đầu cho "${scenario}" không hiệu quả, cách cải thiện tốt hơn là?`,
  ];

  const optionBanks = [
    [
      'Chốt nhanh theo thói quen cũ',
      'Làm rõ mục tiêu, ràng buộc và tiêu chí đánh giá',
      'Đợi thêm thật nhiều dữ liệu rồi mới bắt đầu',
      'Làm theo ý kiến người nói to nhất',
    ],
    [
      'Chọn dữ liệu hợp niềm tin sẵn có',
      'Bỏ toàn bộ dữ liệu gây tranh cãi',
      'Đánh giá độ tin cậy nguồn và kiểm tra chéo',
      'Ưu tiên nguồn mới nhất mà không kiểm chứng',
    ],
    [
      `Ưu tiên phương án cân bằng tác động và độ khả thi cho ${metric}`,
      'Chọn phương án dễ làm nhất bất kể hệ quả',
      'Chọn ngẫu nhiên để tiết kiệm thời gian',
      'Đình lại quyết định vô thời hạn',
    ],
    [
      'Có nêu giới hạn và giả định',
      'Kết luận mạnh nhưng thiếu bằng chứng',
      'Có phản ví dụ để kiểm tra',
      'Nêu rõ nguồn dữ liệu',
    ],
    [
      'Xem toàn hệ thống bằng bản đồ nguyên nhân-kết quả',
      'Bỏ qua tác động bậc hai vì khó đo',
      'Chỉ tối ưu chỉ số ngắn hạn',
      'Ưu tiên quyết định nhanh hơn quyết định đúng',
    ],
    [
      `Theo dõi KPI liên quan ${metric} và điều chỉnh khi lệch mục tiêu`,
      'Giữ nguyên kế hoạch, không cần đo lường thêm',
      'Chờ phát sinh sự cố lớn mới phản ứng',
      'Đổ lỗi bối cảnh nếu kết quả chưa tốt',
    ],
    [
      'Lặp lại y hệt cách cũ để giữ nhất quán',
      'Rút kinh nghiệm từ giả định sai và thử chiến lược mới',
      'Tránh luôn chủ đề tương tự',
      'Phụ thuộc hoàn toàn vào ý kiến số đông',
    ],
  ];

  const correctAnswers = [1, 2, 0, 1, 0, 0, 1];
  const explanations = [
    'Đặt khung bài toán rõ giúp quyết định nhất quán và có cơ sở.',
    'Kiểm tra chéo nguồn giúp giảm thiên lệch xác nhận.',
    'Cân bằng tác động và khả thi thường tạo kết quả bền vững hơn.',
    'Kết luận vượt dữ kiện là lỗi logic phổ biến.',
    'Nhìn hệ thống giảm rủi ro phát sinh ngoài dự kiến.',
    'Theo dõi-điều chỉnh là lõi của cải tiến liên tục.',
    'Học từ sai lầm và đổi chiến lược giúp tiến bộ thực chất.',
  ];

  const questions = templates.map((stem, i) => {
    const logicA = LOGIC_TYPES[(seed + i) % LOGIC_TYPES.length];
    const logicB = LOGIC_TYPES[(seed + i + 2) % LOGIC_TYPES.length];
    const correct = correctAnswers[i];
    return {
      question: `[${title}] ${stem}`,
      options: optionBanks[i].map((text, idx) => ({
        text,
        explanation:
          idx === correct
            ? explanations[i]
            : 'Phương án này chưa tối ưu theo mục tiêu, ràng buộc và bằng chứng của đề bài.',
      })),
      correctAnswer: correct,
      logicTypes: [logicA, logicB],
      competencyMix: competencyMix(seed + i),
    };
  });

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

function makeTextLessonData(node: NodeRow, scenario: string, pack: SubjectPack) {
  const actor = pack.vocab.actor;
  const resource = pack.vocab.resource;
  const output = pack.vocab.output;
  const metric = pack.vocab.metric;
  return {
    sections: [
      {
        title: `${node.title} - Bối cảnh`,
        content: `Tình huống thực tế: ${scenario}. ${actor} cần đưa ra ${output} trong điều kiện ${resource}.`,
      },
      {
        title: `${node.title} - Khung phân tích`,
        content:
          'Làm rõ mục tiêu, ràng buộc, tiêu chí đo lường, và giả định ẩn trước khi đề xuất phương án.',
      },
      {
        title: `${node.title} - Bằng chứng và phản biện`,
        content:
          'Thu thập dữ liệu từ nhiều nguồn, đánh giá độ tin cậy, tìm phản ví dụ và điểm mù lập luận.',
      },
      {
        title: `${node.title} - Quyết định và trade-off`,
        content:
          'So sánh lợi ích/chi phí ngắn hạn-dài hạn, cân bằng rủi ro, và chọn phương án phù hợp nhất.',
      },
      {
        title: `${node.title} - Theo dõi cải tiến`,
        content: `Thiết kế KPI theo dõi ${metric}, định nghĩa ngưỡng cảnh báo và cơ chế điều chỉnh kịp thời.`,
      },
    ],
    inlineQuizzes: [
      {
        question: `Trong "${scenario}", bước khởi đầu đúng nhất là gì?`,
        options: [
          { text: 'Chọn nhanh theo cảm tính', explanation: 'Thiếu cơ sở đánh giá.' },
          { text: 'Làm rõ mục tiêu và ràng buộc', explanation: 'Đúng vì tạo nền quyết định rõ ràng.' },
          { text: 'Đợi thêm ý kiến số đông', explanation: 'Có thể làm chậm và lệch mục tiêu.' },
          { text: 'Ưu tiên trình bày đẹp', explanation: 'Không giải quyết cốt lõi.' },
        ],
        correctAnswer: 1,
      },
      {
        question: `Khi dữ liệu mâu thuẫn trong "${scenario}", nên làm gì?`,
        options: [
          { text: 'Loại bỏ dữ liệu khó hiểu', explanation: 'Mất thông tin quan trọng.' },
          { text: 'Ưu tiên dữ liệu hợp ý mình', explanation: 'Thiên lệch xác nhận.' },
          { text: 'Đánh giá nguồn và kiểm tra chéo', explanation: 'Đúng vì tăng độ chắc kết luận.' },
          { text: 'Dừng quyết định vô thời hạn', explanation: 'Không thực tế vận hành.' },
        ],
        correctAnswer: 2,
      },
      {
        question: `Sau khi chốt phương án cho "${scenario}", điều gì quan trọng nhất?`,
        options: [
          { text: 'Không cần theo dõi thêm', explanation: 'Thiếu vòng phản hồi.' },
          { text: 'Theo dõi KPI và điều chỉnh', explanation: 'Đúng vì hỗ trợ cải tiến liên tục.' },
          { text: 'Chờ có sự cố lớn mới xử lý', explanation: 'Chi phí sửa sai cao.' },
          { text: 'Đổ lỗi cho hoàn cảnh', explanation: 'Không tạo năng lực hệ thống.' },
        ],
        correctAnswer: 1,
      },
    ],
    summary: `Tổng kết ${node.title}: phân tích vấn đề -> phản biện bằng chứng -> quyết định -> theo dõi điều chỉnh.`,
    learningObjectives: [
      'Xây khung mục tiêu và ràng buộc rõ ràng',
      'Đánh giá bằng chứng và kiểm tra giả định',
      'So sánh trade-off giữa các phương án',
      'Theo dõi KPI và cải tiến quyết định',
    ],
  };
}

function makeImageQuizData(node: NodeRow, scenario: string) {
  const slides = [
    {
      question: `Từ hình minh họa "${scenario}", bước nào nên làm trước?`,
      options: [
        { text: 'Chọn phương án quen thuộc', explanation: 'Thiếu khung phân tích.' },
        { text: 'Xác định mục tiêu và ràng buộc', explanation: 'Đúng vì đặt nền quyết định.' },
        { text: 'Đợi thêm dữ liệu vô hạn', explanation: 'Dễ trì hoãn quá mức.' },
        { text: 'Làm theo số đông', explanation: 'Chưa chắc phù hợp.' },
      ],
      correctAnswer: 1,
      hint: 'Mục tiêu-ràng buộc luôn đi trước lựa chọn phương án.',
    },
    {
      question: `Dấu hiệu nào cho thấy lập luận trong tình huống "${scenario}" còn yếu?`,
      options: [
        { text: 'Nêu nguồn dữ liệu rõ', explanation: 'Đây là điểm tốt.' },
        { text: 'Kết luận mạnh nhưng thiếu dữ kiện', explanation: 'Đúng vì thiếu cơ sở.' },
        { text: 'So sánh nhiều phương án', explanation: 'Đây là cách làm tốt.' },
        { text: 'Nêu ràng buộc rõ ràng', explanation: 'Điểm tích cực của phân tích.' },
      ],
      correctAnswer: 1,
      hint: 'Tìm chỗ kết luận vượt bằng chứng.',
    },
    {
      question: `Khi nguồn lực có hạn trong "${scenario}", nên ưu tiên theo nguyên tắc nào?`,
      options: [
        { text: 'Làm mọi việc cùng lúc', explanation: 'Dễ phân tán nguồn lực.' },
        { text: 'Ưu tiên tác động cao và khả thi', explanation: 'Đúng vì tối ưu hiệu quả.' },
        { text: 'Chọn việc dễ trình bày', explanation: 'Không chắc tạo giá trị.' },
        { text: 'Đợi đủ nguồn lực rồi mới làm', explanation: 'Có thể mất cơ hội.' },
      ],
      correctAnswer: 1,
      hint: 'Ưu tiên theo tác động và độ khả thi trong giới hạn hiện có.',
    },
    {
      question: `Yếu tố hệ thống nào cần kiểm tra thêm trước khi chốt quyết định cho "${scenario}"?`,
      options: [
        { text: 'Tác động dây chuyền lên các bên liên quan', explanation: 'Đúng vì giảm rủi ro phát sinh.' },
        { text: 'Mức độ hợp xu hướng nhất thời', explanation: 'Không phản ánh hiệu quả thật.' },
        { text: 'Độ hấp dẫn khi thuyết trình', explanation: 'Không phải tiêu chí cốt lõi.' },
        { text: 'Cảm giác chủ quan của người quyết định', explanation: 'Dễ thiên lệch.' },
      ],
      correctAnswer: 0,
      hint: 'Nhìn tác động cấp 2, cấp 3 để tránh hệ quả ngoài ý muốn.',
    },
    {
      question: `Sau khi triển khai quyết định trong "${scenario}", nên làm gì ngay?`,
      options: [
        { text: 'Giữ nguyên kế hoạch dù dữ liệu mới', explanation: 'Thiếu cơ chế học liên tục.' },
        { text: 'Theo dõi chỉ số và điều chỉnh sớm', explanation: 'Đúng vì tăng khả năng đạt mục tiêu.' },
        { text: 'Đợi cuối kỳ mới đánh giá', explanation: 'Phản hồi quá chậm.' },
        { text: 'Đổ lỗi nếu kết quả xấu', explanation: 'Không giúp cải tiến.' },
      ],
      correctAnswer: 1,
      hint: 'Quyết định tốt luôn gắn với theo dõi và điều chỉnh.',
    },
  ];

  return {
    slides: slides.map((s, i) => ({
      imageUrl: `https://picsum.photos/seed/${node.id.slice(0, 8)}-polish-iq-${i + 1}/1200/700`,
      question: `${node.title}: ${s.question}`,
      options: s.options,
      correctAnswer: s.correctAnswer,
      hint: s.hint,
    })),
  };
}

function makeImageGalleryData(node: NodeRow, scenario: string) {
  const focuses = [
    'đặt vấn đề và bối cảnh',
    'xung đột mục tiêu',
    'chất lượng bằng chứng',
    'so sánh trade-off',
    'rủi ro hệ quả dây chuyền',
    'chỉ số theo dõi sau quyết định',
  ];
  return {
    images: focuses.map((focus, i) => ({
      url: `https://picsum.photos/seed/${node.id.slice(0, 8)}-polish-ig-${i + 1}/1280/720`,
      title: `${node.title} - Góc nhìn ${i + 1}`,
      description: `Tình huống ${scenario}: hình này nhấn mạnh ${focus} để hỗ trợ quyết định tốt hơn.`,
    })),
  };
}

function makeVideoData(node: NodeRow, scenario: string, pack: SubjectPack) {
  const metric = pack.vocab.metric;
  return {
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
    summary: `${node.title}: video phân tích "${scenario}" theo khung mục tiêu - bằng chứng - trade-off - theo dõi.`,
    keyPoints: [
      { title: 'Đặt khung bài toán', description: 'Mục tiêu, ràng buộc, tiêu chí', timestamp: 15 },
      { title: 'Đánh giá bằng chứng', description: 'Nguồn tin, độ tin cậy, giả định ẩn', timestamp: 45 },
      { title: 'So sánh phương án', description: 'Trade-off và tác động hệ thống', timestamp: 85 },
      { title: 'Ra quyết định và điều chỉnh', description: `Theo dõi ${metric} và cải tiến`, timestamp: 120 },
    ],
    keywords: ['critical thinking', 'decision', 'trade-off', 'evidence', 'systems thinking'],
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
    const subjectsRs = await client.query(
      `select id, name from subjects order by "createdAt" asc`,
    );
    const subjects = subjectsRs.rows as SubjectRow[];
    if (!subjects.length) throw new Error('No subjects found');

    for (let sIdx = 0; sIdx < subjects.length; sIdx++) {
      const subject = subjects[sIdx];
      const pack = PACKS[subject.name] ?? fallbackPack(subject.name);

      const nodesRs = await client.query(
        `select ln.id, ln.title, ln."order", s.name as "subjectName", d.name as "domainName", t.name as "topicName"
         from learning_nodes ln
         join subjects s on s.id = ln."subjectId"
         left join domains d on d.id = ln."domainId"
         left join topics t on t.id = ln."topicId"
         where ln."subjectId" = $1
         order by ln."order" asc`,
        [subject.id],
      );
      const nodes = nodesRs.rows as NodeRow[];
      if (!nodes.length) {
        console.log(`• ${subject.name}: no lessons, skipped`);
        continue;
      }

      let updated = 0;
      for (let i = 0; i < nodes.length; i++) {
        const node = nodes[i];
        const scenario = pack.scenarios[(i + sIdx) % pack.scenarios.length];
        const endQuiz = makeEndQuiz(node.title, scenario, pack, i);
        const textData = makeTextLessonData(node, scenario, pack);
        const imageQuizData = makeImageQuizData(node, scenario);
        const imageGalleryData = makeImageGalleryData(node, scenario);
        const videoData = makeVideoData(node, scenario, pack);

        await client.query(
          `update learning_nodes
           set "lessonData" = $1::jsonb, "endQuiz" = $2::jsonb, "updatedAt" = now()
           where id = $3`,
          [JSON.stringify(textData), JSON.stringify(endQuiz), node.id],
        );

        const mapByType: Record<string, any> = {
          text: textData,
          image_quiz: imageQuizData,
          image_gallery: imageGalleryData,
          video: videoData,
        };
        for (const [lessonType, lessonData] of Object.entries(mapByType)) {
          const existsRs = await client.query(
            `select id from lesson_type_contents where "nodeId" = $1 and "lessonType" = $2 limit 1`,
            [node.id, lessonType],
          );
          if (existsRs.rows.length) {
            await client.query(
              `update lesson_type_contents
               set "lessonData" = $1::jsonb, "endQuiz" = $2::jsonb, "updatedAt" = now()
               where id = $3`,
              [JSON.stringify(lessonData), JSON.stringify(endQuiz), existsRs.rows[0].id],
            );
          }
        }
        updated++;
      }
      console.log(`• ${subject.name}: polished ${updated} lessons with subject-specific content`);
    }

    console.log('✅ Finished subject-specific polish for all lessons');
  } finally {
    await client.end();
  }
}

main().catch((e) => {
  console.error('Polish lessons failed:', e);
  process.exit(1);
});
