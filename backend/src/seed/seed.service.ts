import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Subject } from '../subjects/entities/subject.entity';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { ContentItem } from '../content-items/entities/content-item.entity';
import { Question } from '../placement-test/entities/question.entity';
import { DifficultyLevel } from '../placement-test/entities/placement-test.entity';

@Injectable()
export class SeedService {
  constructor(
    @InjectRepository(Subject)
    private subjectRepository: Repository<Subject>,
    @InjectRepository(LearningNode)
    private nodeRepository: Repository<LearningNode>,
    @InjectRepository(ContentItem)
    private contentItemRepository: Repository<ContentItem>,
    @InjectRepository(Question)
    private questionRepository: Repository<Question>,
  ) {}

  async seed() {
    console.log('🌱 Starting seed...');

    // Clear existing data (only if tables exist)
    try {
      const contentItems = await this.contentItemRepository.find();
      if (contentItems.length > 0) {
        await this.contentItemRepository.remove(contentItems);
      }
      
      const nodes = await this.nodeRepository.find();
      if (nodes.length > 0) {
        await this.nodeRepository.remove(nodes);
      }
      
      // Delete all subjects to avoid duplicates
      const subjects = await this.subjectRepository.find();
      if (subjects.length > 0) {
        await this.subjectRepository.remove(subjects);
      }
      
      const questions = await this.questionRepository.find();
      if (questions.length > 0) {
        await this.questionRepository.remove(questions);
      }
    } catch (error) {
      // Tables might not exist yet, that's okay
      console.log('⚠️  Some tables might be empty, continuing...');
    }

    // 1. Create Explorer Subject: IC3 GS6 - Cybersecurity Basics
    const explorerSubject = this.subjectRepository.create({
      name: 'IC3 GS6 - Cybersecurity Basics',
      description: 'Học bảo mật cơ bản một cách thú vị',
      track: 'explorer',
      metadata: {
        icon: '🛡️',
        color: '#4CAF50',
        estimatedDays: 7,
      },
      unlockConditions: {
        minCoin: 0, // Explorer luôn mở
      },
    });
    const savedExplorerSubject = await this.subjectRepository.save(
      explorerSubject,
    );

    // 2. Create Scholar Subject: IC3 GS6 - Advanced Security
    const scholarSubject = this.subjectRepository.create({
      name: 'IC3 GS6 - Advanced Security',
      description: 'Khóa học chuyên sâu về bảo mật',
      track: 'scholar',
      price: 100000, // 100k VND
      metadata: {
        icon: '🔐',
        color: '#2196F3',
        estimatedDays: 30,
      },
      unlockConditions: {
        minCoin: 20, // Cần 20 coin
      },
    });
    const savedScholarSubject = await this.subjectRepository.save(
      scholarSubject,
    );

    // 3. Create Learning Node: "Vệ Sĩ Mật Khẩu"
    const passwordNode = this.nodeRepository.create({
      subjectId: savedExplorerSubject.id,
      title: 'Vệ Sĩ Mật Khẩu',
      description: 'Học cách tạo và bảo vệ mật khẩu an toàn',
      order: 1,
      prerequisites: [],
      contentStructure: {
        concepts: 4,
        examples: 10,
        hiddenRewards: 5,
        bossQuiz: 1,
      },
      metadata: {
        icon: '🔑',
        position: { x: 0, y: 0 },
      },
    });
    const savedPasswordNode = await this.nodeRepository.save(passwordNode);

    // 4. Create Content Items

    // Concepts (4 items)
    const concepts = [
      {
        title: 'Password Complexity',
        content: 'Độ phức tạp mật khẩu: Yêu cầu về ký tự đặc biệt, số, chữ hoa/thường và độ dài.',
        rewards: { xp: 10, coin: 1 },
      },
      {
        title: 'Password Uniqueness',
        content: 'Tại sao không được dùng 1 mật khẩu cho Facebook và Banking? (Rủi ro Credential Stuffing)',
        rewards: { xp: 10, coin: 1 },
      },
      {
        title: 'Multi-Factor Authentication',
        content: 'Bảo mật 2 lớp là gì? (Something you know + Something you have)',
        rewards: { xp: 10, coin: 1 },
      },
      {
        title: 'Password Management',
        content: 'Không được ghi ra giấy, không lưu trên trình duyệt công cộng, nên dùng phần mềm quản lý.',
        rewards: { xp: 10, coin: 1 },
      },
    ];

    for (let i = 0; i < concepts.length; i++) {
      const concept = this.contentItemRepository.create({
        nodeId: savedPasswordNode.id,
        type: 'concept',
        title: concepts[i].title,
        content: concepts[i].content,
        order: i + 1,
        rewards: concepts[i].rewards,
      });
      await this.contentItemRepository.save(concept);
    }

    // Examples (10 items)
    const examples = [
      {
        title: 'Brute Force Attack Demo',
        content: 'Video demo máy tính chạy tool "Brute Force" bẻ khóa pass 6 ký tự trong 1 giây.',
        media: { videoUrl: 'https://example.com/video1.mp4' },
        rewards: { xp: 15, coin: 2 },
      },
      {
        title: 'Password Strength Checker',
        content: 'Tool "Check độ mạnh mật khẩu của bạn" (Nhập thử -> Máy báo bao lâu thì bị hack).',
        media: { interactiveUrl: 'https://example.com/tool1' },
        rewards: { xp: 15, coin: 2, shard: 'security-shard', shardAmount: 1 },
      },
      {
        title: 'Adobe Data Breach Case',
        content: 'Vụ lộ dữ liệu của Adobe (Hàng triệu user mất nick vì đặt pass là "123456").',
        media: { imageUrl: 'https://example.com/image1.jpg' },
        rewards: { xp: 15, coin: 2 },
      },
      {
        title: 'Credential Stuffing Explained',
        content: '"Credential Stuffing" hoạt động thế nào? (Hacker lấy pass cũ thử vào web mới).',
        media: { videoUrl: 'https://example.com/video2.mp4' },
        rewards: { xp: 15, coin: 2 },
      },
      {
        title: 'Find the Security Mistake',
        content: 'Tìm điểm sai trong bức ảnh bàn làm việc (Có tờ giấy note ghi mật khẩu dán trên màn hình).',
        media: { imageUrl: 'https://example.com/image2.jpg' },
        rewards: { xp: 15, coin: 2, shard: 'security-shard', shardAmount: 1 },
      },
      {
        title: '2FA: SMS vs Authenticator',
        content: 'Phân biệt 2FA qua SMS (kém an toàn) và Authenticator App (an toàn hơn).',
        media: { imageUrl: 'https://example.com/image3.jpg' },
        rewards: { xp: 15, coin: 2 },
      },
      {
        title: 'Hardware Keylogger Demo',
        content: 'Demo Keylogger phần cứng gắn sau case máy tính.',
        media: { videoUrl: 'https://example.com/video3.mp4' },
        rewards: { xp: 15, coin: 2 },
      },
      {
        title: 'Create Passphrase',
        content: 'Cách tạo Passphrase (Cụm từ mật khẩu) dễ nhớ: ToiDiLamBangXeBus!',
        media: { videoUrl: 'https://example.com/video4.mp4' },
        rewards: { xp: 15, coin: 2, shard: 'security-shard', shardAmount: 1 },
      },
      {
        title: 'Browser Password Manager Warning',
        content: 'Trình duyệt web hỏi "Save Password?" - Tại sao nên bấm "Never" ở quán Net?',
        media: { videoUrl: 'https://example.com/video5.mp4' },
        rewards: { xp: 15, coin: 2 },
      },
      {
        title: 'Password Manager Tools',
        content: 'Giới thiệu nhanh LastPass/Bitwarden (Nơi cất giữ chìa khóa an toàn).',
        media: { videoUrl: 'https://example.com/video6.mp4' },
        rewards: { xp: 15, coin: 2 },
      },
    ];

    for (let i = 0; i < examples.length; i++) {
      const example = this.contentItemRepository.create({
        nodeId: savedPasswordNode.id,
        type: 'example',
        title: examples[i].title,
        content: examples[i].content,
        media: examples[i].media,
        order: i + 1,
        rewards: examples[i].rewards,
      });
      await this.contentItemRepository.save(example);
    }

    // Hidden Rewards (5 items - sẽ được trigger khi complete examples)
    const hiddenRewards = [
      {
        title: 'Coin Reward #1',
        content: 'Phát hiện Rương Coin! Bạn đã học được cách kiểm tra xem email mình có bị lộ không.',
        rewards: { xp: 5, coin: 5 },
      },
      {
        title: 'Coin Reward #2',
        content: 'Phát hiện Rương Coin! Bạn đã tìm thấy lỗi bảo mật.',
        rewards: { xp: 5, coin: 5 },
      },
      {
        title: 'Shield Item',
        content: 'Nhận Vật phẩm: Khiên Số (Tăng XP trong 1 giờ)',
        rewards: { xp: 10, coin: 3, shard: 'security-shard', shardAmount: 2 },
      },
      {
        title: 'Coin Reward #3',
        content: 'Phát hiện Rương Coin tại mốc 60%!',
        rewards: { xp: 5, coin: 10 },
      },
      {
        title: 'Avatar Fragment',
        content: 'Nhận Mảnh ghép Avatar "Hacker Mũ Trắng" tại mốc 80%!',
        rewards: { xp: 20, coin: 5, shard: 'security-shard', shardAmount: 3 },
      },
    ];

    for (let i = 0; i < hiddenRewards.length; i++) {
      const reward = this.contentItemRepository.create({
        nodeId: savedPasswordNode.id,
        type: 'hidden_reward',
        title: hiddenRewards[i].title,
        content: hiddenRewards[i].content,
        order: i + 1,
        rewards: hiddenRewards[i].rewards,
      });
      await this.contentItemRepository.save(reward);
    }

    // Boss Quiz (1 item)
    const bossQuiz = this.contentItemRepository.create({
      nodeId: savedPasswordNode.id,
      type: 'boss_quiz',
      title: 'BOSS: THE INTERVIEW',
      content: 'Tình huống: Bạn nhận được email từ "Bộ phận IT công ty" yêu cầu cung cấp mật khẩu để bảo trì hệ thống. Email có logo công ty rất chuẩn. Bạn sẽ làm gì?',
      order: 1,
      quizData: {
        question:
          'Bạn nhận được email từ "Bộ phận IT công ty" yêu cầu cung cấp mật khẩu để bảo trì hệ thống. Email có logo công ty rất chuẩn. Bạn sẽ làm gì?',
        options: [
          'Gửi ngay mật khẩu vì sợ bị kỷ luật.',
          'Đổi mật khẩu mới rồi gửi cho họ.',
          'Gọi điện trực tiếp cho phòng IT để xác nhận (Verify out-of-band).',
          'Bấm vào link trong email để reset mật khẩu.',
        ],
        correctAnswer: 2,
        explanation:
          'Đây là kỹ năng chống Social Engineering. Luôn verify qua kênh khác (out-of-band) trước khi cung cấp thông tin nhạy cảm.',
      },
      rewards: {
        xp: 50,
        coin: 10,
        shard: 'security-shard',
        shardAmount: 5,
      },
    });
    await this.contentItemRepository.save(bossQuiz);

    // 3. Create Sample Questions for Placement Test
    const sampleQuestions = [
      // Beginner Questions
      {
        subjectId: savedExplorerSubject.id,
        question: 'Phishing là gì?',
        options: [
          'Một loại virus máy tính',
          'Kỹ thuật lừa đảo qua email/website giả mạo để đánh cắp thông tin',
          'Một loại phần mềm diệt virus',
          'Công nghệ mã hóa dữ liệu',
        ],
        correctAnswer: 1,
        difficulty: DifficultyLevel.BEGINNER,
        explanation: 'Phishing là kỹ thuật tấn công social engineering, sử dụng email hoặc website giả mạo để lừa người dùng cung cấp thông tin nhạy cảm như mật khẩu, số thẻ tín dụng.',
        metadata: {
          category: 'Social Engineering',
          tags: ['phishing', 'security-basics'],
        },
      },
      {
        subjectId: savedExplorerSubject.id,
        question: 'Mật khẩu mạnh nên có đặc điểm gì?',
        options: [
          'Chỉ cần dài là đủ',
          'Dài, có chữ hoa, chữ thường, số và ký tự đặc biệt',
          'Dễ nhớ như tên người yêu',
          'Chỉ cần số là đủ',
        ],
        correctAnswer: 1,
        difficulty: DifficultyLevel.BEGINNER,
        explanation: 'Mật khẩu mạnh cần kết hợp nhiều yếu tố: độ dài (ít nhất 12 ký tự), chữ hoa, chữ thường, số và ký tự đặc biệt để tăng độ phức tạp.',
        metadata: {
          category: 'Password Security',
          tags: ['password', 'authentication'],
        },
      },
      {
        subjectId: null, // General question
        question: 'Two-Factor Authentication (2FA) là gì?',
        options: [
          'Hai lớp mật khẩu',
          'Xác thực hai bước: mật khẩu + mã OTP/thiết bị',
          'Hai tài khoản riêng biệt',
          'Mật khẩu được mã hóa hai lần',
        ],
        correctAnswer: 1,
        difficulty: DifficultyLevel.BEGINNER,
        explanation: '2FA yêu cầu người dùng cung cấp hai yếu tố xác thực: thứ nhất là mật khẩu (something you know), thứ hai là mã OTP hoặc thiết bị (something you have).',
        metadata: {
          category: 'Authentication',
          tags: ['2FA', 'MFA', 'security'],
        },
      },
      // Intermediate Questions
      {
        subjectId: savedExplorerSubject.id,
        question: 'SQL Injection tấn công vào đâu?',
        options: [
          'Ứng dụng web thông qua input không được validate',
          'Hệ điều hành Windows',
          'Phần mềm diệt virus',
          'Router mạng',
        ],
        correctAnswer: 0,
        difficulty: DifficultyLevel.INTERMEDIATE,
        explanation: 'SQL Injection là lỗ hổng bảo mật cho phép kẻ tấn công chèn mã SQL độc hại vào input của ứng dụng web, thường do không validate hoặc sanitize input đúng cách.',
        metadata: {
          category: 'Web Security',
          tags: ['SQL injection', 'OWASP', 'web-vulnerabilities'],
        },
      },
      {
        subjectId: savedExplorerSubject.id,
        question: 'HTTPS khác HTTP ở điểm nào?',
        options: [
          'HTTPS nhanh hơn HTTP',
          'HTTPS mã hóa dữ liệu truyền tải, HTTP thì không',
          'HTTPS chỉ dùng cho email',
          'Không có khác biệt',
        ],
        correctAnswer: 1,
        difficulty: DifficultyLevel.INTERMEDIATE,
        explanation: 'HTTPS (HTTP Secure) sử dụng SSL/TLS để mã hóa dữ liệu giữa client và server, bảo vệ thông tin khỏi bị đánh cắp trong quá trình truyền tải.',
        metadata: {
          category: 'Network Security',
          tags: ['HTTPS', 'SSL', 'TLS', 'encryption'],
        },
      },
      {
        subjectId: null, // General question
        question: 'Zero-day exploit là gì?',
        options: [
          'Lỗ hổng đã được vá trong ngày',
          'Lỗ hổng chưa được phát hiện hoặc chưa có bản vá',
          'Lỗ hổng chỉ tồn tại trong 24 giờ',
          'Lỗ hổng không bao giờ được vá',
        ],
        correctAnswer: 1,
        difficulty: DifficultyLevel.INTERMEDIATE,
        explanation: 'Zero-day exploit là lỗ hổng bảo mật chưa được nhà phát triển biết đến hoặc chưa có bản vá, khiến hệ thống dễ bị tấn công.',
        metadata: {
          category: 'Vulnerability Management',
          tags: ['zero-day', 'exploit', 'vulnerability'],
        },
      },
      // Advanced Questions
      {
        subjectId: savedExplorerSubject.id,
        question: 'Man-in-the-Middle (MITM) attack hoạt động như thế nào?',
        options: [
          'Tấn công trực tiếp vào server',
          'Chặn và thay đổi giao tiếp giữa hai bên mà họ không biết',
          'Gửi email spam hàng loạt',
          'Tấn công từ chối dịch vụ (DDoS)',
        ],
        correctAnswer: 1,
        difficulty: DifficultyLevel.ADVANCED,
        explanation: 'MITM attack xảy ra khi kẻ tấn công chèn mình vào giữa hai bên đang giao tiếp, có thể đọc, sửa đổi hoặc chặn thông tin mà cả hai bên không biết.',
        metadata: {
          category: 'Network Attacks',
          tags: ['MITM', 'network-security', 'attack-vectors'],
        },
      },
      {
        subjectId: savedExplorerSubject.id,
        question: 'Penetration Testing khác Vulnerability Scanning ở điểm nào?',
        options: [
          'Không có khác biệt',
          'Penetration Testing là thử nghiệm xâm nhập thực tế, còn Vulnerability Scanning chỉ quét lỗ hổng',
          'Vulnerability Scanning tốt hơn',
          'Cả hai đều là tấn công thực tế',
        ],
        correctAnswer: 1,
        difficulty: DifficultyLevel.ADVANCED,
        explanation: 'Vulnerability Scanning chỉ quét và liệt kê các lỗ hổng tiềm ẩn. Penetration Testing đi xa hơn bằng cách thực sự khai thác các lỗ hổng để đánh giá mức độ nghiêm trọng và tác động thực tế.',
        metadata: {
          category: 'Security Testing',
          tags: ['penetration-testing', 'vulnerability-scanning', 'security-assessment'],
        },
      },
      {
        subjectId: null, // General question
        question: 'Public Key Infrastructure (PKI) dùng để làm gì?',
        options: [
          'Quản lý mật khẩu công khai',
          'Quản lý và xác thực chứng chỉ số (digital certificates)',
          'Mã hóa dữ liệu công khai',
          'Chia sẻ khóa mã hóa trên mạng công cộng',
        ],
        correctAnswer: 1,
        difficulty: DifficultyLevel.ADVANCED,
        explanation: 'PKI là hệ thống quản lý, phân phối và xác thực chứng chỉ số, cho phép xác minh danh tính và đảm bảo tính toàn vẹn của dữ liệu trong giao tiếp điện tử.',
        metadata: {
          category: 'Cryptography',
          tags: ['PKI', 'certificates', 'encryption', 'cryptography'],
        },
      },
    ];

    const savedQuestions = [];
    for (const q of sampleQuestions) {
      const question = this.questionRepository.create({
        subjectId: q.subjectId,
        question: q.question,
        options: q.options,
        correctAnswer: q.correctAnswer,
        difficulty: q.difficulty,
        explanation: q.explanation,
        metadata: q.metadata,
      });
      savedQuestions.push(await this.questionRepository.save(question));
    }

    console.log('✅ Seed completed!');
    console.log(`   - Created 2 subjects (1 Explorer, 1 Scholar)`);
    console.log(`   - Created 1 learning node`);
    console.log(`   - Created ${concepts.length + examples.length + hiddenRewards.length + 1} content items`);
    console.log(`   - Created ${savedQuestions.length} sample questions for placement test`);
  }

