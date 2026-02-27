import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { LearningNode } from './entities/learning-node.entity';
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

@Injectable()
export class LessonContentService {
  constructor(
    @InjectRepository(LearningNode)
    private readonly nodeRepository: Repository<LearningNode>,
    private readonly aiService: AiService,
    private readonly lessonTypeContentsService: LessonTypeContentsService,
  ) {}

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
  }> {
    const node = await this.nodeRepository.findOne({ where: { id: nodeId } });
    if (!node) throw new NotFoundException('Learning node not found');

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
      "correctAnswer": 0
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

      return {
        questions: parsed.questions || [],
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

    const score = Math.round((correctCount / questions.length) * 100);
    const passingScore = node.endQuiz.passingScore || 70;

    return {
      passed: score >= passingScore,
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

    const score = Math.round((correctCount / questions.length) * 100);
    const passingScore = endQuiz.passingScore || 70;

    return {
      passed: score >= passingScore,
      score,
      totalQuestions: questions.length,
      correctCount,
      results,
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
  }> {
    const node = await this.nodeRepository.findOne({ where: { id: nodeId } });
    if (!node) throw new NotFoundException('Learning node not found');

    const typeContent = await this.lessonTypeContentsService.getByNodeIdAndType(nodeId, lessonType);
    if (!typeContent) {
      throw new NotFoundException(`Lesson type "${lessonType}" not found for node ${nodeId}`);
    }

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
