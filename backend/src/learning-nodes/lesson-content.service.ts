import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { LearningNode } from './entities/learning-node.entity';
import { LearningQuizAttempt } from './entities/learning-quiz-attempt.entity';
import { LearningCommunicationAttempt } from './entities/learning-communication-attempt.entity';
import { AiService } from '../ai/ai.service';
import {
  LessonType,
  UpdateLessonContentDto,
  EndQuizData,
  EndQuizResultDto,
  validateLessonContent,
  validateEndQuiz,
} from './dto/lesson-content.dto';
import { LessonTypeContentsService } from '../lesson-type-contents/lesson-type-contents.service';
import { UsersService } from '../users/users.service';

@Injectable()
export class LessonContentService {
  constructor(
    @InjectRepository(LearningNode)
    private readonly nodeRepository: Repository<LearningNode>,
    @InjectRepository(LearningQuizAttempt)
    private readonly quizAttemptRepository: Repository<LearningQuizAttempt>,
    @InjectRepository(LearningCommunicationAttempt)
    private readonly communicationAttemptRepository: Repository<LearningCommunicationAttempt>,
    private readonly aiService: AiService,
    private readonly lessonTypeContentsService: LessonTypeContentsService,
    private readonly usersService: UsersService,
  ) {}

  private async recordQuizAttempt(params: {
    userId: string;
    nodeId: string;
    lessonType: string | null;
    score: number;
    passed: boolean;
    totalQuestions: number;
    correctCount: number;
    confidencePercent: number | null;
    questionResults: Array<{
      questionIndex: number;
      isCorrect: boolean;
      competencyMix: Record<string, number>;
      logicalWeight: number;
      responseTimeMs: number | null;
    }>;
  }): Promise<void> {
    await this.quizAttemptRepository.save(
      this.quizAttemptRepository.create({
        userId: params.userId,
        nodeId: params.nodeId,
        lessonType: params.lessonType,
        score: params.score,
        passed: params.passed,
        totalQuestions: params.totalQuestions,
        correctCount: params.correctCount,
        confidencePercent: params.confidencePercent,
        questionResults: params.questionResults,
      }),
    );
  }

  private normalizeCompetencyMix(
    rawMix: unknown,
    fallback: Record<string, number> = { logical_thinking: 1 },
  ): Record<string, number> {
    if (!rawMix || typeof rawMix !== 'object' || Array.isArray(rawMix)) {
      return fallback;
    }
    const entries = Object.entries(rawMix as Record<string, unknown>).filter(
      ([k, v]) => k.trim() && typeof v === 'number' && Number.isFinite(v) && v > 0,
    ) as Array<[string, number]>;
    if (entries.length === 0) return fallback;
    const sum = entries.reduce((s, [, v]) => s + v, 0);
    if (sum <= 0) return fallback;

    const normalized: Record<string, number> = {};
    for (const [k, v] of entries) {
      normalized[k] = Math.round((v / sum) * 1000) / 1000;
    }
    return normalized;
  }

  private normalizeResponseTimeMs(value: unknown): number | null {
    if (typeof value !== 'number' || !Number.isFinite(value)) return null;
    const rounded = Math.round(value);
    if (rounded <= 0) return null;
    return Math.min(120000, rounded);
  }

  private normalizeConfidencePercent(value: unknown): number | null {
    if (value === undefined || value === null) return null;
    if (typeof value !== 'number' || !Number.isFinite(value)) {
      throw new BadRequestException('confidencePercent must be a number in [0, 100]');
    }
    const rounded = Math.round(value);
    if (rounded < 0 || rounded > 100) {
      throw new BadRequestException('confidencePercent must be in [0, 100]');
    }
    return rounded;
  }

  private normalizeCommunicationText(value: unknown): string {
    if (typeof value !== 'string') {
      throw new BadRequestException('responseText must be a string');
    }
    const text = value.trim().replace(/\s+/g, ' ');
    if (!text) {
      throw new BadRequestException('responseText is required');
    }
    const words = text.split(' ').filter(Boolean);
    if (words.length < 40) {
      throw new BadRequestException('responseText must be at least 40 words');
    }
    return text;
  }

