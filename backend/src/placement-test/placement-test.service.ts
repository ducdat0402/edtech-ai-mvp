import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PlacementTest, TestStatus, DifficultyLevel } from './entities/placement-test.entity';
import { Question } from './entities/question.entity';
import { UsersService } from '../users/users.service';

@Injectable()
export class PlacementTestService {
  constructor(
    @InjectRepository(PlacementTest)
    private testRepository: Repository<PlacementTest>,
    @InjectRepository(Question)
    private questionRepository: Repository<Question>,
    private usersService: UsersService,
  ) {}

  async startTest(userId: string, subjectId?: string): Promise<PlacementTest> {
    // Check if user already has an active test
    const existingTest = await this.testRepository.findOne({
      where: {
        userId,
        status: TestStatus.IN_PROGRESS,
      },
    });

    if (existingTest) {
      return existingTest;
    }

    // Get questions based on subject (or general if no subject)
    // Use 5-10 questions depending on availability
    const questions = await this.getQuestionsForTest(subjectId, 10);
    
    if (questions.length === 0) {
      throw new BadRequestException('No questions available for placement test. Please seed the database first.');
    }

    // Create test
    const test = this.testRepository.create({
      userId,
      subjectId: subjectId || null,
      status: TestStatus.IN_PROGRESS,
      questions: questions.map((q) => ({
        questionId: q.id,
        question: q.question,
        options: q.options,
        correctAnswer: q.correctAnswer,
        difficulty: q.difficulty,
      })),
      currentQuestionIndex: 0,
      adaptiveData: {
        currentDifficulty: DifficultyLevel.BEGINNER,
        correctStreak: 0,
        incorrectStreak: 0,
        totalCorrect: 0,
        totalAnswered: 0,
      },
      startedAt: new Date(),
    });

    return this.testRepository.save(test);
  }

  async getCurrentTest(userId: string): Promise<PlacementTest | null> {
    return this.testRepository.findOne({
      where: {
        userId,
        status: TestStatus.IN_PROGRESS,
      },
      order: { createdAt: 'DESC' },
    });
  }

  async getCurrentQuestion(userId: string): Promise<{
    test: PlacementTest;
    question: any;
    progress: { current: number; total: number };
  }> {
    const test = await this.getCurrentTest(userId);
    if (!test) {
      throw new NotFoundException('No active test found');
    }

    if (test.currentQuestionIndex >= test.questions.length) {
      throw new BadRequestException('Test already completed');
    }

    const currentQuestion = test.questions[test.currentQuestionIndex];
    const question = await this.questionRepository.findOne({
      where: { id: currentQuestion.questionId },
    });

    return {
      test,
      question: {
        id: question.id,
        question: currentQuestion.question,
        options: currentQuestion.options,
        difficulty: currentQuestion.difficulty,
      },
      progress: {
        current: test.currentQuestionIndex + 1,
        total: test.questions.length,
      },
    };
  }