  /**
   * Seed Learning Nodes cho một subject
   * @param subjectId - ID của subject cần seed nodes
   * @param nodesData - Mảng các node data
   */
  async seedLearningNodesForSubject(
    subjectId: string,
    nodesData: Array<{
      title: string;
      description: string;
      order: number;
      prerequisites?: string[];
      icon?: string;
      concepts?: Array<{ title: string; content: string }>;
      examples?: Array<{ title: string; content: string; media?: any }>;
    }>,
  ): Promise<void> {
    console.log(`🌱 Seeding Learning Nodes for subject: ${subjectId}`);

    const subject = await this.subjectRepository.findOne({
      where: { id: subjectId },
    });

    if (!subject) {
      throw new Error(`Subject with ID ${subjectId} not found`);
    }

    const savedNodes: LearningNode[] = [];

    for (const nodeData of nodesData) {
      // Tạo Learning Node
      const node = this.nodeRepository.create({
        subjectId,
        title: nodeData.title,
        description: nodeData.description,
        order: nodeData.order,
        prerequisites: nodeData.prerequisites || [],
        contentStructure: {
          concepts: nodeData.concepts?.length || 0,
          examples: nodeData.examples?.length || 0,
          hiddenRewards: 3,
          bossQuiz: 1,
        },
        metadata: {
          icon: nodeData.icon || '📚',
          position: { x: (nodeData.order - 1) * 100, y: 0 },
        },
      });

      const savedNode = await this.nodeRepository.save(node);
      savedNodes.push(savedNode);

      // Cập nhật prerequisites nếu cần
      if (savedNodes.length > 1 && !nodeData.prerequisites) {
        const prevNode = savedNodes[savedNodes.length - 2];
        savedNode.prerequisites = [prevNode.id];
        await this.nodeRepository.save(savedNode);
      }

      // Tạo Concepts
      if (nodeData.concepts) {
        for (let i = 0; i < nodeData.concepts.length; i++) {
          const concept = this.contentItemRepository.create({
            nodeId: savedNode.id,
            type: 'concept',
            title: nodeData.concepts[i].title,
            content: nodeData.concepts[i].content,
            order: i + 1,
            rewards: { xp: 10, coin: 1 },
          });
          await this.contentItemRepository.save(concept);
        }
      }

      // Tạo Examples
      if (nodeData.examples) {
        for (let i = 0; i < nodeData.examples.length; i++) {
          const example = this.contentItemRepository.create({
            nodeId: savedNode.id,
            type: 'example',
            title: nodeData.examples[i].title,
            content: nodeData.examples[i].content,
            media: nodeData.examples[i].media,
            order: i + 1,
            rewards: { xp: 15, coin: 2 },
          });
          await this.contentItemRepository.save(example);
        }
      }

      // Tạo Boss Quiz
      const bossQuiz = this.contentItemRepository.create({
        nodeId: savedNode.id,
        type: 'boss_quiz',
        title: `Boss Quiz: ${nodeData.title}`,
        content: `Kiểm tra kiến thức về ${nodeData.title}`,
        order: 100,
        quizData: {
          question: `Câu hỏi về ${nodeData.title}?`,
          options: [
            'A. Đáp án 1',
            'B. Đáp án 2',
            'C. Đáp án 3',
            'D. Đáp án 4',
          ],
          correctAnswer: 0,
          explanation: 'Giải thích đáp án đúng',
        },
        rewards: { xp: 50, coin: 10 },
      });
      await this.contentItemRepository.save(bossQuiz);

      console.log(`✅ Created node: ${nodeData.title}`);
    }

    console.log(`✅ Successfully seeded ${savedNodes.length} Learning Nodes!`);
  }
}