  private async scoreCommunicationText(params: {
    nodeTitle: string;
    lessonType: string | null;
    contentSummary: string;
    responseText: string;
  }): Promise<{
    clarity: number;
    structure: number;
    coverage: number;
    audienceFit: number;
    conciseness: number;
    totalScore: number;
    feedbackShort: string;
  }> {
    const prompt = `Bạn là giám khảo chấm năng lực "Giao tiếp & diễn đạt" cho học sinh.

BỐI CẢNH:
- Bài học: "${params.nodeTitle}"
- Loại bài: ${params.lessonType ?? 'unknown'}
- Tóm tắt kiến thức gốc:
${params.contentSummary}

BÀI GIẢNG LẠI CỦA HỌC SINH (tiếng Việt):
${params.responseText}

Hãy chấm theo rubric (0-100):
- clarity: rõ ràng, dễ hiểu
- structure: bố cục/mạch diễn đạt
- coverage: độ bao phủ ý chính của bài học
- audienceFit: phù hợp người mới học
- conciseness: gọn, không lan man

Tổng điểm:
totalScore = round(clarity*0.25 + structure*0.2 + coverage*0.3 + audienceFit*0.15 + conciseness*0.1)

Viết feedbackShort (1-2 câu tiếng Việt), chỉ nêu điểm mạnh/yếu chính, không quá 240 ký tự.

TRẢ VỀ JSON DUY NHẤT:
{
  "clarity": 0,
  "structure": 0,
  "coverage": 0,
  "audienceFit": 0,
  "conciseness": 0,
  "totalScore": 0,
  "feedbackShort": ""
}`;

    const fallback = {
      clarity: 60,
      structure: 60,
      coverage: 60,
      audienceFit: 60,
      conciseness: 60,
      totalScore: 60,
      feedbackShort:
        'Bài giảng lại có nền tảng tốt. Hãy trình bày ngắn gọn hơn và làm rõ các ý chính để người mới dễ theo dõi.',
    };

    try {
      const response = await this.aiService.chat([{ role: 'user', content: prompt }]);
      const cleaned = response
        .replace(/```json\n?/g, '')
        .replace(/```\n?/g, '')
        .trim();
      const parsed = JSON.parse(cleaned) as Record<string, unknown>;
      const readScore = (k: string, def = 60) => {
        const n = Number(parsed[k]);
        if (!Number.isFinite(n)) return def;
        return Math.max(0, Math.min(100, Math.round(n)));
      };
      const clarity = readScore('clarity');
      const structure = readScore('structure');
      const coverage = readScore('coverage');
      const audienceFit = readScore('audienceFit');
      const conciseness = readScore('conciseness');
      const weighted = Math.round(
        clarity * 0.25 +
          structure * 0.2 +
          coverage * 0.3 +
          audienceFit * 0.15 +
          conciseness * 0.1,
      );
      const totalScore = readScore('totalScore', weighted);
      const feedbackRaw =
        typeof parsed.feedbackShort === 'string' ? parsed.feedbackShort.trim() : '';
      const feedbackShort = feedbackRaw
        ? feedbackRaw.slice(0, 240)
        : fallback.feedbackShort;
      return {
        clarity,
        structure,
        coverage,
        audienceFit,
        conciseness,
        totalScore,
        feedbackShort,
      };
    } catch {
      return fallback;
    }
  }

  private async contributorPayload(
    contributorId: string | null | undefined,
  ): Promise<{
    id: string;
    fullName: string;
    avatarUrl: string | null;
  } | null> {
    if (!contributorId) return null;
    const u = await this.usersService.findById(contributorId);
    if (!u) return null;
    return {
      id: u.id,
      fullName: u.fullName?.trim() || 'Thành viên',
      avatarUrl: u.avatarUrl ?? null,
    };
  }

  /**
   * Get lesson data for a learning node
   */
  async getLessonData(nodeId: string): Promise<{
    id: string;
    title: string;
    description: string;
    lessonType: LessonType | null;
    lessonData: any;
    endQuiz: EndQuizData | null;
    difficulty: string;
    subjectId: string;
    domainId: string | null;
    contributor: {
      id: string;
      fullName: string;
      avatarUrl: string | null;
    } | null;
  }> {
    const node = await this.nodeRepository.findOne({ where: { id: nodeId } });
    if (!node) throw new NotFoundException('Learning node not found');

    const contributor = await this.contributorPayload(node.contributorId);

    return {
      id: node.id,
      title: node.title,
      description: node.description,
      lessonType: node.lessonType as LessonType | null,
      lessonData: node.lessonData,
      endQuiz: node.endQuiz,
      difficulty: node.difficulty,
      subjectId: node.subjectId,
      domainId: node.domainId,
      contributor,
    };
  }

