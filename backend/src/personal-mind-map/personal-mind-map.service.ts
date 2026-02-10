// Personal Mind Map Service - Chat riêng cho từng môn học
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  PersonalMindMap,
  PersonalMindMapNode,
  PersonalMindMapEdge,
} from './entities/personal-mind-map.entity';
import { AiService } from '../ai/ai.service';
import { DomainsService } from '../domains/domains.service';
import { LearningNode } from '../learning-nodes/entities/learning-node.entity';
import { UserPremium } from '../payment/entities/user-premium.entity';

// Number of free nodes before requiring premium
const FREE_MIND_MAP_NODES_LIMIT = 2;

// Interface cho onboarding data (từ OnboardingService cũ)
interface OnboardingData {
  nickname?: string;
  age?: number;
  currentLevel?: string;
  subject?: string;
  targetGoal?: string;
  dailyTime?: number;
  fullName?: string;
  phone?: string;
  interests?: string[];
  learningGoals?: string;
  experienceLevel?: string;
}

// Interface cho chat session của môn học cụ thể
interface SubjectChatSession {
  userId: string;
  subjectId: string;
  subjectName: string;
  messages: Array<{ role: string; content: string }>;
  extractedData: {
    currentLevel?: 'beginner' | 'intermediate' | 'advanced';
    interestedTopics?: string[]; // ID của LearningNode
    interestedDomains?: string[]; // ID của Domain
    learningGoals?: string;
    preferredPace?: 'slow' | 'normal' | 'fast';
    depthPreference?: 'simplified' | 'standard' | 'comprehensive';
    skipBasics?: boolean;
    dailyTime?: number;
  };
  // Dữ liệu môn học để AI hỏi
  domains: Array<{ id: string; name: string; description?: string }>;
  learningNodes: Array<{ id: string; title: string; description?: string; difficulty?: string }>;
  completed: boolean;
  turnCount: number;
}

@Injectable()
export class PersonalMindMapService {
  private chatSessions: Map<string, SubjectChatSession> = new Map();

  constructor(
    @InjectRepository(PersonalMindMap)
    private personalMindMapRepo: Repository<PersonalMindMap>,
    @InjectRepository(LearningNode)
    private learningNodeRepo: Repository<LearningNode>,
    @InjectRepository(UserPremium)
    private userPremiumRepo: Repository<UserPremium>,
    private aiService: AiService,
    private domainsService: DomainsService,
  ) {}

  /**
   * Check if user has active premium
   */
  private async checkUserPremium(userId: string): Promise<boolean> {
    if (!userId) return false;
    
    const userPremium = await this.userPremiumRepo.findOne({
      where: { userId },
    });

    if (!userPremium) return false;

    const now = new Date();
    return userPremium.isPremium && userPremium.premiumExpiresAt > now;
  }

  private getSessionKey(userId: string, subjectId: string): string {
    return `${userId}_${subjectId}`;
  }

  /**
   * Get subject mind map data from domains and learning nodes (replaces KnowledgeGraphService.getMindMapForSubject)
   */
  private async getSubjectMindMapData(subjectId: string): Promise<{ nodes: any[]; edges: any[] }> {
    const domains = await this.domainsService.findBySubject(subjectId);
    const learningNodes = await this.learningNodeRepo.find({
      where: { subjectId },
      order: { order: 'ASC' },
    });

    const nodes: any[] = [];
    // No subject node needed from KG - we get subject name from other sources
    // Add domain nodes
    for (const domain of domains) {
      nodes.push({
        id: domain.id,
        name: domain.name,
        type: 'domain',
        description: domain.description,
      });
    }

    return { nodes, edges: [] };
  }

  /**
   * Bắt đầu chat session để tạo lộ trình - HỎI DỰA TRÊN NỘI DUNG MÔN HỌC
   */
  async startSubjectChat(
    userId: string,
    subjectId: string,
  ): Promise<{
    response: string;
    subjectInfo: {
      name: string;
      domains: Array<{ id: string; name: string }>;
      totalLessons: number;
    };
    sessionStarted: boolean;
  }> {
    const key = this.getSessionKey(userId, subjectId);

    // Lấy thông tin môn học từ domains và learning nodes
    const subjectMindMap = await this.getSubjectMindMapData(subjectId);
    const domains = subjectMindMap.nodes.filter((n: any) => n.type === 'domain');

    // Lấy LearningNodes
    const learningNodes = await this.learningNodeRepo.find({
      where: { subjectId },
      order: { order: 'ASC' },
    });

    if (learningNodes.length === 0) {
      throw new NotFoundException('Môn học này chưa có bài học nào');
    }

    // Tạo session mới
    const session: SubjectChatSession = {
      userId,
      subjectId,
      subjectName: domains.length > 0 ? domains[0].name : 'Môn học',
      messages: [],
      extractedData: {},
      domains: domains.map((d: any) => ({ id: d.id, name: d.name, description: d.description })),
      learningNodes: learningNodes.map((ln) => ({
        id: ln.id,
        title: ln.title,
        description: ln.description,
        difficulty: ln.difficulty,
      })),
      completed: false,
      turnCount: 0,
    };

    // Tạo prompt khởi tạo DỰA TRÊN NỘI DUNG MÔN HỌC
    const systemPrompt = `Bạn là một AI tutor thân thiện giúp học viên tạo lộ trình học "${session.subjectName}".

📚 MÔN HỌC: ${session.subjectName}

📂 CÁC CHƯƠNG CHÍNH (Domain):
${domains.map((d: any, i: number) => `${i + 1}. ${d.name}${d.description ? ` - ${d.description}` : ''}`).join('\n')}

📖 CÁC BÀI HỌC CÓ SẴN (${learningNodes.length} bài):
${learningNodes.slice(0, 15).map((ln, i) => `${i + 1}. "${ln.title}"${ln.difficulty ? ` (${ln.difficulty})` : ''}`).join('\n')}
${learningNodes.length > 15 ? `... và ${learningNodes.length - 15} bài học khác` : ''}

🎯 NHIỆM VỤ CỦA BẠN:
Thu thập thông tin qua các câu hỏi NGẮN GỌN (1-2 câu/lượt), HỎI TỪNG CÂU MỘT:

1. Hỏi về KINH NGHIỆM với môn học này (đã học chưa, biết gì về nó)
2. Hỏi về MỤC TIÊU cụ thể (học để làm gì, muốn đạt được gì)
3. Hỏi CHƯƠNG NÀO trong danh sách trên họ QUAN TÂM NHẤT (đọc tên các chương)
4. Hỏi BÀI HỌC NÀO họ muốn ưu tiên (có thể đọc 1 số bài học mẫu)
5. Hỏi về THỜI GIAN có thể dành cho việc học mỗi ngày
6. Hỏi muốn lộ trình NGẮN GỌN (5-7 bài) hay ĐẦY ĐỦ (10+ bài)

⚠️ QUY TẮC:
- Hỏi NGẮN GỌN, thân thiện, 1-2 câu mỗi lượt
- Sử dụng tên CHƯƠNG và BÀI HỌC cụ thể trong câu hỏi
- Khi user trả lời chung chung, gợi ý các option cụ thể từ danh sách
- Sau 4-5 lượt hỏi đáp, tóm tắt và hỏi xác nhận để tạo lộ trình

Bắt đầu bằng cách chào hỏi và hỏi về kinh nghiệm của họ với môn "${session.subjectName}".`;

    const aiResponse = await this.aiService.chat([
      { role: 'system', content: systemPrompt },
    ]);

    session.messages.push({
      role: 'assistant',
      content: aiResponse,
    });

    this.chatSessions.set(key, session);

    return {
      response: aiResponse,
      subjectInfo: {
        name: session.subjectName,
        domains: session.domains.map((d) => ({ id: d.id, name: d.name })),
        totalLessons: learningNodes.length,
      },
      sessionStarted: true,
    };
  }