  async submitAnswer(
    userId: string,
    answer: number,
  ): Promise<{
    test: PlacementTest;
    isCorrect: boolean;
    explanation?: string;
    nextQuestion?: any;
    completed: boolean;
  }> {
    const test = await this.getCurrentTest(userId);
    if (!test) {
      throw new NotFoundException('No active test found');
    }

    if (test.currentQuestionIndex >= test.questions.length) {
      throw new BadRequestException('Test already completed');
    }

    const currentQuestion = test.questions[test.currentQuestionIndex];
    const isCorrect = answer === currentQuestion.correctAnswer;

    // Update question with answer
    currentQuestion.userAnswer = answer;
    currentQuestion.isCorrect = isCorrect;
    currentQuestion.answeredAt = new Date();

    // Update adaptive data
    test.adaptiveData.totalAnswered++;
    if (isCorrect) {
      test.adaptiveData.totalCorrect++;
      test.adaptiveData.correctStreak++;
      test.adaptiveData.incorrectStreak = 0;
    } else {
      test.adaptiveData.correctStreak = 0;
      test.adaptiveData.incorrectStreak++;
    }

    // Adaptive difficulty adjustment
    if (test.adaptiveData.correctStreak >= 2 && test.adaptiveData.currentDifficulty === DifficultyLevel.BEGINNER) {
      test.adaptiveData.currentDifficulty = DifficultyLevel.INTERMEDIATE;
    } else if (test.adaptiveData.correctStreak >= 2 && test.adaptiveData.currentDifficulty === DifficultyLevel.INTERMEDIATE) {
      test.adaptiveData.currentDifficulty = DifficultyLevel.ADVANCED;
    } else if (test.adaptiveData.incorrectStreak >= 2 && test.adaptiveData.currentDifficulty === DifficultyLevel.ADVANCED) {
      test.adaptiveData.currentDifficulty = DifficultyLevel.INTERMEDIATE;
    } else if (test.adaptiveData.incorrectStreak >= 2 && test.adaptiveData.currentDifficulty === DifficultyLevel.INTERMEDIATE) {
      test.adaptiveData.currentDifficulty = DifficultyLevel.BEGINNER;
    }

    // Move to next question
    test.currentQuestionIndex++;

    // Check if completed
    const completed = test.currentQuestionIndex >= test.questions.length;

    if (completed) {
      // Calculate score and level
      const score = Math.round(
        (test.adaptiveData.totalCorrect / test.adaptiveData.totalAnswered) * 100,
      );
      test.score = score;
      test.status = TestStatus.COMPLETED;
      test.completedAt = new Date();

      // Determine level based on score and final difficulty
      if (score >= 80 && test.adaptiveData.currentDifficulty === DifficultyLevel.ADVANCED) {
        test.level = DifficultyLevel.ADVANCED;
      } else if (score >= 60) {
        test.level = DifficultyLevel.INTERMEDIATE;
      } else {
        test.level = DifficultyLevel.BEGINNER;
      }

      // Save to user profile
      await this.usersService.updatePlacementTest(
        userId,
        score,
        test.level,
      );
    }

    const savedTest = await this.testRepository.save(test);

    // Get explanation for current question
    const question = await this.questionRepository.findOne({
      where: { id: currentQuestion.questionId },
    });

    const result: any = {
      test: savedTest,
      isCorrect,
      explanation: question?.explanation,
      completed,
    };

    // If not completed, get next question
    if (!completed) {
      const nextQuestion = savedTest.questions[savedTest.currentQuestionIndex];
      const nextQuestionData = await this.questionRepository.findOne({
        where: { id: nextQuestion.questionId },
      });
      result.nextQuestion = {
        id: nextQuestionData.id,
        question: nextQuestion.question,
        options: nextQuestion.options,
        difficulty: nextQuestion.difficulty,
      };
    }

    return result;
  }

  async getTestResult(userId: string, testId: string): Promise<PlacementTest> {
    const test = await this.testRepository.findOne({
      where: { id: testId, userId },
    });

    if (!test) {
      throw new NotFoundException('Test not found');
    }

    return test;
  }

  private async getQuestionsForTest(
    subjectId: string | undefined,
    count: number,
  ): Promise<Question[]> {
    // Start with beginner questions, will adapt based on answers
    const where: any = { difficulty: DifficultyLevel.BEGINNER };
    if (subjectId) {
      where.subjectId = subjectId;
    }

    const questions = await this.questionRepository.find({
      where,
      take: count,
      order: { createdAt: 'DESC' },
    });

    // If not enough questions, get from other difficulties
    if (questions.length < count) {
      const whereClause: any = {};
      if (subjectId) {
        whereClause.subjectId = subjectId;
      }
      
      const additional = await this.questionRepository.find({
        where: whereClause,
        take: count - questions.length,
        order: { createdAt: 'DESC' },
      });
      
      // Avoid duplicates
      const existingIds = new Set(questions.map(q => q.id));
      const uniqueAdditional = additional.filter(q => !existingIds.has(q.id));
      questions.push(...uniqueAdditional);
    }

    return questions.slice(0, count);
  }
}