  /**
   * Update lesson content (type + data + quiz)
   */
  async updateLessonContent(
    nodeId: string,
    dto: UpdateLessonContentDto,
  ): Promise<LearningNode> {
    const node = await this.nodeRepository.findOne({ where: { id: nodeId } });
    if (!node) throw new NotFoundException('Learning node not found');

    // Validate lesson content
    const contentValidation = validateLessonContent(dto.lessonType, dto.lessonData);
    if (!contentValidation.valid) {
      throw new BadRequestException({
        message: 'Invalid lesson content',
        errors: contentValidation.errors,
      });
    }

    // Validate end quiz
    const quizValidation = validateEndQuiz(dto.endQuiz);
    if (!quizValidation.valid) {
      throw new BadRequestException({
        message: 'Invalid end quiz',
        errors: quizValidation.errors,
      });
    }

    // Update node
    node.lessonType = dto.lessonType;
    node.lessonData = dto.lessonData as any;
    node.endQuiz = {
      ...dto.endQuiz,
      passingScore: dto.endQuiz.passingScore || 70,
    };

    if (dto.title) node.title = dto.title;
    if (dto.description) node.description = dto.description;

    return this.nodeRepository.save(node);
  }

  /**
   * AI generate end quiz suggestions from lesson content
   */
  async generateEndQuiz(nodeId: string): Promise<EndQuizData> {
    const node = await this.nodeRepository.findOne({ where: { id: nodeId } });
    if (!node) throw new NotFoundException('Learning node not found');

    if (!node.lessonType || !node.lessonData) {
      throw new BadRequestException('Lesson content must be set before generating quiz');
    }

    const contentSummary = this.extractContentSummary(node.lessonType as LessonType, node.lessonData);

    const prompt = `Bạn là AI tạo câu hỏi trắc nghiệm cho bài học "${node.title}".

NỘI DUNG BÀI HỌC:
${contentSummary}

YÊU CẦU:
- Tạo 5 câu hỏi trắc nghiệm (ABCD)
- Mỗi câu có 4 đáp án, 1 đáp án đúng
- Mỗi đáp án có giải thích tại sao đúng/sai
- Câu hỏi phải kiểm tra hiểu biết, không chỉ nhớ
- Độ khó: dễ -> trung bình -> khó (tăng dần)
- Mỗi câu phải có:
  - "logicTypes": mảng tag suy luận, ví dụ ["inference"], ["sequence", "compare"]
  - "competencyMix": object tỷ lệ đóng góp chỉ số, ví dụ { "logical_thinking": 0.35, "practical_application": 0.20, "systems_thinking": 0.20, "creativity": 0.10, "critical_thinking": 0.15 }
- Với mỗi quiz, phải có ít nhất 1-2 câu có trọng số "critical_thinking" >= 0.4
- Ưu tiên câu dạng đánh giá lập luận, phát hiện giả định ẩn, so sánh bằng chứng
- competencyMix phải có tổng gần bằng 1

Trả về JSON:
{
  "questions": [
    {
      "question": "Câu hỏi",
      "options": [
        { "text": "Đáp án A", "explanation": "Giải thích" },
        { "text": "Đáp án B", "explanation": "Giải thích" },
        { "text": "Đáp án C", "explanation": "Giải thích" },
        { "text": "Đáp án D", "explanation": "Giải thích" }
      ],
      "correctAnswer": 0,
      "logicTypes": ["inference"],
      "competencyMix": {
        "logical_thinking": 0.35,
        "practical_application": 0.20,
        "systems_thinking": 0.20,
        "creativity": 0.10,
        "critical_thinking": 0.15
      }
    }
  ]
}

CHỈ TRẢ VỀ JSON.`;

    try {
      const response = await this.aiService.chat([
        { role: 'user', content: prompt },
      ]);

      const cleaned = response.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
      const parsed = JSON.parse(cleaned);
      const questions = Array.isArray(parsed.questions) ? parsed.questions : [];

      return {
        questions: questions.map((q: any) => ({
          ...q,
          logicTypes: Array.isArray(q.logicTypes)
            ? q.logicTypes
                .filter((x: unknown) => typeof x === 'string' && x.trim())
                .map((x: string) => x.trim())
            : [],
          competencyMix: this.normalizeCompetencyMix(q.competencyMix),
        })),
        passingScore: 70,
      };
    } catch (error) {
      console.error('Error generating quiz:', error);
      // Return empty quiz as fallback
      return { questions: [], passingScore: 70 };
    }
  }