  /**
   * Tiếp tục chat - trích xuất thông tin từ câu trả lời
   */
  async continueSubjectChat(
    userId: string,
    subjectId: string,
    message: string,
  ): Promise<{
    response: string;
    extractedData: SubjectChatSession['extractedData'];
    canGenerate: boolean;
  }> {
    const key = this.getSessionKey(userId, subjectId);
    let session = this.chatSessions.get(key);

    if (!session) {
      // Tự động start session nếu chưa có
      await this.startSubjectChat(userId, subjectId);
      session = this.chatSessions.get(key)!;
    }

    // Thêm message của user
    session.messages.push({
      role: 'user',
      content: message,
    });
    session.turnCount++;

    // Extract data mỗi 2 lượt
    if (session.turnCount % 2 === 0 || session.turnCount >= 3) {
      const extracted = await this.extractSubjectLearningData(session);
      session.extractedData = { ...session.extractedData, ...extracted };
    }

    // Tạo context prompt
    const contextPrompt = `Bạn đang trò chuyện với học viên về môn "${session.subjectName}".

📂 CÁC CHƯƠNG: ${session.domains.map((d) => d.name).join(', ')}

📖 MỘT SỐ BÀI HỌC: ${session.learningNodes.slice(0, 10).map((ln) => ln.title).join(', ')}

📊 THÔNG TIN ĐÃ THU THẬP:
- Trình độ: ${session.extractedData.currentLevel || 'chưa biết'}
- Mục tiêu: ${session.extractedData.learningGoals || 'chưa có'}
- Chương quan tâm: ${session.extractedData.interestedDomains?.length ? session.extractedData.interestedDomains.join(', ') : 'chưa có'}
- Bài học quan tâm: ${session.extractedData.interestedTopics?.length ? session.extractedData.interestedTopics.join(', ') : 'chưa có'}
- Thời gian học/ngày: ${session.extractedData.dailyTime ? `${session.extractedData.dailyTime} phút` : 'chưa biết'}
- Độ chi tiết: ${session.extractedData.depthPreference || 'chưa biết'}

🎯 HƯỚNG DẪN:
${!session.extractedData.currentLevel ? '→ Hỏi về kinh nghiệm/trình độ với môn học này.' : ''}
${!session.extractedData.learningGoals ? '→ Hỏi về mục tiêu học tập cụ thể.' : ''}
${!session.extractedData.interestedDomains?.length && session.extractedData.currentLevel ? `→ Hỏi họ quan tâm chương nào: ${session.domains.slice(0, 5).map((d) => d.name).join(', ')}` : ''}
${!session.extractedData.depthPreference && session.extractedData.currentLevel && session.extractedData.learningGoals ? '→ Hỏi muốn lộ trình NGẮN GỌN (5-7 bài) hay ĐẦY ĐỦ (10+ bài)?' : ''}
${session.extractedData.currentLevel && session.extractedData.learningGoals && session.extractedData.depthPreference ? '✅ Đã đủ thông tin! Tóm tắt lại và hỏi user có muốn tạo lộ trình không.' : ''}

Trả lời NGẮN GỌN (2-3 câu), thân thiện.`;

    const aiResponse = await this.aiService.chat([
      { role: 'system', content: contextPrompt },
      ...session.messages,
    ]);

    session.messages.push({
      role: 'assistant',
      content: aiResponse,
    });

    // Kiểm tra đủ thông tin chưa
    const canGenerate =
      !!session.extractedData.currentLevel &&
      !!session.extractedData.learningGoals;

    session.completed = canGenerate;
    this.chatSessions.set(key, session);

    return {
      response: aiResponse,
      extractedData: session.extractedData,
      canGenerate,
    };
  }

  /**
   * Trích xuất thông tin học tập từ conversation
   */
  private async extractSubjectLearningData(
    session: SubjectChatSession,
  ): Promise<Partial<SubjectChatSession['extractedData']>> {
    const prompt = `Phân tích cuộc hội thoại về môn "${session.subjectName}" và trích xuất thông tin.

CÁC CHƯƠNG CÓ SẴN:
${session.domains.map((d) => `- ${d.name} (ID: ${d.id})`).join('\n')}

CÁC BÀI HỌC CÓ SẴN:
${session.learningNodes.slice(0, 20).map((ln) => `- "${ln.title}" (ID: ${ln.id})`).join('\n')}

Trả về JSON:
{
  "currentLevel": "beginner" | "intermediate" | "advanced" | null,
  "interestedTopics": ["learningNodeId1", "learningNodeId2"] | null,
  "interestedDomains": ["tên chương 1", "tên chương 2"] | null,
  "learningGoals": "mục tiêu cụ thể" | null,
  "preferredPace": "slow" | "normal" | "fast" | null,
  "depthPreference": "simplified" | "standard" | "comprehensive" | null,
  "dailyTime": number | null,
  "skipBasics": true | false | null
}

GỢI Ý:
- currentLevel: "beginner" nếu chưa biết gì, "intermediate" nếu biết cơ bản, "advanced" nếu đã có kinh nghiệm
- depthPreference: "simplified" nếu muốn ngắn gọn/nhanh, "comprehensive" nếu muốn đầy đủ
- interestedDomains: Lấy TÊN các chương user quan tâm từ danh sách
- interestedTopics: Lấy ID các bài học user muốn học từ danh sách

Hội thoại:
${session.messages.map((m) => `${m.role}: ${m.content}`).join('\n')}

CHỈ TRẢ VỀ JSON.`;

    try {
      const response = await this.aiService.chat([{ role: 'user', content: prompt }]);
      const jsonMatch = response.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
      return {};
    } catch {
      return {};
    }
  }

  /**
   * Tạo lộ trình từ chat session đã hoàn thành
   */
  async generateFromSubjectChat(
    userId: string,
    subjectId: string,
  ): Promise<{
    success: boolean;
    mindMap?: PersonalMindMap;
    message: string;
  }> {
    const key = this.getSessionKey(userId, subjectId);
    const session = this.chatSessions.get(key);

    if (!session) {
      throw new NotFoundException('Chưa có chat session. Hãy bắt đầu trò chuyện trước.');
    }

    // Xóa mind map cũ nếu có (cho phép tạo lại)
    await this.personalMindMapRepo.delete({ userId, subjectId });

    // Tạo learning goal từ extracted data
    const learningGoal = this.buildLearningGoalFromChat(session);

    // Lấy mind map môn học từ domains
    const subjectMindMap = await this.getSubjectMindMapData(subjectId);

    // Tạo lộ trình cá nhân hóa
    const personalizedPlan = await this.generateSmartPlan(
      learningGoal,
      subjectMindMap,
      session.extractedData,
      subjectId,
    );

    // Tạo personal mind map
    const personalMindMap = new PersonalMindMap();
    personalMindMap.userId = userId;
    personalMindMap.subjectId = subjectId;
    personalMindMap.learningGoal = learningGoal;
    personalMindMap.nodes = personalizedPlan.nodes;
    personalMindMap.edges = personalizedPlan.edges;
    personalMindMap.totalNodes = personalizedPlan.nodes.length;
    personalMindMap.completedNodes = 0;
    personalMindMap.progressPercent = 0;
    personalMindMap.aiConversationHistory = session.messages.map((m) => ({
      role: m.role as 'user' | 'assistant',
      content: m.content,
      timestamp: new Date(),
    }));

    const saved = await this.personalMindMapRepo.save(personalMindMap);

    // Xóa session
    this.chatSessions.delete(key);

    return {
      success: true,
      mindMap: saved,
      message: 'Đã tạo lộ trình học tập cá nhân thành công!',
    };
  }

