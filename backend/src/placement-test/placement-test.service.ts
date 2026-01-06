import { Injectable, NotFoundException, BadRequestException, Inject, forwardRef } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PlacementTest, TestStatus, DifficultyLevel } from './entities/placement-test.entity';
import { Question } from './entities/question.entity';
import { UsersService } from '../users/users.service';
import { SubjectsService } from '../subjects/subjects.service';
import { AiService } from '../ai/ai.service';
import { SkillTreeService } from '../skill-tree/skill-tree.service';

@Injectable()
export class PlacementTestService {
  constructor(
    @InjectRepository(PlacementTest)
    private testRepository: Repository<PlacementTest>,
    @InjectRepository(Question)
    private questionRepository: Repository<Question>,
    private usersService: UsersService,
    @Inject(forwardRef(() => SubjectsService))
    private subjectsService: SubjectsService,
    private aiService: AiService,
    @Inject(forwardRef(() => SkillTreeService))
    private skillTreeService: SkillTreeService,
  ) {}

  async startTest(userId: string, subjectId?: string): Promise<PlacementTest> {
    // Check if user already has an active test
    const existingTest = await this.testRepository.findOne({
      where: {
        userId,
        status: TestStatus.IN_PROGRESS,
      },
    });

    // ✅ Nếu có test cũ, complete nó trước khi tạo test mới
    if (existingTest) {
      console.log(`⚠️  Found existing test, completing it first...`);
      existingTest.status = TestStatus.COMPLETED;
      existingTest.completedAt = new Date();
      await this.testRepository.save(existingTest);
      console.log(`✅ Completed old test`);
    }

    // ✅ Nếu không có subjectId, determine từ user's onboarding data
    if (!subjectId) {
      try {
        const user = await this.usersService.findById(userId);
        const onboardingData = user?.onboardingData || {};
        const subject = onboardingData.subject; // Ngành học
        const targetGoal = onboardingData.targetGoal;
        
        console.log(`🔍 User onboarding data:`, JSON.stringify(onboardingData, null, 2));
        console.log(`🔍 Subject (ngành học): "${subject}"`);
        console.log(`🔍 Target goal: "${targetGoal}"`);
        
        // Ưu tiên: Sử dụng subject (ngành học) nếu có
        if (subject) {
          console.log(`🔍 Determining subject ID from subject: "${subject}"`);
          subjectId = await this.determineSubjectFromTargetGoal(subject);
          if (subjectId) {
            console.log(`✅ Found subject ID: ${subjectId}`);
          } else {
            console.log(`⚠️  Could not determine subject ID from subject: "${subject}"`);
          }
        }
        
        // Fallback: Nếu không có subject, thử từ targetGoal
        if (!subjectId && targetGoal) {
          console.log(`🔍 Fallback: Determining subject from targetGoal: "${targetGoal}"`);
          subjectId = await this.determineSubjectFromTargetGoal(targetGoal);
          if (subjectId) {
            console.log(`✅ Found subject ID from targetGoal: ${subjectId}`);
          } else {
            console.log(`⚠️  Could not determine subject from targetGoal: "${targetGoal}"`);
          }
        }
        
        if (!subjectId) {
          console.log(`⚠️  No subject found, will generate questions from subject/targetGoal`);
        }
      } catch (error) {
        console.error('❌ Error determining subject from onboarding:', error);
        // Continue without subjectId
      }
    }

    // ✅ Progressive Generation Strategy:
    // 1. Generate first question immediately
    // 2. Create test with first question
    // 3. Return immediately so user can start
    // 4. Generate remaining 9 questions in background
    
    const TOTAL_QUESTIONS = 10;
    let firstQuestion: Question | null = null;
    let subjectName: string | undefined;
    
    // Determine subjectName for background generation
    if (!subjectId) {
      try {
        const user = await this.usersService.findById(userId);
        const onboardingData = user?.onboardingData || {};
        subjectName = onboardingData.subject;
        if (!subjectName && onboardingData.targetGoal) {
          subjectName = this.extractSubjectFromTargetGoal(onboardingData.targetGoal);
        }
      } catch (error) {
        console.error('❌ Error getting user data:', error);
      }
    }
    
    // Try to get first question from existing questions (only 1 question, not all 10)
    try {
      if (subjectName) {
        // Try to find one existing question with this subject
        const allNullSubjectQuestions = await this.questionRepository.find({
          where: { subjectId: null },
          take: 20,
          order: { createdAt: 'DESC' },
        });
        
        const subjectQuestions = allNullSubjectQuestions.filter(q => {
          const metadata = q.metadata as any;
          const qSubject = (metadata?.subject || metadata?.targetGoal || '').toLowerCase();
          const userSubject = subjectName.toLowerCase();
          if (!qSubject) return false;
          return qSubject.includes(userSubject) || userSubject.includes(qSubject);
        });
        
        if (subjectQuestions.length > 0) {
          firstQuestion = subjectQuestions[0];
          console.log(`✅ Found existing first question for subject: ${subjectName}`);
        }
      } else if (subjectId) {
        // Try to get one question from DB
        const dbQuestions = await this.getQuestionsForTest(subjectId, 1);
        if (dbQuestions.length > 0) {
          firstQuestion = dbQuestions[0];
          console.log(`✅ Found existing first question for subjectId: ${subjectId}`);
        }
      }
    } catch (error) {
      console.error('❌ Error finding existing question:', error);
    }
    
    // If no existing question, generate first one immediately
    if (!firstQuestion) {
      // Generate first question immediately
      console.log(`🚀 Generating first question immediately...`);
      try {
        if (subjectName) {
          const generated = await this.generateQuestionsFromTargetGoal(subjectName, 1);
          if (generated.length > 0) {
            firstQuestion = generated[0];
            console.log(`✅ Generated first question about ${subjectName}`);
          }
        } else if (subjectId) {
          const subject = await this.subjectsService.findById(subjectId);
          if (subject) {
            const generated = await this.generateQuestionsWithAI(subjectId, 1);
            if (generated.length > 0) {
              firstQuestion = generated[0];
              console.log(`✅ Generated first question for subject ${subject.name}`);
            }
          }
        } else {
          // Fallback: get one general question
          const generalQuestions = await this.getQuestionsForTest(undefined, 1);
          if (generalQuestions.length > 0) {
            firstQuestion = generalQuestions[0];
            console.log(`✅ Using general first question`);
          }
        }
      } catch (error) {
        console.error('❌ Error generating first question:', error);
      }
    }
    
    if (!firstQuestion) {
      throw new BadRequestException('Failed to generate first question. Please try again.');
    }

    // Create test with first question only
    const test = this.testRepository.create({
      userId,
      subjectId: subjectId || null,
      status: TestStatus.IN_PROGRESS,
      questions: [{
        questionId: firstQuestion.id,
        question: firstQuestion.question,
        options: firstQuestion.options,
        correctAnswer: firstQuestion.correctAnswer,
        difficulty: firstQuestion.difficulty,
      }],
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

    const savedTest = await this.testRepository.save(test);
    
    console.log(`✅ Created test with first question. Total will be ${TOTAL_QUESTIONS} questions.`);
    
    // ✅ Generate remaining questions in background (non-blocking)
    // Pass empty array since we only have first question, need to generate 9 more
    this.generateRemainingQuestionsInBackground(
      savedTest.id,
      userId,
      subjectId,
      subjectName,
      [], // No existing questions beyond first one
      TOTAL_QUESTIONS,
    ).catch(error => {
      console.error('❌ Error generating remaining questions in background:', error);
    });
    
    return savedTest;
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
    let test = await this.getCurrentTest(userId);
    if (!test) {
      throw new NotFoundException('No active test found');
    }

    const TOTAL_QUESTIONS = 10;
    const currentIndex = test.currentQuestionIndex;
    
    // Check if current question exists
    if (currentIndex >= test.questions.length) {
      // Question not ready yet, try to generate it immediately
      console.log(`⚠️  Question ${currentIndex + 1} not ready yet, generating immediately...`);
      
      try {
        const user = await this.usersService.findById(userId);
        const onboardingData = user?.onboardingData || {};
        const subjectName = onboardingData.subject;
        const subjectId = test.subjectId;
        
        let newQuestion: Question | null = null;
        if (subjectName) {
          const generated = await this.generateQuestionsFromTargetGoal(subjectName, 1);
          if (generated.length > 0) newQuestion = generated[0];
        } else if (subjectId) {
          const subject = await this.subjectsService.findById(subjectId);
          if (subject) {
            const generated = await this.generateQuestionsWithAI(subjectId, 1);
            if (generated.length > 0) newQuestion = generated[0];
          }
        }
        
        if (newQuestion) {
          // Add to test
          test.questions.push({
            questionId: newQuestion.id,
            question: newQuestion.question,
            options: newQuestion.options,
            correctAnswer: newQuestion.correctAnswer,
            difficulty: newQuestion.difficulty,
          });
          await this.testRepository.save(test);
          console.log(`✅ Generated question ${currentIndex + 1} immediately`);
        }
      } catch (error) {
        console.error('❌ Error generating question immediately:', error);
        throw new BadRequestException(`Question ${currentIndex + 1} is not ready yet. Please wait a moment.`);
      }
      
      // Reload test
      test = await this.getCurrentTest(userId);
      if (!test || currentIndex >= test.questions.length) {
        throw new BadRequestException(`Question ${currentIndex + 1} is not ready yet. Please wait a moment.`);
      }
    }

    if (currentIndex >= TOTAL_QUESTIONS) {
      throw new BadRequestException('Test already completed');
    }

    const currentQuestion = test.questions[currentIndex];
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
        current: currentIndex + 1,
        total: TOTAL_QUESTIONS, // Always show total as 10
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
    progress: { current: number; total: number };
  }> {
    const TOTAL_QUESTIONS = 10;
    let test = await this.getCurrentTest(userId);
    if (!test) {
      throw new NotFoundException('No active test found');
    }

    const currentIndex = test.currentQuestionIndex;
    
    // Ensure current question exists
    if (currentIndex >= test.questions.length) {
      // Try to generate it immediately
      try {
        const user = await this.usersService.findById(userId);
        const onboardingData = user?.onboardingData || {};
        const subjectName = onboardingData.subject;
        const subjectId = test.subjectId;
        
        let newQuestion: Question | null = null;
        if (subjectName) {
          const generated = await this.generateQuestionsFromTargetGoal(subjectName, 1);
          if (generated.length > 0) newQuestion = generated[0];
        } else if (subjectId) {
          const subject = await this.subjectsService.findById(subjectId);
          if (subject) {
            const generated = await this.generateQuestionsWithAI(subjectId, 1);
            if (generated.length > 0) newQuestion = generated[0];
          }
        }
        
        if (newQuestion) {
          test.questions.push({
            questionId: newQuestion.id,
            question: newQuestion.question,
            options: newQuestion.options,
            correctAnswer: newQuestion.correctAnswer,
            difficulty: newQuestion.difficulty,
          });
          await this.testRepository.save(test);
        }
      } catch (error) {
        console.error('❌ Error generating question:', error);
      }
      
      // Reload test
      test = await this.getCurrentTest(userId);
      if (!test || currentIndex >= test.questions.length) {
        throw new BadRequestException('Current question is not ready yet. Please wait a moment.');
      }
    }

    if (currentIndex >= test.questions.length) {
      throw new BadRequestException('Test already completed');
    }

    const currentQuestion = test.questions[currentIndex];
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

    // Check if completed (always 10 questions total)
    const completed = test.currentQuestionIndex >= TOTAL_QUESTIONS;

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

      // ✅ Cập nhật test.subjectId nếu chưa có (từ onboarding data)
      if (!test.subjectId) {
        try {
          const user = await this.usersService.findById(userId);
          const onboardingData = user?.onboardingData || {};
          const subject = onboardingData.subject; // Ngành học
          const targetGoal = onboardingData.targetGoal;
          
          let foundSubjectId: string | undefined;
          
          if (subject) {
            foundSubjectId = await this.determineSubjectFromTargetGoal(subject);
            if (foundSubjectId) {
              test.subjectId = foundSubjectId;
              console.log(`✅ Updated test.subjectId from onboarding.subject: ${foundSubjectId}`);
            } else {
              // Không tìm thấy subject, tự động tạo mới
              foundSubjectId = await this.createSubjectIfNotExists(subject);
              if (foundSubjectId) {
                test.subjectId = foundSubjectId;
                console.log(`✅ Created new subject and updated test.subjectId: ${foundSubjectId}`);
              }
            }
          } else if (targetGoal) {
            foundSubjectId = await this.determineSubjectFromTargetGoal(targetGoal);
            if (foundSubjectId) {
              test.subjectId = foundSubjectId;
              console.log(`✅ Updated test.subjectId from onboarding.targetGoal: ${foundSubjectId}`);
            } else {
              // Không tìm thấy subject, tự động tạo mới từ targetGoal
              const subjectName = this.extractSubjectFromTargetGoal(targetGoal) || targetGoal;
              foundSubjectId = await this.createSubjectIfNotExists(subjectName);
              if (foundSubjectId) {
                test.subjectId = foundSubjectId;
                console.log(`✅ Created new subject from targetGoal and updated test.subjectId: ${foundSubjectId}`);
              }
            }
          }
        } catch (error) {
          console.error(`❌ Error updating test.subjectId from onboarding:`, error);
        }
      }

      // ✅ Tự động tạo skill tree cho môn học này (nếu có subjectId)
      if (test.subjectId) {
        try {
          console.log(`🌳 Auto-generating skill tree for subjectId: ${test.subjectId}`);
          await this.skillTreeService.generateSkillTree(userId, test.subjectId);
          console.log(`✅ Skill tree generated successfully`);
        } catch (error) {
          console.error(`❌ Error auto-generating skill tree:`, error);
          // Không throw error để không làm gián đoạn flow
          // Skill tree có thể được tạo sau khi user vào skill tree screen
        }
      } else {
        console.log(`⚠️  No subjectId found in test or onboarding, skipping skill tree generation`);
      }
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
      progress: {
        current: savedTest.currentQuestionIndex + 1,
        total: TOTAL_QUESTIONS,
      },
    };

    // If not completed, get next question (or generate if not ready)
    if (!completed) {
      const nextIndex = savedTest.currentQuestionIndex;
      
      // Check if next question exists
      if (nextIndex < savedTest.questions.length) {
        const nextQuestion = savedTest.questions[nextIndex];
        const nextQuestionData = await this.questionRepository.findOne({
          where: { id: nextQuestion.questionId },
        });
        if (nextQuestionData) {
          result.nextQuestion = {
            id: nextQuestionData.id,
            question: nextQuestion.question,
            options: nextQuestion.options,
            difficulty: nextQuestion.difficulty,
          };
        }
      } else {
        // Next question not ready yet, try to generate it
        console.log(`⚠️  Next question ${nextIndex + 1} not ready, generating immediately...`);
        try {
          const user = await this.usersService.findById(userId);
          const onboardingData = user?.onboardingData || {};
          const subjectName = onboardingData.subject;
          const subjectId = savedTest.subjectId;
          
          let newQuestion: Question | null = null;
          if (subjectName) {
            const generated = await this.generateQuestionsFromTargetGoal(subjectName, 1);
            if (generated.length > 0) newQuestion = generated[0];
          } else if (subjectId) {
            const subject = await this.subjectsService.findById(subjectId);
            if (subject) {
              const generated = await this.generateQuestionsWithAI(subjectId, 1);
              if (generated.length > 0) newQuestion = generated[0];
            }
          }
          
          if (newQuestion) {
            // Add to test
            savedTest.questions.push({
              questionId: newQuestion.id,
              question: newQuestion.question,
              options: newQuestion.options,
              correctAnswer: newQuestion.correctAnswer,
              difficulty: newQuestion.difficulty,
            });
            await this.testRepository.save(savedTest);
            
            result.nextQuestion = {
              id: newQuestion.id,
              question: newQuestion.question,
              options: newQuestion.options,
              difficulty: newQuestion.difficulty,
            };
            console.log(`✅ Generated next question immediately`);
          } else {
            result.nextQuestion = null; // Will show loading in frontend
          }
        } catch (error) {
          console.error('❌ Error generating next question:', error);
          result.nextQuestion = null; // Will show loading in frontend
        }
      }
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

    // ✅ Fallback: Nếu test không có subjectId, thử lấy từ user's onboarding data
    if (!test.subjectId) {
      try {
        const user = await this.usersService.findById(userId);
        const onboardingData = user?.onboardingData || {};
        const subject = onboardingData.subject; // Ngành học
        const targetGoal = onboardingData.targetGoal;
        
        if (subject) {
          const foundSubjectId = await this.determineSubjectFromTargetGoal(subject);
          if (foundSubjectId) {
            test.subjectId = foundSubjectId;
            await this.testRepository.save(test);
            console.log(`✅ Updated test.subjectId from onboarding.subject in getTestResult: ${foundSubjectId}`);
          }
        } else if (targetGoal) {
          const foundSubjectId = await this.determineSubjectFromTargetGoal(targetGoal);
          if (foundSubjectId) {
            test.subjectId = foundSubjectId;
            await this.testRepository.save(test);
            console.log(`✅ Updated test.subjectId from onboarding.targetGoal in getTestResult: ${foundSubjectId}`);
          }
        }
      } catch (error) {
        console.error(`❌ Error updating test.subjectId in getTestResult:`, error);
      }
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

  /**
   * Extract ngành học từ targetGoal
   * Ví dụ: "chơi bài tori no uta" → "piano"
   */
  private extractSubjectFromTargetGoal(targetGoal: string): string | undefined {
    if (!targetGoal) return undefined;
    
    const goal = targetGoal.toLowerCase();
    
    // Keyword mapping để extract ngành học
    const subjectKeywords: { keywords: string[]; subject: string }[] = [
      { keywords: ['piano', 'đàn piano'], subject: 'piano' },
      { keywords: ['guitar', 'đàn guitar'], subject: 'guitar' },
      { keywords: ['violin', 'đàn violin'], subject: 'violin' },
      { keywords: ['drum', 'trống'], subject: 'drum' },
      { keywords: ['nhạc', 'âm nhạc', 'music'], subject: 'music' },
      { keywords: ['excel', 'bảng tính'], subject: 'excel' },
      { keywords: ['python'], subject: 'python' },
      { keywords: ['javascript', 'js'], subject: 'javascript' },
      { keywords: ['java'], subject: 'java' },
      { keywords: ['web', 'website'], subject: 'web' },
      { keywords: ['vẽ', 'drawing'], subject: 'drawing' },
      { keywords: ['tiếng anh', 'english'], subject: 'english' },
    ];
    
    for (const mapping of subjectKeywords) {
      if (mapping.keywords.some(kw => goal.includes(kw))) {
        return mapping.subject;
      }
    }
    
    return undefined;
  }

  /**
   * Determine subject ID from user's targetGoal or subject name
   * Nếu không tìm thấy subject, sẽ dùng AI để generate questions trực tiếp từ subject name
   */
  private async determineSubjectFromTargetGoal(targetGoalOrSubject: string): Promise<string | undefined> {
    if (!targetGoalOrSubject) return undefined;

    const goal = targetGoalOrSubject.toLowerCase();
    console.log(`🔍 Analyzing targetGoalOrSubject: "${goal}"`);

    try {
      // Get all subjects
      const explorerSubjects = await this.subjectsService.findByTrack('explorer');
      const scholarSubjects = await this.subjectsService.findByTrack('scholar');
      const allSubjects = [...explorerSubjects, ...scholarSubjects];
      
      if (allSubjects.length === 0) {
        console.log('⚠️  No subjects found in database');
        return undefined;
      }

      // Keyword mapping - mở rộng để hỗ trợ nhiều môn học hơn
      const keywordMappings: { keywords: string[]; subjectNames: string[] }[] = [
        // Công nghệ thông tin
        {
          keywords: ['excel', 'spreadsheet', 'bảng tính'],
          subjectNames: ['excel', 'microsoft excel'],
        },
        {
          keywords: ['python', 'lập trình python', 'programming python'],
          subjectNames: ['python', 'lập trình python'],
        },
        {
          keywords: ['javascript', 'js', 'lập trình javascript'],
          subjectNames: ['javascript', 'js'],
        },
        {
          keywords: ['java', 'lập trình java'],
          subjectNames: ['java'],
        },
        {
          keywords: ['web', 'website', 'frontend', 'backend'],
          subjectNames: ['web', 'html', 'css', 'react'],
        },
        {
          keywords: ['data', 'data science', 'machine learning', 'ai'],
          subjectNames: ['data', 'machine learning', 'ai'],
        },
        {
          keywords: ['sql', 'database', 'cơ sở dữ liệu'],
          subjectNames: ['sql', 'database'],
        },
        // Âm nhạc
        {
          keywords: ['piano', 'đàn piano', 'học piano', 'chơi piano', 'pianoforte'],
          subjectNames: ['piano', 'âm nhạc', 'music', 'piano'],
        },
        {
          keywords: ['guitar', 'đàn guitar', 'học guitar', 'chơi guitar'],
          subjectNames: ['guitar', 'âm nhạc', 'music'],
        },
        {
          keywords: ['nhạc', 'âm nhạc', 'music', 'học nhạc'],
          subjectNames: ['âm nhạc', 'music'],
        },
        {
          keywords: ['violin', 'đàn violin', 'học violin'],
          subjectNames: ['violin', 'âm nhạc', 'music'],
        },
        {
          keywords: ['drum', 'trống', 'học trống'],
          subjectNames: ['drum', 'trống', 'âm nhạc'],
        },
        // Nghệ thuật
        {
          keywords: ['vẽ', 'drawing', 'hội họa', 'painting'],
          subjectNames: ['vẽ', 'drawing', 'painting', 'nghệ thuật'],
        },
        {
          keywords: ['design', 'thiết kế', 'design'],
          subjectNames: ['design', 'thiết kế'],
        },
        // Ngôn ngữ
        {
          keywords: ['tiếng anh', 'english', 'học tiếng anh'],
          subjectNames: ['tiếng anh', 'english'],
        },
        {
          keywords: ['tiếng nhật', 'japanese', 'học tiếng nhật'],
          subjectNames: ['tiếng nhật', 'japanese'],
        },
        {
          keywords: ['tiếng trung', 'chinese', 'học tiếng trung'],
          subjectNames: ['tiếng trung', 'chinese'],
        },
      ];

      // Try keyword matching
      for (const mapping of keywordMappings) {
        const hasKeyword = mapping.keywords.some(kw => goal.includes(kw));
        if (hasKeyword) {
          // Find matching subject
          for (const subjectName of mapping.subjectNames) {
            const subject = allSubjects.find(
              s => s.name.toLowerCase().includes(subjectName) ||
                   subjectName.includes(s.name.toLowerCase())
            );
            if (subject) {
              console.log(`✅ Matched subject: ${subject.name} (${subject.id})`);
              return subject.id;
            }
          }
        }
      }

      // Fallback: Try to find any subject that matches part of the goal
      for (const subject of allSubjects) {
        const subjectNameLower = subject.name.toLowerCase();
        if (goal.includes(subjectNameLower) || subjectNameLower.includes(goal)) {
          console.log(`✅ Found subject by partial match: ${subject.name} (${subject.id})`);
          return subject.id;
        }
      }

      console.log(`⚠️  No subject found for: ${targetGoalOrSubject}`);
      console.log(`💡 Will try to create subject automatically`);
      return undefined;
    } catch (error) {
      console.error('Error determining subject:', error);
      return undefined;
    }
  }

  /**
   * Tự động tạo subject nếu chưa có trong database
   */
  private async createSubjectIfNotExists(subjectName: string): Promise<string | undefined> {
    if (!subjectName) return undefined;

    try {
      // Normalize subject name
      const normalizedName = subjectName.trim();
      if (!normalizedName) return undefined;

      // Determine track: music-related subjects go to explorer, others to scholar
      const musicKeywords = ['piano', 'guitar', 'violin', 'drum', 'nhạc', 'âm nhạc', 'music'];
      const isMusic = musicKeywords.some(kw => normalizedName.toLowerCase().includes(kw));
      const track = isMusic ? 'explorer' : 'scholar';

      // Use SubjectsService to create subject
      const savedSubject = await this.subjectsService.createIfNotExists(
        normalizedName,
        `Khóa học về ${normalizedName}`,
        track,
      );

      console.log(`✅ Created/found subject "${savedSubject.name}" (${savedSubject.id}) in track "${track}"`);
      
      return savedSubject.id;
    } catch (error) {
      console.error(`❌ Error creating subject "${subjectName}":`, error);
      return undefined;
    }
  }

  /**
   * Generate remaining questions in background and update test
   * This runs asynchronously so the user can start answering immediately
   */
  private async generateRemainingQuestionsInBackground(
    testId: string,
    userId: string,
    subjectId: string | undefined,
    subjectName: string | undefined,
    existingQuestions: Question[],
    totalNeeded: number,
  ): Promise<void> {
    try {
      const currentCount = 1 + existingQuestions.length; // First question + existing
      const neededCount = totalNeeded - currentCount;
      
      if (neededCount <= 0) {
        console.log(`✅ Already have enough questions (${currentCount}/${totalNeeded}), no need to generate more`);
        return;
      }

      console.log(`🔄 Generating ${neededCount} remaining questions in background...`);
      
      let newQuestions: Question[] = [];
      
      if (subjectName) {
        // Generate from subject name
        newQuestions = await this.generateQuestionsFromTargetGoal(subjectName, neededCount);
      } else if (subjectId) {
        // Generate from subject ID
        newQuestions = await this.generateQuestionsWithAI(subjectId, neededCount);
      } else {
        // Fallback: get general questions
        newQuestions = await this.getQuestionsForTest(undefined, neededCount);
      }

      if (newQuestions.length > 0) {
        // Update test with new questions
        const test = await this.testRepository.findOne({
          where: { id: testId, userId },
        });

        if (test && test.status === TestStatus.IN_PROGRESS) {
          // Add new questions to existing questions (excluding first question which is already there)
          const newQuestionData = newQuestions.map((q) => ({
            questionId: q.id,
            question: q.question,
            options: q.options,
            correctAnswer: q.correctAnswer,
            difficulty: q.difficulty,
          }));

          // Merge: keep first question, add existing questions (if any), then add new questions
          const allQuestions = [
            test.questions[0], // First question
            ...existingQuestions.map(q => ({
              questionId: q.id,
              question: q.question,
              options: q.options,
              correctAnswer: q.correctAnswer,
              difficulty: q.difficulty,
            })),
            ...newQuestionData,
          ];

          test.questions = allQuestions.slice(0, totalNeeded); // Ensure exactly totalNeeded questions
          await this.testRepository.save(test);
          
          console.log(`✅ Updated test with ${newQuestions.length} additional questions (total: ${test.questions.length}/${totalNeeded})`);
        }
      }
    } catch (error) {
      console.error('❌ Error generating remaining questions in background:', error);
    }
  }

  /**
   * Generate questions directly from targetGoal using AI
   * Dùng khi không tìm thấy subject trong database
   */
  private async generateQuestionsFromTargetGoal(
    targetGoal: string,
    count: number,
  ): Promise<Question[]> {
    try {
      console.log(`🎯 Generating ${count} questions for targetGoal: "${targetGoal}" (parallel mode)`);
      
      const difficulties: DifficultyLevel[] = [
        DifficultyLevel.BEGINNER,
        DifficultyLevel.INTERMEDIATE,
        DifficultyLevel.ADVANCED,
      ];

      // Generate questions in parallel batches to avoid API rate limits
      const BATCH_SIZE = 5; // Generate 5 questions at a time
      const questions: Question[] = [];

      for (let batchStart = 0; batchStart < count; batchStart += BATCH_SIZE) {
        const batchEnd = Math.min(batchStart + BATCH_SIZE, count);
        const batchSize = batchEnd - batchStart;
        
        console.log(`🚀 Generating batch ${Math.floor(batchStart / BATCH_SIZE) + 1}: questions ${batchStart + 1}-${batchEnd} (${batchSize} parallel)`);

        // Create promises for this batch
        const batchPromises = Array.from({ length: batchSize }, async (_, i) => {
          const questionIndex = batchStart + i;
          const difficulty = difficulties[questionIndex % difficulties.length];
          
          try {
            console.log(`🤖 [Batch] Generating question ${questionIndex + 1}/${count} for "${targetGoal}" (${difficulty})...`);

          const aiQuestion = await this.aiService.generatePlacementQuestion(
            targetGoal,
            difficulty,
          );

          // Save to database without subjectId (null = general question for this subject)
          const question = this.questionRepository.create({
            question: aiQuestion.question,
            options: aiQuestion.options,
            correctAnswer: aiQuestion.correctAnswer,
            difficulty: difficulty,
            subjectId: null, // No subject, generated from subject name
            explanation: aiQuestion.explanation || '',
            metadata: {
              isAIGenerated: true,
              generatedAt: new Date().toISOString(),
              subject: targetGoal, // Store subject name (ngành học) for reference
              targetGoal: targetGoal, // Keep for backward compatibility
            },
          });

          const saved = await this.questionRepository.save(question);
            console.log(`✅ Saved AI-generated question ${questionIndex + 1}/${count} from targetGoal: ${saved.id}`);
            return saved;
          } catch (error) {
            console.error(`❌ Error generating question ${questionIndex + 1}:`, error);
            return null; // Return null for failed questions
          }
        });

        // Wait for all questions in this batch to complete
        const batchResults = await Promise.allSettled(batchPromises);
        
        // Collect successful questions
        batchResults.forEach((result, index) => {
          if (result.status === 'fulfilled' && result.value) {
            questions.push(result.value);
          } else {
            console.error(`❌ Failed to generate question ${batchStart + index + 1}:`, result.status === 'rejected' ? result.reason : 'Unknown error');
          }
        });

        console.log(`✅ Batch ${Math.floor(batchStart / BATCH_SIZE) + 1} completed: ${questions.length}/${count} questions generated so far`);

        // Small delay between batches to avoid rate limiting (only if not last batch)
        if (batchEnd < count) {
          await new Promise(resolve => setTimeout(resolve, 200));
        }
      }

      console.log(`✅ Completed generating ${questions.length}/${count} questions for "${targetGoal}"`);
      return questions;
    } catch (error) {
      console.error('Error in generateQuestionsFromTargetGoal:', error);
      return [];
    }
  }

  /**
   * Generate questions using AI when not available in database
   * Now uses parallel batch processing for better performance
   */
  private async generateQuestionsWithAI(
    subjectId: string,
    count: number,
  ): Promise<Question[]> {
    try {
      const subject = await this.subjectsService.findById(subjectId);
      if (!subject) {
        console.error(`Subject ${subjectId} not found`);
        return [];
      }

      console.log(`🎯 Generating ${count} questions for ${subject.name} (parallel mode)`);

      const difficulties: DifficultyLevel[] = [
        DifficultyLevel.BEGINNER,
        DifficultyLevel.INTERMEDIATE,
        DifficultyLevel.ADVANCED,
      ];

      // Generate questions in parallel batches to avoid API rate limits
      const BATCH_SIZE = 5; // Generate 5 questions at a time
      const questions: Question[] = [];

      for (let batchStart = 0; batchStart < count; batchStart += BATCH_SIZE) {
        const batchEnd = Math.min(batchStart + BATCH_SIZE, count);
        const batchSize = batchEnd - batchStart;
        
        console.log(`🚀 Generating batch ${Math.floor(batchStart / BATCH_SIZE) + 1}: questions ${batchStart + 1}-${batchEnd} (${batchSize} parallel)`);

        // Create promises for this batch
        const batchPromises = Array.from({ length: batchSize }, async (_, i) => {
          const questionIndex = batchStart + i;
          const difficulty = difficulties[questionIndex % difficulties.length];
          
          try {
            console.log(`🤖 [Batch] Generating question ${questionIndex + 1}/${count} for ${subject.name} (${difficulty})...`);

          const aiQuestion = await this.aiService.generatePlacementQuestion(
            subject.name,
            difficulty,
          );

          // Save to database
          const question = this.questionRepository.create({
            question: aiQuestion.question,
            options: aiQuestion.options,
            correctAnswer: aiQuestion.correctAnswer,
            difficulty: difficulty,
            subjectId: subjectId,
            explanation: aiQuestion.explanation || '',
            metadata: {
              isAIGenerated: true,
              generatedAt: new Date().toISOString(),
            },
          });

          const saved = await this.questionRepository.save(question);
            console.log(`✅ Saved AI-generated question ${questionIndex + 1}/${count}: ${saved.id}`);
            return saved;
          } catch (error) {
            console.error(`❌ Error generating question ${questionIndex + 1}:`, error);
            return null; // Return null for failed questions
          }
        });

        // Wait for all questions in this batch to complete
        const batchResults = await Promise.allSettled(batchPromises);
        
        // Collect successful questions
        batchResults.forEach((result, index) => {
          if (result.status === 'fulfilled' && result.value) {
            questions.push(result.value);
          } else {
            console.error(`❌ Failed to generate question ${batchStart + index + 1}:`, result.status === 'rejected' ? result.reason : 'Unknown error');
          }
        });

        console.log(`✅ Batch ${Math.floor(batchStart / BATCH_SIZE) + 1} completed: ${questions.length}/${count} questions generated so far`);

        // Small delay between batches to avoid rate limiting (only if not last batch)
        if (batchEnd < count) {
          await new Promise(resolve => setTimeout(resolve, 200));
          }
      }

      console.log(`✅ Completed generating ${questions.length}/${count} questions for ${subject.name}`);
      return questions;
    } catch (error) {
      console.error('Error in generateQuestionsWithAI:', error);
      return [];
    }
  }
}