  /**
   * Submit end quiz answers and calculate results
   */
  async submitEndQuiz(
    nodeId: string,
    answers: number[],
    userId: string,
    confidencePercent?: number,
    responseTimesMs?: number[],
  ): Promise<EndQuizResultDto> {
    const node = await this.nodeRepository.findOne({ where: { id: nodeId } });
    if (!node) throw new NotFoundException('Learning node not found');

    if (!node.endQuiz || !node.endQuiz.questions || node.endQuiz.questions.length === 0) {
      throw new BadRequestException('This lesson has no end quiz');
    }

    const questions = node.endQuiz.questions;
    if (answers.length !== questions.length) {
      throw new BadRequestException(
        `Expected ${questions.length} answers, got ${answers.length}`,
      );
    }
    if (responseTimesMs && responseTimesMs.length !== questions.length) {
      throw new BadRequestException(
        `Expected ${questions.length} response times, got ${responseTimesMs.length}`,
      );
    }

    let correctCount = 0;
    const results = questions.map((q, index) => {
      const isCorrect = answers[index] === q.correctAnswer;
      if (isCorrect) correctCount++;

      const selectedOption = q.options[answers[index]];
      return {
        questionIndex: index,
        question: q.question,
        selectedAnswer: answers[index],
        correctAnswer: q.correctAnswer,
        isCorrect,
        explanation: selectedOption?.explanation || '',
      };
    });
    const questionResults = questions.map((q, index) => {
      const competencyMix = this.normalizeCompetencyMix(
        (q as { competencyMix?: unknown }).competencyMix,
      );
      return {
        questionIndex: index,
        isCorrect: answers[index] === q.correctAnswer,
        competencyMix,
        logicalWeight: competencyMix.logical_thinking ?? 0,
        responseTimeMs: this.normalizeResponseTimeMs(responseTimesMs?.[index]),
      };
    });

    const score = Math.round((correctCount / questions.length) * 100);
    const passingScore = node.endQuiz.passingScore || 70;
    const passed = score >= passingScore;
    const normalizedConfidence =
      this.normalizeConfidencePercent(confidencePercent);

    await this.recordQuizAttempt({
      userId,
      nodeId,
      lessonType: null,
      score,
      passed,
      totalQuestions: questions.length,
      correctCount,
      confidencePercent: normalizedConfidence,
      questionResults,
    });

    return {
      passed,
      score,
      totalQuestions: questions.length,
      correctCount,
      results,
    };
  }

  /**
   * Submit end quiz answers for a specific lesson type (from lesson_type_contents table)
   */
  async submitEndQuizForType(
    nodeId: string,
    lessonType: string,
    answers: number[],
    userId: string,
    confidencePercent?: number,
    responseTimesMs?: number[],
  ): Promise<EndQuizResultDto> {
    // Try to get from lesson_type_contents table first
    const typeContent = await this.lessonTypeContentsService.getByNodeIdAndType(nodeId, lessonType);

    if (!typeContent) {
      throw new NotFoundException(`Lesson type "${lessonType}" not found for node ${nodeId}`);
    }

    const endQuiz = typeContent.endQuiz;
    if (!endQuiz || !endQuiz.questions || endQuiz.questions.length === 0) {
      throw new BadRequestException('This lesson type has no end quiz');
    }

    const questions = endQuiz.questions;
    if (answers.length !== questions.length) {
      throw new BadRequestException(
        `Expected ${questions.length} answers, got ${answers.length}`,
      );
    }
    if (responseTimesMs && responseTimesMs.length !== questions.length) {
      throw new BadRequestException(
        `Expected ${questions.length} response times, got ${responseTimesMs.length}`,
      );
    }

    let correctCount = 0;
    const results = questions.map((q, index) => {
      const isCorrect = answers[index] === q.correctAnswer;
      if (isCorrect) correctCount++;

      const selectedOption = q.options[answers[index]];
      return {
        questionIndex: index,
        question: q.question,
        selectedAnswer: answers[index],
        correctAnswer: q.correctAnswer,
        isCorrect,
        explanation: selectedOption?.explanation || '',
      };
    });
    const questionResults = questions.map((q, index) => {
      const competencyMix = this.normalizeCompetencyMix(
        (q as { competencyMix?: unknown }).competencyMix,
      );
      return {
        questionIndex: index,
        isCorrect: answers[index] === q.correctAnswer,
        competencyMix,
        logicalWeight: competencyMix.logical_thinking ?? 0,
        responseTimeMs: this.normalizeResponseTimeMs(responseTimesMs?.[index]),
      };
    });

    const score = Math.round((correctCount / questions.length) * 100);
    const passingScore = endQuiz.passingScore || 70;
    const passed = score >= passingScore;
    const normalizedConfidence =
      this.normalizeConfidencePercent(confidencePercent);

    await this.recordQuizAttempt({
      userId,
      nodeId,
      lessonType,
      score,
      passed,
      totalQuestions: questions.length,
      correctCount,
      confidencePercent: normalizedConfidence,
      questionResults,
    });

    return {
      passed,
      score,
      totalQuestions: questions.length,
      correctCount,
      results,
    };
  }