  /**
   * Tạo learning goal từ chat session
   */
  private buildLearningGoalFromChat(session: SubjectChatSession): string {
    const parts: string[] = [];

    if (session.extractedData.currentLevel) {
      const levelMap = {
        beginner: 'người mới bắt đầu',
        intermediate: 'đã có kiến thức cơ bản',
        advanced: 'trình độ nâng cao',
      };
      parts.push(`Trình độ: ${levelMap[session.extractedData.currentLevel]}`);
    }

    if (session.extractedData.learningGoals) {
      parts.push(`Mục tiêu: ${session.extractedData.learningGoals}`);
    }

    if (session.extractedData.interestedDomains?.length) {
      parts.push(`Chương quan tâm: ${session.extractedData.interestedDomains.join(', ')}`);
    }

    if (session.extractedData.dailyTime) {
      parts.push(`Thời gian: ${session.extractedData.dailyTime} phút/ngày`);
    }

    return parts.join('. ') || 'Học tập chung';
  }

  /**
   * Lấy thông tin chat session hiện tại
   */
  async getChatSession(
    userId: string,
    subjectId: string,
  ): Promise<{
    exists: boolean;
    extractedData?: SubjectChatSession['extractedData'];
    messages?: Array<{ role: string; content: string }>;
    canGenerate?: boolean;
  }> {
    const key = this.getSessionKey(userId, subjectId);
    const session = this.chatSessions.get(key);

    if (!session) {
      return { exists: false };
    }

    const canGenerate =
      !!session.extractedData.currentLevel &&
      !!session.extractedData.learningGoals;

    return {
      exists: true,
      extractedData: session.extractedData,
      messages: session.messages,
      canGenerate,
    };
  }

  /**
   * Generate personal mind map from adaptive test results
   * This creates a learning path focused on weak areas identified in the test
   */
  async generateFromAdaptiveTest(
    userId: string,
    subjectId: string,
    testResults: {
      score: number;
      overallLevel: 'beginner' | 'intermediate' | 'advanced';
      weakAreas: string[]; // Topic names that need improvement
      strongAreas: string[]; // Topic names user is good at
      recommendedPath: string[]; // Node IDs sorted by priority (weak first)
      topicAssessments: Array<{
        topicId: string;
        topicName?: string;
        score: number;
        level: string;
      }>;
    },
  ): Promise<{
    success: boolean;
    mindMap?: PersonalMindMap;
    message: string;
  }> {
    // Delete old mind map if exists
    await this.personalMindMapRepo.delete({ userId, subjectId });

    // Get subject mind map from domains
    const subjectMindMap = await this.getSubjectMindMapData(subjectId);

    // Build learning goal from test results
    const learningGoal = this.buildLearningGoalFromTest(testResults);

    // Create extractedData compatible with generateSmartPlan
    const extractedData = {
      currentLevel: testResults.overallLevel,
      learningGoals: `Cần cải thiện: ${testResults.weakAreas.join(', ')}`,
      focusAreas: testResults.weakAreas,
      skipBasics: testResults.overallLevel === 'advanced',
      preferredPace: testResults.overallLevel === 'beginner' ? 'slow' as const : 'normal' as const,
    };

    // Generate personalized plan prioritizing weak areas
    const personalizedPlan = await this.generatePlanFromTestResults(
      learningGoal,
      subjectMindMap,
      extractedData,
      subjectId,
      testResults,
    );

    // Create personal mind map
    const personalMindMap = new PersonalMindMap();
    personalMindMap.userId = userId;
    personalMindMap.subjectId = subjectId;
    personalMindMap.learningGoal = learningGoal;
    personalMindMap.nodes = personalizedPlan.nodes;
    personalMindMap.edges = personalizedPlan.edges;
    personalMindMap.totalNodes = personalizedPlan.nodes.length;
    personalMindMap.completedNodes = 0;
    personalMindMap.progressPercent = 0;
    personalMindMap.aiConversationHistory = [
      {
        role: 'assistant',
        content: `Lộ trình này được tạo tự động từ bài kiểm tra đầu vào.\n\nKết quả: ${testResults.score}%\nTrình độ: ${testResults.overallLevel}\nCần cải thiện: ${testResults.weakAreas.join(', ') || 'Không có'}\nĐiểm mạnh: ${testResults.strongAreas.join(', ') || 'Không có'}`,
        timestamp: new Date(),
      },
    ];

    const saved = await this.personalMindMapRepo.save(personalMindMap);

    return {
      success: true,
      mindMap: saved,
      message: 'Đã tạo lộ trình học tập từ kết quả bài kiểm tra!',
    };
  }

  /**
   * Build learning goal from test results
   */
  private buildLearningGoalFromTest(testResults: {
    score: number;
    overallLevel: string;
    weakAreas: string[];
    strongAreas: string[];
  }): string {
    const parts: string[] = [];

    const levelMap: Record<string, string> = {
      beginner: 'người mới bắt đầu',
      intermediate: 'đã có kiến thức cơ bản',
      advanced: 'trình độ nâng cao',
    };
    parts.push(`Trình độ đánh giá: ${levelMap[testResults.overallLevel] || testResults.overallLevel}`);
    parts.push(`Điểm kiểm tra: ${testResults.score}%`);

    if (testResults.weakAreas.length > 0) {
      parts.push(`Cần cải thiện: ${testResults.weakAreas.join(', ')}`);
    }

    if (testResults.strongAreas.length > 0) {
      parts.push(`Đã nắm vững: ${testResults.strongAreas.join(', ')}`);
    }

    return parts.join('. ');
  }

  /**
   * Generate plan specifically from test results, prioritizing weak areas
   */
  private async generatePlanFromTestResults(
    learningGoal: string,
    subjectMindMap: { nodes: any[]; edges: any[] },
    extractedData: {
      currentLevel?: 'beginner' | 'intermediate' | 'advanced';
      learningGoals?: string;
      focusAreas?: string[];
      skipBasics?: boolean;
      preferredPace?: 'slow' | 'normal' | 'fast';
    },
    subjectId: string,
    testResults: {
      score: number;
      weakAreas: string[];
      strongAreas: string[];
      recommendedPath: string[];
      topicAssessments: Array<{
        topicId: string;
        score: number;
        level: string;
      }>;
    },
  ): Promise<{ nodes: PersonalMindMapNode[]; edges: PersonalMindMapEdge[] }> {
    const subjectNode = subjectMindMap.nodes.find((n) => n.type === 'subject');
    
    // Get learning nodes from DB
    const learningNodes = await this.learningNodeRepo.find({
      where: { subjectId },
      order: { order: 'ASC' },
    });

    if (learningNodes.length === 0) {
      throw new Error('Môn học này chưa có bài học nào.');
    }

    const level = extractedData.currentLevel || 'beginner';
    
    // Sort learning nodes: weak areas first, then others
    const weakTopicIds = new Set(
      testResults.topicAssessments
        .filter(a => a.score < 50 || a.level === 'beginner')
        .map(a => a.topicId)
    );

    const strongTopicIds = new Set(
      testResults.topicAssessments
        .filter(a => a.score >= 70 || a.level === 'advanced')
        .map(a => a.topicId)
    );
    
    const prioritizedNodes = [...learningNodes].sort((a, b) => {
      const aIsWeak = weakTopicIds.has(a.id);
      const bIsWeak = weakTopicIds.has(b.id);
      if (aIsWeak && !bIsWeak) return -1;
      if (!aIsWeak && bIsWeak) return 1;
      return (a.order || 0) - (b.order || 0);
    });

    // Create prompt focusing on test results
    const prompt = `Bạn là một AI giáo dục chuyên tạo lộ trình học tập cá nhân hóa DỰA TRÊN KẾT QUẢ KIỂM TRA.

THÔNG TIN TỪ BÀI KIỂM TRA:
- Điểm số: ${testResults.score}%
- Trình độ đánh giá: ${level === 'beginner' ? 'Cơ bản' : level === 'intermediate' ? 'Trung bình' : 'Nâng cao'}
- CẦN CẢI THIỆN: ${testResults.weakAreas.length > 0 ? testResults.weakAreas.join(', ') : 'Không có (đã nắm tốt)'}
- ĐÃ NẮM VỮNG: ${testResults.strongAreas.length > 0 ? testResults.strongAreas.join(', ') : 'Chưa xác định'}

ĐÁNH GIÁ CHI TIẾT TỪNG CHỦ ĐỀ:
${testResults.topicAssessments.map(a => `- ${a.topicId}: ${a.score}% (${a.level})`).join('\n')}

MÔN HỌC: ${subjectNode?.name || 'Không xác định'}

⚠️ DANH SÁCH BÀI HỌC CÓ SẴN (BẮT BUỘC CHỌN TỪ DANH SÁCH NÀY):
${prioritizedNodes.map((ln, i) => `${i + 1}. "${ln.title}" (ID: ${ln.id})${weakTopicIds.has(ln.id) ? ' [CẦN CẢI THIỆN]' : strongTopicIds.has(ln.id) ? ' [ĐIỂM MẠNH]' : ''}`).join('\n')}

YÊU CẦU TẠO LỘ TRÌNH:
1. ƯU TIÊN các bài học [CẦN CẢI THIỆN] lên đầu lộ trình
2. THÊM các bài [ĐIỂM MẠNH] để ôn tập và nâng cao
3. ${level === 'advanced' ? 'Bỏ qua các bài quá cơ bản, tập trung bài chuyên sâu' : level === 'intermediate' ? 'Ôn lại phần yếu, sau đó học nâng cao' : 'Bắt đầu từ cơ bản, củng cố nền tảng'}
4. CHỈ ĐƯỢC CHỌN TỪ DANH SÁCH Ở TRÊN (dùng đúng ID)
5. Số lượng bài: ${level === 'beginner' ? '8-12' : level === 'intermediate' ? '10-15' : '12-18'} bài

Trả về JSON:
{
  "selectedLessons": [
    {
      "learningNodeId": "uuid từ danh sách",
      "title": "tên bài",
      "priority": "high" | "medium" | "low",
      "estimatedDays": number,
      "reason": "lý do (ví dụ: 'Cần cải thiện từ bài kiểm tra' hoặc 'Đã nắm vững - ôn tập')",
      "difficulty": "easy" | "medium" | "hard",
      "isWeakArea": true/false,
      "isStrongArea": true/false
    }
  ],
  "learningPath": ["id1", "id2", ...],
  "summary": "tóm tắt lộ trình dựa trên kết quả test"
}

QUAN TRỌNG: CHỈ SỬ DỤNG ID TỪ DANH SÁCH. KHÔNG TỰ TẠO ID MỚI.
CHỈ TRẢ VỀ JSON.`;

    try {
      const response = await this.aiService.chat([
        { role: 'user', content: prompt },
      ]);
      const cleanedResponse = response
        .replace(/```json\n?/g, '')
        .replace(/```\n?/g, '')
        .trim();
      const aiPlan = JSON.parse(cleanedResponse);

      // Create map from ID to LearningNode
      const learningNodeMap = new Map<string, LearningNode>();
      learningNodes.forEach((ln) => learningNodeMap.set(ln.id, ln));

      // Build mind map with weak area highlights
      return this.buildMindMapFromTestResults(
        aiPlan,
        learningGoal,
        learningNodeMap,
        level,
        weakTopicIds,
        strongTopicIds,
      );
    } catch (error) {
      console.error('Error generating plan from test:', error);
      // Fallback: prioritize weak areas
      const selectedNodes = prioritizedNodes.slice(0, 12);
      return this.createDefaultPlanFromLearningNodes(learningGoal, selectedNodes);
    }
  }