  async submitCommunicationAttempt(params: {
    nodeId: string;
    userId: string;
    responseText: string;
    lessonType?: string;
  }): Promise<{
    totalScore: number;
    aiScores: {
      clarity: number;
      structure: number;
      coverage: number;
      audienceFit: number;
      conciseness: number;
    };
    feedbackShort: string;
  }> {
    const node = await this.nodeRepository.findOne({ where: { id: params.nodeId } });
    if (!node) throw new NotFoundException('Learning node not found');
    const normalizedText = this.normalizeCommunicationText(params.responseText);
    const contentSummary = this.extractContentSummary(
      (node.lessonType as LessonType) ?? 'text',
      node.lessonData ?? {},
    );
    const scored = await this.scoreCommunicationText({
      nodeTitle: node.title,
      lessonType: params.lessonType ?? node.lessonType ?? null,
      contentSummary,
      responseText: normalizedText,
    });
    const aiScores = {
      clarity: scored.clarity,
      structure: scored.structure,
      coverage: scored.coverage,
      audienceFit: scored.audienceFit,
      conciseness: scored.conciseness,
    };
    await this.communicationAttemptRepository.save(
      this.communicationAttemptRepository.create({
        userId: params.userId,
        nodeId: params.nodeId,
        lessonType: params.lessonType ?? node.lessonType ?? null,
        responseText: normalizedText,
        aiScores,
        feedbackShort: scored.feedbackShort,
        totalScore: scored.totalScore,
      }),
    );
    return {
      totalScore: scored.totalScore,
      aiScores,
      feedbackShort: scored.feedbackShort,
    };
  }

  /**
   * Get lesson data for a specific type from the lesson_type_contents table
   */
  async getLessonDataByType(nodeId: string, lessonType: string): Promise<{
    id: string;
    nodeId: string;
    title: string;
    description: string;
    lessonType: string;
    lessonData: any;
    endQuiz: any;
    difficulty: string;
    subjectId: string;
    domainId: string | null;
    contributor: {
      id: string;
      fullName: string;
      avatarUrl: string | null;
    } | null;
  }> {
    const node = await this.nodeRepository.findOne({ where: { id: nodeId } });
    if (!node) throw new NotFoundException('Learning node not found');

    const typeContent = await this.lessonTypeContentsService.getByNodeIdAndType(nodeId, lessonType);
    if (!typeContent) {
      throw new NotFoundException(`Lesson type "${lessonType}" not found for node ${nodeId}`);
    }

    const contributor = await this.contributorPayload(node.contributorId);

    return {
      id: typeContent.id,
      nodeId: node.id,
      title: node.title,
      description: node.description,
      lessonType: typeContent.lessonType,
      lessonData: typeContent.lessonData,
      endQuiz: typeContent.endQuiz,
      difficulty: node.difficulty,
      subjectId: node.subjectId,
      domainId: node.domainId,
      contributor,
    };
  }

  /**
   * Extract content summary for AI quiz generation
   */
  private extractContentSummary(lessonType: LessonType, lessonData: any): string {
    switch (lessonType) {
      case 'image_quiz':
        return `Dạng bài: Hình ảnh trắc nghiệm
${(lessonData.slides || []).map((s: any, i: number) => 
  `Slide ${i + 1}: Câu hỏi: "${s.question}" - Đáp án đúng: ${s.options?.[s.correctAnswer]?.text || ''}`
).join('\n')}`;

      case 'image_gallery':
        return `Dạng bài: Thư viện hình ảnh
${(lessonData.images || []).map((img: any, i: number) =>
  `Hình ${i + 1}: ${img.description}`
).join('\n')}`;

      case 'video':
        return `Dạng bài: Video
Tóm tắt: ${lessonData.summary || ''}
Nội dung chính:
${(lessonData.keyPoints || []).map((kp: any) => `- ${kp.title}: ${kp.description || ''}`).join('\n')}
Từ khóa: ${(lessonData.keywords || []).join(', ')}`;

      case 'text':
        return `Dạng bài: Văn bản
${(lessonData.sections || []).map((s: any) => `## ${s.title}\n${s.content}`).join('\n\n')}
Tóm tắt: ${lessonData.summary || ''}
Mục tiêu: ${(lessonData.learningObjectives || []).join(', ')}`;

      default:
        return 'Không có nội dung';
    }
  }
}