  /**
   * Build mind map structure highlighting weak areas from test
   */
  private buildMindMapFromTestResults(
    aiPlan: any,
    learningGoal: string,
    learningNodeMap: Map<string, LearningNode>,
    level: string,
    weakTopicIds: Set<string>,
    strongTopicIds: Set<string>,
  ): { nodes: PersonalMindMapNode[]; edges: PersonalMindMapEdge[] } {
    const nodes: PersonalMindMapNode[] = [];
    const edges: PersonalMindMapEdge[] = [];

    // Root node - Goal (level 1)
    const goalNode: PersonalMindMapNode = {
      id: 'goal-root',
      title: '🎯 Lộ trình cá nhân hóa',
      description: 'Dựa trên kết quả bài kiểm tra đầu vào',
      level: 1,
      position: { x: 0, y: 0 },
      status: 'in_progress',
      priority: 'high',
    };
    nodes.push(goalNode);

    // Split lessons into 3 categories: weak, strong, other
    const allLessons = aiPlan.selectedLessons || [];
    const weakLessons = allLessons.filter((l: any) => 
      weakTopicIds.has(l.learningNodeId) || l.isWeakArea
    );
    const strongLessons = allLessons.filter((l: any) => 
      !weakTopicIds.has(l.learningNodeId) && !l.isWeakArea &&
      (strongTopicIds.has(l.learningNodeId) || l.isStrongArea)
    );
    const otherLessons = allLessons.filter((l: any) => 
      !weakTopicIds.has(l.learningNodeId) && !l.isWeakArea &&
      !strongTopicIds.has(l.learningNodeId) && !l.isStrongArea
    );

    let yOffset = 100;
    let edgeIndex = 0;

    // Track first milestone for auto-unlock
    let firstMilestoneUnlocked = false;

    // Add "Cần cải thiện" milestone if there are weak areas
    if (weakLessons.length > 0) {
      const weakMilestone: PersonalMindMapNode = {
        id: 'milestone-weak',
        title: '⚠️ Cần cải thiện',
        description: `${weakLessons.length} bài học cần tập trung`,
        level: 2,
        parentId: 'goal-root',
        position: { x: -200, y: yOffset },
        status: !firstMilestoneUnlocked ? 'in_progress' : 'not_started',
        priority: 'high',
      };
      firstMilestoneUnlocked = true;
      nodes.push(weakMilestone);
      edges.push({
        id: `edge-${edgeIndex++}`,
        from: 'goal-root',
        to: 'milestone-weak',
        type: 'leads_to',
      });

      // Add weak area lessons
      weakLessons.forEach((lesson: any, index: number) => {
        const learningNode = learningNodeMap.get(lesson.learningNodeId);
        if (!learningNode) return;

        yOffset += 80;
        const lessonNode: PersonalMindMapNode = {
          id: `lesson-${lesson.learningNodeId}`,
          title: `🔴 ${lesson.title || learningNode.title}`,
          description: lesson.reason || 'Cần ôn lại từ kết quả kiểm tra',
          level: 3,
          parentId: 'milestone-weak',
          position: { x: -200, y: yOffset },
          status: weakMilestone.status === 'in_progress' && index === 0 ? 'in_progress' : 'not_started',
          priority: 'high',
          estimatedDays: lesson.estimatedDays || 1,
          metadata: {
            linkedLearningNodeId: lesson.learningNodeId,
            linkedLearningNodeTitle: learningNode.title,
            hasLearningContent: true,
          },
        };
        nodes.push(lessonNode);
        
        if (index === 0) {
          edges.push({
            id: `edge-${edgeIndex++}`,
            from: 'milestone-weak',
            to: lessonNode.id,
            type: 'leads_to',
          });
        } else {
          const prevLessonId = `lesson-${weakLessons[index - 1].learningNodeId}`;
          edges.push({
            id: `edge-${edgeIndex++}`,
            from: prevLessonId,
            to: lessonNode.id,
            type: 'leads_to',
          });
        }
      });
    }

    // Add "Củng cố & Nâng cao" milestone for other lessons
    if (otherLessons.length > 0) {
      yOffset += 100;
      const otherMilestone: PersonalMindMapNode = {
        id: 'milestone-other',
        title: '📚 Củng cố & Nâng cao',
        description: `${otherLessons.length} bài học tiếp theo`,
        level: 2,
        parentId: 'goal-root',
        position: { x: 200, y: yOffset },
        status: !firstMilestoneUnlocked ? 'in_progress' : 'not_started',
        priority: 'medium',
      };
      firstMilestoneUnlocked = true;
      nodes.push(otherMilestone);

      // Connect to previous section
      if (weakLessons.length > 0) {
        const lastWeakLessonId = `lesson-${weakLessons[weakLessons.length - 1].learningNodeId}`;
        edges.push({
          id: `edge-${edgeIndex++}`,
          from: lastWeakLessonId,
          to: 'milestone-other',
          type: 'leads_to',
        });
      } else {
        edges.push({
          id: `edge-${edgeIndex++}`,
          from: 'goal-root',
          to: 'milestone-other',
          type: 'leads_to',
        });
      }

      // Add other lessons
      otherLessons.forEach((lesson: any, index: number) => {
        const learningNode = learningNodeMap.get(lesson.learningNodeId);
        if (!learningNode) return;

        yOffset += 80;
        const lessonNode: PersonalMindMapNode = {
          id: `lesson-${lesson.learningNodeId}`,
          title: lesson.title || learningNode.title,
          description: lesson.reason || learningNode.description,
          level: 3,
          parentId: 'milestone-other',
          position: { x: 200, y: yOffset },
          status: otherMilestone.status === 'in_progress' && index === 0 ? 'in_progress' : 'not_started',
          priority: lesson.priority || 'medium',
          estimatedDays: lesson.estimatedDays || 1,
          metadata: {
            linkedLearningNodeId: lesson.learningNodeId,
            linkedLearningNodeTitle: learningNode.title,
            hasLearningContent: true,
          },
        };
        nodes.push(lessonNode);
        
        if (index === 0) {
          edges.push({
            id: `edge-${edgeIndex++}`,
            from: 'milestone-other',
            to: lessonNode.id,
            type: 'leads_to',
          });
        } else {
          const prevLessonId = `lesson-${otherLessons[index - 1].learningNodeId}`;
          edges.push({
            id: `edge-${edgeIndex++}`,
            from: prevLessonId,
            to: lessonNode.id,
            type: 'leads_to',
          });
        }
      });
    }

    // Add "Điểm mạnh" milestone for strong areas
    if (strongLessons.length > 0) {
      yOffset += 100;
      const strongMilestone: PersonalMindMapNode = {
        id: 'milestone-strong',
        title: '✅ Điểm mạnh',
        description: `${strongLessons.length} bài đã nắm vững - ôn lại khi cần`,
        level: 2,
        parentId: 'goal-root',
        position: { x: 0, y: yOffset },
        status: !firstMilestoneUnlocked ? 'in_progress' : 'not_started',
        priority: 'low',
      };
      firstMilestoneUnlocked = true;
      nodes.push(strongMilestone);

      // Connect to previous section
      const lastMilestoneId = otherLessons.length > 0
        ? `lesson-${otherLessons[otherLessons.length - 1].learningNodeId}`
        : weakLessons.length > 0
          ? `lesson-${weakLessons[weakLessons.length - 1].learningNodeId}`
          : 'goal-root';
      edges.push({
        id: `edge-${edgeIndex++}`,
        from: lastMilestoneId,
        to: 'milestone-strong',
        type: 'leads_to',
      });

      // Add strong area lessons
      strongLessons.forEach((lesson: any, index: number) => {
        const learningNode = learningNodeMap.get(lesson.learningNodeId);
        if (!learningNode) return;

        yOffset += 80;
        const lessonNode: PersonalMindMapNode = {
          id: `lesson-${lesson.learningNodeId}`,
          title: `🟢 ${lesson.title || learningNode.title}`,
          description: lesson.reason || 'Đã nắm vững từ bài kiểm tra',
          level: 3,
          parentId: 'milestone-strong',
          position: { x: 0, y: yOffset },
          status: strongMilestone.status === 'in_progress' && index === 0 ? 'in_progress' : 'not_started',
          priority: 'low',
          estimatedDays: lesson.estimatedDays || 1,
          metadata: {
            linkedLearningNodeId: lesson.learningNodeId,
            linkedLearningNodeTitle: learningNode.title,
            hasLearningContent: true,
          },
        };
        nodes.push(lessonNode);

        if (index === 0) {
          edges.push({
            id: `edge-${edgeIndex++}`,
            from: 'milestone-strong',
            to: lessonNode.id,
            type: 'leads_to',
          });
        } else {
          const prevLessonId = `lesson-${strongLessons[index - 1].learningNodeId}`;
          edges.push({
            id: `edge-${edgeIndex++}`,
            from: prevLessonId,
            to: lessonNode.id,
            type: 'leads_to',
          });
        }
      });
    }

    return { nodes, edges };
  }

  /**
   * Reset chat session
   */
  async resetChatSession(userId: string, subjectId: string): Promise<void> {
    const key = this.getSessionKey(userId, subjectId);
    this.chatSessions.delete(key);
  }

  /**
   * Tạo personal mind map từ dữ liệu onboarding đã thu thập
   * Sử dụng onboarding chat có sẵn thay vì tạo chat mới
   */
  async createFromOnboardingData(
    userId: string,
    subjectId: string,
    onboardingData: OnboardingData,
  ): Promise<{
    success: boolean;
    mindMap?: PersonalMindMap;
    message: string;
  }> {
    if (!userId) {
      throw new Error('userId is required');
    }

    // Kiểm tra đã có mind map chưa
    const existing = await this.personalMindMapRepo.findOne({
      where: { userId, subjectId },
    });

    if (existing) {
      return {
        success: false,
        mindMap: existing,
        message: 'Bạn đã có lộ trình học tập cho môn học này.',
      };
    }

    // Lấy mind map môn học từ domains
    const subjectMindMap = await this.getSubjectMindMapData(subjectId);

    // Tạo learning goal từ onboarding data
    const learningGoal = this.buildLearningGoalFromOnboarding(onboardingData);

    // Chuyển đổi onboarding data thành extracted data cho AI
    const extractedData = this.convertOnboardingToExtractedData(onboardingData);

    // Tạo lộ trình cá nhân hóa
    const personalizedPlan = await this.generateSmartPlan(
      learningGoal,
      subjectMindMap,
      extractedData,
      subjectId,
    );

    // Tạo personal mind map
    const personalMindMap = new PersonalMindMap();
    personalMindMap.userId = userId;
    personalMindMap.subjectId = subjectId;
    personalMindMap.learningGoal = learningGoal;
    personalMindMap.nodes = personalizedPlan.nodes;
    personalMindMap.edges = personalizedPlan.edges;
    personalMindMap.totalNodes = personalizedPlan.nodes.length;
    personalMindMap.completedNodes = 0;
    personalMindMap.progressPercent = 0;
    personalMindMap.aiConversationHistory = [];

    const saved = await this.personalMindMapRepo.save(personalMindMap);

    return {
      success: true,
      mindMap: saved,
      message: 'Đã tạo lộ trình học tập cá nhân thành công!',
    };
  }

  /**
   * Chuyển đổi onboarding data thành extracted data
   */
  private convertOnboardingToExtractedData(onboardingData: OnboardingData) {
    // Map currentLevel từ onboarding (có thể là string bất kỳ) sang format mong muốn
    let currentLevel: 'beginner' | 'intermediate' | 'advanced' = 'beginner';
    if (onboardingData.currentLevel) {
      const level = onboardingData.currentLevel.toLowerCase();
      if (level.includes('advanced') || level.includes('nâng cao') || level.includes('cao')) {
        currentLevel = 'advanced';
      } else if (level.includes('intermediate') || level.includes('trung') || level.includes('biết')) {
        currentLevel = 'intermediate';
      }
    }

    // Map dailyTime sang preferredPace
    let preferredPace: 'slow' | 'normal' | 'fast' = 'normal';
    if (onboardingData.dailyTime) {
      if (onboardingData.dailyTime <= 30) {
        preferredPace = 'slow';
      } else if (onboardingData.dailyTime >= 60) {
        preferredPace = 'fast';
      }
    }

    // Xác định độ chi tiết dựa trên mục tiêu và trình độ
    let depthPreference: 'simplified' | 'standard' | 'comprehensive' = 'standard';
    const goal = onboardingData.targetGoal?.toLowerCase() || '';
    if (goal.includes('nhanh') || goal.includes('cơ bản') || goal.includes('ngắn')) {
      depthPreference = 'simplified';
    } else if (goal.includes('đầy đủ') || goal.includes('chi tiết') || goal.includes('chuyên sâu')) {
      depthPreference = 'comprehensive';
    }

    return {
      currentLevel,
      interestedTopics: onboardingData.interests || [],
      learningGoals: onboardingData.targetGoal || onboardingData.learningGoals,
      preferredPace,
      depthPreference,
      focusAreas: [],
      skipBasics: currentLevel !== 'beginner',
    };
  }

  /**
   * Tạo learning goal string từ onboarding data
   */
  private buildLearningGoalFromOnboarding(onboardingData: OnboardingData): string {
    const parts: string[] = [];

    if (onboardingData.currentLevel) {
      parts.push(`Trình độ: ${onboardingData.currentLevel}`);
    }

    if (onboardingData.targetGoal) {
      parts.push(`Mục tiêu: ${onboardingData.targetGoal}`);
    } else if (onboardingData.learningGoals) {
      parts.push(`Mục tiêu: ${onboardingData.learningGoals}`);
    }

    if (onboardingData.interests && onboardingData.interests.length > 0) {
      parts.push(`Quan tâm: ${onboardingData.interests.join(', ')}`);
    }

    if (onboardingData.dailyTime) {
      parts.push(`Thời gian học: ${onboardingData.dailyTime} phút/ngày`);
    }

    return parts.join('. ') || 'Học tập chung';
  }

  /**
   * Tạo lộ trình thông minh dựa trên trình độ và mục tiêu của user
   * SỬ DỤNG TRỰC TIẾP LearningNode từ DB
   */
  private async generateSmartPlan(
    learningGoal: string,
    subjectMindMap: { nodes: any[]; edges: any[] },
    extractedData: {
      currentLevel?: 'beginner' | 'intermediate' | 'advanced';
      interestedTopics?: string[];
      learningGoals?: string;
      preferredPace?: 'slow' | 'normal' | 'fast';
      depthPreference?: 'simplified' | 'standard' | 'comprehensive';
      focusAreas?: string[];
      skipBasics?: boolean;
    },
    subjectId: string,
  ): Promise<{ nodes: PersonalMindMapNode[]; edges: PersonalMindMapEdge[] }> {
    const subjectNode = subjectMindMap.nodes.find((n) => n.type === 'subject');
    const domains = subjectMindMap.nodes.filter((n) => n.type === 'domain');

    // LẤY TRỰC TIẾP LearningNodes từ DB cho subject này
    const learningNodes = await this.learningNodeRepo.find({
      where: { subjectId },
      order: { order: 'ASC' },
    });

    if (learningNodes.length === 0) {
      throw new Error('Môn học này chưa có bài học nào. Vui lòng liên hệ admin.');
    }

    // Xác định độ chi tiết dựa trên trình độ, tốc độ học và preference
    const level = extractedData.currentLevel || 'beginner';
    const pace = extractedData.preferredPace || 'normal';
    const interestedTopics = extractedData.interestedTopics || [];
    const depthPref = extractedData.depthPreference;
    const focusAreas = extractedData.focusAreas || [];
    const skipBasics = extractedData.skipBasics || false;

    // Tính số lượng topics nên chọn
    let maxTopics: number;
    let depthLevel: 'basic' | 'standard' | 'comprehensive';

    // Ưu tiên depthPreference từ user nếu có
    if (depthPref === 'simplified') {
      maxTopics = 5;
      depthLevel = 'basic';
    } else if (depthPref === 'comprehensive') {
      maxTopics = 20;
      depthLevel = 'comprehensive';
    } else if (level === 'beginner') {
      maxTopics = pace === 'fast' ? 5 : pace === 'slow' ? 8 : 6;
      depthLevel = 'basic';
    } else if (level === 'intermediate') {
      maxTopics = pace === 'fast' ? 8 : pace === 'slow' ? 15 : 10;
      depthLevel = 'standard';
    } else {
      maxTopics = pace === 'fast' ? 10 : pace === 'slow' ? 20 : 15;
      depthLevel = 'comprehensive';
    }

    // Tạo prompt với DANH SÁCH BÀI HỌC THỰC TẾ từ DB
    const prompt = `Bạn là một AI giáo dục chuyên tạo lộ trình học tập cá nhân hóa.

THÔNG TIN HỌC VIÊN:
- Trình độ: ${level === 'beginner' ? 'Người mới bắt đầu' : level === 'intermediate' ? 'Đã có kiến thức cơ bản' : 'Nâng cao'}
- Tốc độ học: ${pace === 'slow' ? 'Học chậm và chắc' : pace === 'fast' ? 'Học nhanh, tập trung trọng tâm' : 'Bình thường'}
- Mục tiêu: ${learningGoal}
${interestedTopics.length > 0 ? `- Quan tâm đặc biệt: ${interestedTopics.join(', ')}` : ''}
${focusAreas.length > 0 ? `- Muốn tập trung vào: ${focusAreas.join(', ')}` : ''}
${skipBasics ? '- YÊU CẦU: Bỏ qua các bài học cơ bản, tập trung vào nội dung chuyên sâu' : ''}

MÔN HỌC: ${subjectNode?.name || 'Không xác định'}

CÁC CHƯƠNG (Tham khảo):
${domains.map((d, i) => `${i + 1}. ${d.name}`).join('\n')}

⚠️ DANH SÁCH BÀI HỌC CÓ SẴN (BẮT BUỘC CHỌN TỪ DANH SÁCH NÀY):
${learningNodes.map((ln, i) => `${i + 1}. "${ln.title}" (ID: ${ln.id})${ln.description ? ` - ${ln.description.substring(0, 50)}...` : ''}`).join('\n')}

YÊU CẦU TẠO LỘ TRÌNH:
1. CHỈ ĐƯỢC CHỌN TỪ DANH SÁCH BÀI HỌC Ở TRÊN (dùng đúng ID)
2. Độ chi tiết: ${depthLevel === 'basic' ? 'GIẢN LƯỢC - 3-5 bài' : depthLevel === 'standard' ? 'TIÊU CHUẨN - 6-10 bài' : 'TOÀN DIỆN - 10+ bài'}
3. Số lượng bài học tối đa: ${Math.min(maxTopics, learningNodes.length)}
4. Sắp xếp theo thứ tự học logic
5. Nếu user quan tâm chủ đề cụ thể, ưu tiên các bài liên quan

Trả về JSON:
{
  "selectedLessons": [
    {
      "learningNodeId": "uuid từ danh sách trên",
      "title": "tên bài học",
      "priority": "high" | "medium" | "low",
      "estimatedDays": number,
      "reason": "lý do chọn bài này",
      "difficulty": "easy" | "medium" | "hard"
    }
  ],
  "learningPath": ["learningNodeId1", "learningNodeId2", ...],
  "summary": "tóm tắt ngắn về lộ trình"
}

QUAN TRỌNG: CHỈ SỬ DỤNG ID TỪ DANH SÁCH BÀI HỌC Ở TRÊN. KHÔNG TỰ TẠO ID MỚI.
CHỈ TRẢ VỀ JSON.`;

    try {
      const response = await this.aiService.chat([
        { role: 'user', content: prompt },
      ]);
      const cleanedResponse = response
        .replace(/```json\n?/g, '')
        .replace(/```\n?/g, '')
        .trim();
      const aiPlan = JSON.parse(cleanedResponse);

      // Tạo map từ ID sang LearningNode
      const learningNodeMap = new Map<string, LearningNode>();
      learningNodes.forEach((ln) => learningNodeMap.set(ln.id, ln));

      // Tạo nodes và edges với liên kết TRỰC TIẾP đến LearningNode
      return this.buildMindMapFromLearningNodes(
        aiPlan,
        learningGoal,
        learningNodeMap,
        level,
      );
    } catch (error) {
      console.error('Error generating smart plan:', error);
      // Fallback: Lấy các bài học đầu tiên
      const selectedNodes = learningNodes.slice(0, maxTopics);
      return this.createDefaultPlanFromLearningNodes(learningGoal, selectedNodes);
    }
  }

  /**
   * Build mind map structure từ AI plan với LearningNode thực tế từ DB
   */
  private buildMindMapFromLearningNodes(
    aiPlan: any,
    learningGoal: string,
    learningNodeMap: Map<string, LearningNode>,
    level: string,
  ): { nodes: PersonalMindMapNode[]; edges: PersonalMindMapEdge[] } {
    const nodes: PersonalMindMapNode[] = [];
    const edges: PersonalMindMapEdge[] = [];

    // Node gốc - Mục tiêu
    const goalNode: PersonalMindMapNode = {
      id: 'goal-root',
      title: 'Mục tiêu của bạn',
      description: learningGoal,
      level: 1,
      position: { x: 600, y: 50 },
      status: 'in_progress',
      priority: 'high',
      metadata: {
        icon: '🎯',
        color: '#FF6B6B',
      },
    };
    nodes.push(goalNode);

    // Lấy danh sách bài học được chọn
    const selectedLessons = aiPlan.selectedLessons || [];

    // Nhóm bài học theo difficulty
    const easyLessons = selectedLessons.filter((l: any) => l.difficulty === 'easy');
    const mediumLessons = selectedLessons.filter((l: any) => l.difficulty === 'medium');
    const hardLessons = selectedLessons.filter((l: any) => l.difficulty === 'hard' || !l.difficulty);

    let yOffset = 150;
    let prevNodeId = goalNode.id;

    // Track whether we've set the first milestone
    let firstMilestoneSet = false;

    // Tạo milestone cho Easy lessons
    if (easyLessons.length > 0) {
      const milestoneEasy: PersonalMindMapNode = {
        id: 'milestone-basic',
        title: level === 'beginner' ? '🌱 Nền tảng cơ bản' : '⚡ Ôn tập nhanh',
        description: `${easyLessons.length} bài học cơ bản`,
        level: 2,
        parentId: goalNode.id,
        position: { x: 600, y: yOffset },
        status: !firstMilestoneSet ? 'in_progress' : 'not_started',
        priority: level === 'beginner' ? 'high' : 'low',
        metadata: { icon: '🌱', color: '#4ECDC4' },
      };
      firstMilestoneSet = true;
      nodes.push(milestoneEasy);
      edges.push({
        id: `edge-goal-${milestoneEasy.id}`,
        from: goalNode.id,
        to: milestoneEasy.id,
        type: 'leads_to',
      });

      this.addLearningNodeItems(nodes, edges, easyLessons, milestoneEasy.id, learningNodeMap, yOffset + 80, milestoneEasy.status === 'in_progress');
      yOffset += 80 + easyLessons.length * 60 + 50;
      prevNodeId = milestoneEasy.id;
    }

    // Tạo milestone cho Medium lessons
    if (mediumLessons.length > 0) {
      const milestoneMedium: PersonalMindMapNode = {
        id: 'milestone-intermediate',
        title: '📚 Kiến thức cốt lõi',
        description: `${mediumLessons.length} bài học quan trọng`,
        level: 2,
        parentId: goalNode.id,
        position: { x: 600, y: yOffset },
        status: !firstMilestoneSet ? 'in_progress' : 'not_started',
        priority: 'high',
        metadata: { icon: '📚', color: '#FFE66D' },
      };
      firstMilestoneSet = true;
      nodes.push(milestoneMedium);
      edges.push({
        id: `edge-${prevNodeId}-${milestoneMedium.id}`,
        from: prevNodeId,
        to: milestoneMedium.id,
        type: 'leads_to',
      });

      this.addLearningNodeItems(nodes, edges, mediumLessons, milestoneMedium.id, learningNodeMap, yOffset + 80, milestoneMedium.status === 'in_progress');
      yOffset += 80 + mediumLessons.length * 60 + 50;
      prevNodeId = milestoneMedium.id;
    }

    // Tạo milestone cho Hard lessons
    if (hardLessons.length > 0) {
      const milestoneHard: PersonalMindMapNode = {
        id: 'milestone-advanced',
        title: '🚀 Nâng cao & Chuyên sâu',
        description: `${hardLessons.length} bài học nâng cao`,
        level: 2,
        parentId: goalNode.id,
        position: { x: 600, y: yOffset },
        status: !firstMilestoneSet ? 'in_progress' : 'not_started',
        priority: level === 'advanced' ? 'high' : 'medium',
        metadata: { icon: '🚀', color: '#FF6B6B' },
      };
      firstMilestoneSet = true;
      nodes.push(milestoneHard);
      edges.push({
        id: `edge-${prevNodeId}-${milestoneHard.id}`,
        from: prevNodeId,
        to: milestoneHard.id,
        type: 'leads_to',
      });

      this.addLearningNodeItems(nodes, edges, hardLessons, milestoneHard.id, learningNodeMap, yOffset + 80, milestoneHard.status === 'in_progress');
    }

    return { nodes, edges };
  }

  /**
   * Thêm các bài học vào milestone - SỬ DỤNG LearningNode THỰC TẾ
   * @param unlockFirst - nếu true, bài học đầu tiên sẽ được mở khóa (in_progress)
   */
  private addLearningNodeItems(
    nodes: PersonalMindMapNode[],
    edges: PersonalMindMapEdge[],
    lessons: any[],
    parentId: string,
    learningNodeMap: Map<string, LearningNode>,
    startY: number,
    unlockFirst = false,
  ): void {
    const startX = 300;
    const spacingX = 300;
    const spacingY = 60;

    lessons.forEach((lessonInfo, index) => {
      // Tìm LearningNode thực tế từ DB
      const learningNode = learningNodeMap.get(lessonInfo.learningNodeId);
      
      if (!learningNode) {
        console.warn(`LearningNode not found for ID: ${lessonInfo.learningNodeId}`);
        return; // Skip nếu không tìm thấy
      }

      const col = index % 2;
      const row = Math.floor(index / 2);

      const node: PersonalMindMapNode = {
        id: `lesson-${learningNode.id}`,
        title: learningNode.title, // Sử dụng title từ DB
        description: lessonInfo.reason || learningNode.description,
        level: 3,
        parentId: parentId,
        position: {
          x: startX + col * spacingX,
          y: startY + row * spacingY,
        },
        status: unlockFirst && index === 0 ? 'in_progress' : 'not_started',
        priority: lessonInfo.priority || 'medium',
        estimatedDays: lessonInfo.estimatedDays || 3,
        metadata: {
          icon: this.getTopicIcon(index),
          color: this.getPriorityColor(lessonInfo.priority || 'medium'),
          // LIÊN KẾT TRỰC TIẾP ĐẾN LearningNode TRONG DB
          linkedLearningNodeId: learningNode.id,
          linkedLearningNodeTitle: learningNode.title,
          hasLearningContent: true, // Chắc chắn có vì lấy từ DB
          learningNodeType: learningNode.type, // theory, video, image
        },
      };
      nodes.push(node);

      edges.push({
        id: `edge-${parentId}-${node.id}`,
        from: parentId,
        to: node.id,
        type: 'leads_to',
      });
    });
  }

  /**
   * Tạo lộ trình mặc định từ LearningNodes khi AI fail
   */
  private createDefaultPlanFromLearningNodes(
    learningGoal: string,
    learningNodes: LearningNode[],
  ): { nodes: PersonalMindMapNode[]; edges: PersonalMindMapEdge[] } {
    const nodes: PersonalMindMapNode[] = [];
    const edges: PersonalMindMapEdge[] = [];

    const goalNode: PersonalMindMapNode = {
      id: 'goal-root',
      title: 'Mục tiêu của bạn',
      description: learningGoal,
      level: 1,
      position: { x: 600, y: 100 },
      status: 'in_progress',
      priority: 'high',
      metadata: { icon: '🎯', color: '#FF6B6B' },
    };
    nodes.push(goalNode);

    let prevNodeId = goalNode.id;

    learningNodes.forEach((learningNode, index) => {
      const row = Math.floor(index / 4);
      const col = index % 4;

      const node: PersonalMindMapNode = {
        id: `lesson-${learningNode.id}`,
        title: learningNode.title,
        description: learningNode.description,
        level: 3,
        parentId: goalNode.id,
        position: {
          x: 200 + col * 250,
          y: 250 + row * 150,
        },
        status: index === 0 ? 'in_progress' : 'not_started',
        priority: 'medium',
        estimatedDays: 3,
        metadata: {
          icon: this.getTopicIcon(index),
          // LIÊN KẾT TRỰC TIẾP
          linkedLearningNodeId: learningNode.id,
          linkedLearningNodeTitle: learningNode.title,
          hasLearningContent: true,
          learningNodeType: learningNode.type,
        },
      };
      nodes.push(node);

      edges.push({
        id: `edge-${prevNodeId}-${node.id}`,
        from: index === 0 ? goalNode.id : prevNodeId,
        to: node.id,
        type: 'leads_to',
      });
      prevNodeId = node.id;
    });

    return { nodes, edges };
  }

  private getTopicIcon(index: number): string {
    const icons = ['📖', '💡', '🔬', '📊', '🎨', '⚡', '🌟', '🔥', '🚀', '💎'];
    return icons[index % icons.length];
  }

  private getPriorityColor(priority: string): string {
    const colors: Record<string, string> = {
      high: '#FF6B6B',
      medium: '#FFE66D',
      low: '#4ECDC4',
    };
    return colors[priority] || colors.medium;
  }

  /**
   * Kiểm tra xem user đã có personal mind map cho subject chưa
   */
  async checkExists(
    userId: string,
    subjectId: string,
  ): Promise<{ exists: boolean; mindMap?: PersonalMindMap }> {
    const mindMap = await this.personalMindMapRepo.findOne({
      where: { userId, subjectId },
    });

    return {
      exists: !!mindMap,
      mindMap: mindMap || undefined,
    };
  }

  /**
   * Lấy personal mind map của user cho subject
   */
  async getPersonalMindMap(
    userId: string,
    subjectId: string,
  ): Promise<PersonalMindMap | null> {
    return this.personalMindMapRepo.findOne({
      where: { userId, subjectId },
      relations: ['subject'],
    });
  }

  /**
   * Lấy personal mind map với premium lock status
   * First 2 lesson nodes are free, rest require premium
   */
  async getPersonalMindMapWithPremiumStatus(
    userId: string,
    subjectId: string,
  ): Promise<{
    mindMap: PersonalMindMap | null;
    isPremium: boolean;
    nodesWithLockStatus: (PersonalMindMapNode & { isLocked: boolean; requiresPremium: boolean })[];
  }> {
    const mindMap = await this.personalMindMapRepo.findOne({
      where: { userId, subjectId },
      relations: ['subject'],
    });

    if (!mindMap) {
      return {
        mindMap: null,
        isPremium: false,
        nodesWithLockStatus: [],
      };
    }

    const isPremium = await this.checkUserPremium(userId);

    // Count only lesson nodes (not milestone or goal nodes)
    let lessonNodeCount = 0;
    const nodesWithLockStatus = mindMap.nodes.map((node) => {
      // Check if this is a lesson node (has linkedLearningNodeId)
      const isLessonNode = node.id.startsWith('lesson-') || node.metadata?.linkedLearningNodeId;
      
      let isLocked = false;
      let requiresPremium = false;
      
      if (isLessonNode) {
        requiresPremium = lessonNodeCount >= FREE_MIND_MAP_NODES_LIMIT;
        isLocked = !isPremium && requiresPremium;
        lessonNodeCount++;
      }

      return {
        ...node,
        isLocked,
        requiresPremium,
      };
    });

    return {
      mindMap,
      isPremium,
      nodesWithLockStatus,
    };
  }

  /**
   * Tạo personal mind map mới dựa trên mục tiêu học tập (không cần onboarding)
   */
  async createPersonalMindMap(
    userId: string,
    subjectId: string,
    learningGoal: string,
  ): Promise<PersonalMindMap> {
    if (!userId) {
      throw new Error('userId is required to create personal mind map');
    }

    // Kiểm tra đã có chưa
    const existing = await this.personalMindMapRepo.findOne({
      where: { userId, subjectId },
    });

    if (existing) {
      return existing;
    }

    // Lấy LearningNodes của subject
    const learningNodes = await this.learningNodeRepo.find({
      where: { subjectId },
      order: { order: 'ASC' },
    });

    if (learningNodes.length === 0) {
      throw new NotFoundException('Môn học này chưa có bài học nào.');
    }

    // Tạo default plan
    const plan = this.createDefaultPlanFromLearningNodes(
      learningGoal,
      learningNodes.slice(0, 10),
    );

    // Tạo personal mind map
    const personalMindMap = new PersonalMindMap();
    personalMindMap.userId = userId;
    personalMindMap.subjectId = subjectId;
    personalMindMap.learningGoal = learningGoal;
    personalMindMap.nodes = plan.nodes;
    personalMindMap.edges = plan.edges;
    personalMindMap.totalNodes = plan.nodes.length;
    personalMindMap.completedNodes = 0;
    personalMindMap.progressPercent = 0;
    personalMindMap.aiConversationHistory = [];

    return this.personalMindMapRepo.save(personalMindMap);
  }

  /**
   * Cập nhật trạng thái node
   */
  async updateNodeStatus(
    userId: string,
    subjectId: string,
    nodeId: string,
    status: 'not_started' | 'in_progress' | 'completed',
  ): Promise<PersonalMindMap> {
    const mindMap = await this.personalMindMapRepo.findOne({
      where: { userId, subjectId },
    });

    if (!mindMap) {
      throw new NotFoundException('Personal mind map không tồn tại');
    }

    // Cập nhật status của node
    mindMap.nodes = mindMap.nodes.map((node) => {
      if (node.id === nodeId) {
        return { ...node, status };
      }
      return node;
    });

    // Tính lại progress
    mindMap.completedNodes = mindMap.nodes.filter(
      (n) => n.status === 'completed',
    ).length;
    mindMap.progressPercent =
      mindMap.totalNodes > 0
        ? (mindMap.completedNodes / mindMap.totalNodes) * 100
        : 0;

    return this.personalMindMapRepo.save(mindMap);
  }

  /**
   * Xóa personal mind map
   */
  async deletePersonalMindMap(
    userId: string,
    subjectId: string,
  ): Promise<void> {
    await this.personalMindMapRepo.delete({ userId, subjectId });
  }
}
