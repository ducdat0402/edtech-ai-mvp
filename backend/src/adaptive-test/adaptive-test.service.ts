import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  AdaptiveTest,
  AdaptiveTestStatus,
  DifficultyLevel,
  QuestionResponse,
  TopicAssessment,
} from './entities/adaptive-test.entity';
import { SubjectsService } from '../subjects/subjects.service';
import { DomainsService } from '../domains/domains.service';
import { LearningNodesService } from '../learning-nodes/learning-nodes.service';
import { AiService } from '../ai/ai.service';
import { UsersService } from '../users/users.service';
import { PersonalMindMapService } from '../personal-mind-map/personal-mind-map.service';
import { LessonTypeContentsService } from '../lesson-type-contents/lesson-type-contents.service';

// Configuration
const NODES_PER_TOPIC = 2; // Test 2-3 representative nodes per topic
const MAX_QUESTIONS_PER_TOPIC = 4; // Max questions before moving to next topic
const EARLY_STOP_CORRECT = 2; // If 2 correct in a row at medium difficulty -> topic is STRONG
const EARLY_STOP_INCORRECT = 2; // If 2 incorrect in a row at easy difficulty -> topic is WEAK
const MIN_QUESTIONS = 15;
const MAX_QUESTIONS = 30;

@Injectable()
export class AdaptiveTestService {
  constructor(
    @InjectRepository(AdaptiveTest)
    private testRepository: Repository<AdaptiveTest>,
    @Inject(forwardRef(() => SubjectsService))
    private subjectsService: SubjectsService,
    @Inject(forwardRef(() => DomainsService))
    private domainsService: DomainsService,
    @Inject(forwardRef(() => LearningNodesService))
    private nodesService: LearningNodesService,
    private aiService: AiService,
    private usersService: UsersService,
    @Inject(forwardRef(() => PersonalMindMapService))
    private personalMindMapService: PersonalMindMapService,
    private lessonTypeContentsService: LessonTypeContentsService,
  ) {}

  /**
   * Start a new adaptive placement test for a subject
   */
  async startTest(userId: string, subjectId: string): Promise<any> {
    // Check for existing in-progress test
    const existingTest = await this.testRepository.findOne({
      where: {
        userId,
        subjectId,
        status: AdaptiveTestStatus.IN_PROGRESS,
      },
    });

    if (existingTest) {
      // Mark as abandoned and create new one
      existingTest.status = AdaptiveTestStatus.ABANDONED;
      await this.testRepository.save(existingTest);
    }

    // Get subject with domains
    const subject = await this.subjectsService.findById(subjectId);
    if (!subject) {
      throw new NotFoundException('Subject not found');
    }

    // Get all domains for this subject
    const domains = await this.domainsService.findBySubject(subjectId);
    if (!domains || domains.length === 0) {
      throw new BadRequestException('Subject has no domains to test');
    }

    // Select domains to test (all of them, or sample if too many)
    const domainsToTest = domains.map((d) => d.id);

    // Get learning nodes - try domain first, fallback to subject
    const firstDomain = domains[0];
    let learningNodes = await this.nodesService.findByDomain(firstDomain.id);
    
    // If domain has no nodes, try getting nodes directly from subject
    if (!learningNodes || learningNodes.length === 0) {
      console.log(`⚠️ Domain ${firstDomain.name} has no nodes, trying subject directly...`);
      learningNodes = await this.nodesService.findBySubject(subjectId);
    }
    
    if (!learningNodes || learningNodes.length === 0) {
      // No nodes found - try to generate them
      console.log(`⚠️ No learning nodes found for subject, generating with AI...`);
      try {
        const generatedNodes = await this.nodesService.generateNodesFromRawData(
          subjectId,
          subject.name,
          subject.description,
          undefined,
          12, // Generate 12 nodes
        );
        learningNodes = generatedNodes;
        console.log(`✅ Generated ${learningNodes.length} nodes for ${subject.name}`);
      } catch (error) {
        console.error('❌ Error generating nodes:', error);
        throw new BadRequestException(
          'Môn học này chưa có nội dung. Vui lòng thử lại sau hoặc chọn phương thức Chat với AI.',
        );
      }
    }
    
    const topicsInDomain = learningNodes;

    // Sample nodes from first topic
    const sampleNodes = this.sampleNodes(topicsInDomain, NODES_PER_TOPIC);

    // Calculate estimated questions
    const estimatedQuestions = this.estimateTotalQuestions(domainsToTest.length, topicsInDomain.length);

    // Create test
    const test = this.testRepository.create({
      userId,
      subjectId,
      status: AdaptiveTestStatus.IN_PROGRESS,
      currentDomainId: firstDomain.id,
      currentTopicId: sampleNodes[0]?.id,
      currentNodeId: sampleNodes[0]?.id,
      currentDifficulty: DifficultyLevel.INTERMEDIATE, // Start at medium
      domainsToTest,
      topicsToTest: topicsInDomain.map((n) => n.id),
      nodesToTest: sampleNodes.map((n) => n.id),
      testedDomains: [],
      testedTopics: [],
      testedNodes: [],
      responses: [],
      topicAssessments: [],
      estimatedQuestions, // Store for progress tracking
      adaptiveState: {
        consecutiveCorrect: 0,
        consecutiveIncorrect: 0,
        totalCorrect: 0,
        totalAnswered: 0,
        currentTopicCorrect: 0,
        currentTopicAnswered: 0,
        difficultyHistory: [DifficultyLevel.INTERMEDIATE],
      },
      startedAt: new Date(),
    });

    const savedTest = await this.testRepository.save(test);

    // Generate first question
    const firstQuestion = await this.generateQuestion(
      savedTest,
      sampleNodes[0],
      DifficultyLevel.INTERMEDIATE,
    );

    return {
      testId: savedTest.id,
      subjectName: subject.name,
      currentQuestion: firstQuestion,
      currentDomain: firstDomain.name,
      currentTopic: sampleNodes[0]?.title || '',
      progress: {
        current: 1,
        total: this.estimateTotalQuestions(domainsToTest.length, topicsInDomain.length),
      },
      estimatedQuestions: this.estimateTotalQuestions(domainsToTest.length, topicsInDomain.length),
      adaptiveData: {
        currentDifficulty: DifficultyLevel.INTERMEDIATE,
      },
    };
  }

  /**
   * Submit answer and get next question or complete test
   */
  async submitAnswer(
    testId: string,
    userId: string,
    answer: number,
  ): Promise<any> {
    const test = await this.testRepository.findOne({
      where: { id: testId, userId },
    });

    if (!test) {
      throw new NotFoundException('Test not found');
    }

    if (test.status !== AdaptiveTestStatus.IN_PROGRESS) {
      throw new BadRequestException('Test is not in progress');
    }

    // Get current question (last generated)
    const currentResponse = test.responses.length > 0
      ? test.responses[test.responses.length - 1]
      : null;

    if (!currentResponse || currentResponse.userAnswer !== undefined) {
      // No current question or already answered
      throw new BadRequestException('No current question to answer');
    }

    // Check if user chose to skip (answer = -1)
    const isSkip = answer === -1;
    const isCorrect = !isSkip && answer === currentResponse.correctAnswer;
    
    currentResponse.userAnswer = answer;
    currentResponse.isCorrect = isSkip ? false : isCorrect;
    currentResponse.answeredAt = new Date();

    // Update adaptive state
    if (isSkip) {
      // Skip this topic entirely - mark as weak
      this.updateAdaptiveStateForSkip(test);
    } else {
      this.updateAdaptiveState(test, isCorrect);
    }

    // Save responses
    test.responses[test.responses.length - 1] = currentResponse;

    // Determine next action
    const nextAction = isSkip 
      ? await this.handleSkipTopic(test)
      : await this.determineNextAction(test, isCorrect);

    if (nextAction.completed) {
      // Test completed - calculate results
      await this.completeTest(test);

      return {
        testId: test.id,
        isCorrect,
        explanation: currentResponse.question, // Can enhance with AI explanation
        completed: true,
        result: {
          score: test.score,
          level: test.overallLevel,
          strongAreas: test.strongAreas,
          weakAreas: test.weakAreas,
        },
        progress: {
          current: test.responses.length,
          total: test.responses.length,
        },
        adaptiveData: test.adaptiveState,
      };
    }

    // Generate next question
    const nextNode = await this.nodesService.findById(nextAction.nextNodeId);
    if (!nextNode) {
      throw new BadRequestException('Next node not found');
    }

    const nextQuestion = await this.generateQuestion(
      test,
      nextNode,
      nextAction.nextDifficulty,
    );

    // Get domain and topic names
    const domain = await this.domainsService.findById(test.currentDomainId);
    const topic = await this.nodesService.findById(test.currentTopicId);

    await this.testRepository.save(test);

    return {
      testId: test.id,
      isCorrect,
      isSkipped: isSkip,
      explanation: isSkip 
        ? 'Đã bỏ qua chủ đề này. Chuyển sang chủ đề mới.' 
        : (isCorrect ? 'Chính xác!' : 'Đáp án chưa đúng.'),
      completed: false,
      nextQuestion,
      currentDomain: domain?.name || '',
      currentTopic: topic?.title || '',
      progress: {
        current: test.responses.filter(r => r.userAnswer !== undefined).length,
        total: test.estimatedQuestions,
      },
      adaptiveData: {
        currentDifficulty: test.currentDifficulty,
        totalCorrect: test.adaptiveState.totalCorrect,
        totalAnswered: test.adaptiveState.totalAnswered,
      },
    };
  }

  /**
   * Get test result
   */
  async getTestResult(testId: string, userId: string): Promise<AdaptiveTest> {
    const test = await this.testRepository.findOne({
      where: { id: testId, userId },
    });

    if (!test) {
      throw new NotFoundException('Test not found');
    }

    return test;
  }

  // ============ PRIVATE METHODS ============

  /**
   * Sample representative nodes from a list
   * Strategy: Pick from beginning, middle, and end for variety
   */
  private sampleNodes(nodes: any[], count: number): any[] {
    if (nodes.length <= count) {
      return nodes;
    }

    const sampled: any[] = [];
    const step = Math.floor(nodes.length / count);

    for (let i = 0; i < count && i * step < nodes.length; i++) {
      sampled.push(nodes[i * step]);
    }

    return sampled;
  }

  /**
   * Estimate total questions based on domains and topics
   */
  private estimateTotalQuestions(domainCount: number, topicCount: number): number {
    // Rough estimate: 2-4 questions per topic, capped
    const estimate = topicCount * 3;
    return Math.min(Math.max(estimate, MIN_QUESTIONS), MAX_QUESTIONS);
  }

  /**
   * Update adaptive state when user skips topic
   */
  private updateAdaptiveStateForSkip(test: AdaptiveTest): void {
    const state = test.adaptiveState;
    state.totalAnswered++;
    state.currentTopicAnswered++;
    // Reset streaks
    state.consecutiveCorrect = 0;
    state.consecutiveIncorrect = 0;
    test.adaptiveState = state;
  }

  /**
   * Handle skip topic - mark as weak and move to next
   */
  private async handleSkipTopic(test: AdaptiveTest): Promise<{
    completed: boolean;
    nextNodeId?: string;
    nextDifficulty?: DifficultyLevel;
    movingToNextTopic?: boolean;
    movingToNextDomain?: boolean;
  }> {
    console.log(`⏭️ User skipped topic: ${test.currentTopicId}`);

    // Record topic as WEAK (beginner level)
    this.recordTopicAssessment(test, DifficultyLevel.BEGINNER);

    // Mark current topic as tested
    if (test.currentTopicId && !test.testedTopics.includes(test.currentTopicId)) {
      test.testedTopics.push(test.currentTopicId);
    }

    // Reset topic counters
    const state = test.adaptiveState;
    state.currentTopicCorrect = 0;
    state.currentTopicAnswered = 0;
    state.consecutiveCorrect = 0;
    state.consecutiveIncorrect = 0;
    test.adaptiveState = state;

    // Find next topic
    const nextTopic = this.findNextTopic(test);
    if (!nextTopic) {
      // No more topics - try next domain
      const nextDomain = this.findNextDomain(test);
      if (!nextDomain) {
        return { completed: true };
      }

      // Move to next domain
      test.testedDomains.push(test.currentDomainId);
      test.currentDomainId = nextDomain.id;

      // Get topics for new domain
      let newTopics = await this.nodesService.findByDomain(nextDomain.id);
      if (!newTopics || newTopics.length === 0) {
        const allSubjectNodes = await this.nodesService.findBySubject(test.subjectId);
        newTopics = allSubjectNodes.filter(n => !test.testedNodes.includes(n.id));
      }
      if (!newTopics || newTopics.length === 0) {
        return { completed: true };
      }

      test.topicsToTest = newTopics.map((n) => n.id);
      const sampledNodes = this.sampleNodes(newTopics, NODES_PER_TOPIC);
      test.nodesToTest = sampledNodes.map((n) => n.id);
      test.currentTopicId = sampledNodes[0]?.id;
      test.currentNodeId = sampledNodes[0]?.id;
      test.currentDifficulty = DifficultyLevel.INTERMEDIATE;

      return {
        completed: false,
        nextNodeId: test.currentNodeId,
        nextDifficulty: DifficultyLevel.INTERMEDIATE,
        movingToNextDomain: true,
      };
    }

    // Move to next topic in same domain
    test.currentTopicId = nextTopic.id;
    const sampledNodes = this.sampleNodes([nextTopic], NODES_PER_TOPIC);
    test.nodesToTest = sampledNodes.map((n) => n.id);
    test.currentNodeId = sampledNodes[0]?.id;
    test.currentDifficulty = DifficultyLevel.INTERMEDIATE;

    return {
      completed: false,
      nextNodeId: test.currentNodeId,
      nextDifficulty: DifficultyLevel.INTERMEDIATE,
      movingToNextTopic: true,
    };
  }

  /**
   * Update adaptive state after answer
   */
  private updateAdaptiveState(test: AdaptiveTest, isCorrect: boolean): void {
    const state = test.adaptiveState;

    state.totalAnswered++;
    state.currentTopicAnswered++;

    if (isCorrect) {
      state.totalCorrect++;
      state.currentTopicCorrect++;
      state.consecutiveCorrect++;
      state.consecutiveIncorrect = 0;
    } else {
      state.consecutiveIncorrect++;
      state.consecutiveCorrect = 0;
    }

    test.adaptiveState = state;
  }

  /**
   * Determine next action based on adaptive algorithm
   */
  private async determineNextAction(
    test: AdaptiveTest,
    lastAnswerCorrect: boolean,
  ): Promise<{
    completed: boolean;
    nextNodeId?: string;
    nextDifficulty?: DifficultyLevel;
    movingToNextTopic?: boolean;
    movingToNextDomain?: boolean;
  }> {
    const state = test.adaptiveState;

    // Check if we've reached estimated questions (or absolute max)
    // Use responses.length for more accurate count (totalAnswered might drift)
    const answeredCount = test.responses.filter(r => r.userAnswer !== undefined).length;
    const targetQuestions = test.estimatedQuestions || MAX_QUESTIONS;
    
    console.log(`📊 Progress check: ${answeredCount}/${targetQuestions} answered, totalAnswered=${state.totalAnswered}`);
    
    if (answeredCount >= targetQuestions || answeredCount >= MAX_QUESTIONS) {
      console.log(`✅ Test completed: ${answeredCount}/${targetQuestions} questions answered`);
      return { completed: true };
    }

    // Check early stopping conditions for current topic
    let shouldMoveToNextTopic = false;
    let topicLevel = DifficultyLevel.INTERMEDIATE;

    // EARLY STOP: Strong on topic
    if (
      state.consecutiveCorrect >= EARLY_STOP_CORRECT &&
      test.currentDifficulty === DifficultyLevel.INTERMEDIATE
    ) {
      // Strong on this topic - move on
      shouldMoveToNextTopic = true;
      topicLevel = DifficultyLevel.ADVANCED;
      console.log(`✅ Early stop: Strong on topic (${state.consecutiveCorrect} correct at medium)`);
    }

    // EARLY STOP: Weak on topic
    if (
      state.consecutiveIncorrect >= EARLY_STOP_INCORRECT &&
      test.currentDifficulty === DifficultyLevel.BEGINNER
    ) {
      // Weak on this topic - move on
      shouldMoveToNextTopic = true;
      topicLevel = DifficultyLevel.BEGINNER;
      console.log(`⚠️ Early stop: Weak on topic (${state.consecutiveIncorrect} incorrect at easy)`);
    }

    // Max questions per topic
    if (state.currentTopicAnswered >= MAX_QUESTIONS_PER_TOPIC) {
      shouldMoveToNextTopic = true;
      topicLevel = this.calculateTopicLevel(state.currentTopicCorrect, state.currentTopicAnswered);
      console.log(`📊 Max questions reached for topic`);
    }

    // If moving to next topic
    if (shouldMoveToNextTopic) {
      // Record topic assessment
      this.recordTopicAssessment(test, topicLevel);

      // Mark current topic as tested
      if (test.currentTopicId && !test.testedTopics.includes(test.currentTopicId)) {
        test.testedTopics.push(test.currentTopicId);
      }

      // Reset topic counters
      state.currentTopicCorrect = 0;
      state.currentTopicAnswered = 0;
      state.consecutiveCorrect = 0;
      state.consecutiveIncorrect = 0;

      // Find next topic
      const nextTopic = this.findNextTopic(test);
      if (!nextTopic) {
        // No more topics in current domain - try next domain
        const nextDomain = this.findNextDomain(test);
        if (!nextDomain) {
          // No more domains - test complete
          return { completed: true };
        }

        // Mark domain as tested
        test.testedDomains.push(test.currentDomainId);
        test.currentDomainId = nextDomain.id;

        // Get topics for new domain, fallback to subject if empty
        let newTopics = await this.nodesService.findByDomain(nextDomain.id);
        if (!newTopics || newTopics.length === 0) {
          // Try getting all remaining nodes from subject
          const allSubjectNodes = await this.nodesService.findBySubject(test.subjectId);
          newTopics = allSubjectNodes.filter(n => !test.testedNodes.includes(n.id));
        }
        if (!newTopics || newTopics.length === 0) {
          return { completed: true };
        }

        test.topicsToTest = newTopics.map((n) => n.id);
        const sampledNodes = this.sampleNodes(newTopics, NODES_PER_TOPIC);
        test.nodesToTest = sampledNodes.map((n) => n.id);
        test.currentTopicId = sampledNodes[0]?.id;
        test.currentNodeId = sampledNodes[0]?.id;
        test.currentDifficulty = DifficultyLevel.INTERMEDIATE;

        return {
          completed: false,
          nextNodeId: test.currentNodeId,
          nextDifficulty: DifficultyLevel.INTERMEDIATE,
          movingToNextDomain: true,
        };
      }

      // Move to next topic in same domain
      test.currentTopicId = nextTopic.id;
      const sampledNodes = this.sampleNodes([nextTopic], NODES_PER_TOPIC);
      test.nodesToTest = sampledNodes.map((n) => n.id);
      test.currentNodeId = sampledNodes[0]?.id;
      test.currentDifficulty = DifficultyLevel.INTERMEDIATE;

      return {
        completed: false,
        nextNodeId: test.currentNodeId,
        nextDifficulty: DifficultyLevel.INTERMEDIATE,
        movingToNextTopic: true,
      };
    }

    // Continue with current topic - adjust difficulty
    let nextDifficulty = test.currentDifficulty;

    if (lastAnswerCorrect) {
      // Correct answer - increase difficulty
      if (nextDifficulty === DifficultyLevel.BEGINNER) {
        nextDifficulty = DifficultyLevel.INTERMEDIATE;
      } else if (nextDifficulty === DifficultyLevel.INTERMEDIATE) {
        nextDifficulty = DifficultyLevel.ADVANCED;
      }
    } else {
      // Incorrect answer - decrease difficulty
      if (nextDifficulty === DifficultyLevel.ADVANCED) {
        nextDifficulty = DifficultyLevel.INTERMEDIATE;
      } else if (nextDifficulty === DifficultyLevel.INTERMEDIATE) {
        nextDifficulty = DifficultyLevel.BEGINNER;
      }
    }

    test.currentDifficulty = nextDifficulty;
    state.difficultyHistory.push(nextDifficulty);

    // Find next node to test (could be same node with different difficulty, or next node)
    const nextNodeId = this.findNextNodeInTopic(test);

    return {
      completed: false,
      nextNodeId: nextNodeId || test.currentNodeId,
      nextDifficulty,
    };
  }

  /**
   * Find next untested topic in current domain
   */
  private findNextTopic(test: AdaptiveTest): any | null {
    const untestedTopics = test.topicsToTest.filter(
      (id) => !test.testedTopics.includes(id),
    );

    if (untestedTopics.length === 0) {
      return null;
    }

    // Return first untested topic
    return { id: untestedTopics[0] };
  }

  /**
   * Find next untested domain
   */
  private findNextDomain(test: AdaptiveTest): any | null {
    const untestedDomains = test.domainsToTest.filter(
      (id) => !test.testedDomains.includes(id) && id !== test.currentDomainId,
    );

    if (untestedDomains.length === 0) {
      return null;
    }

    return { id: untestedDomains[0] };
  }

  /**
   * Find next node to test in current topic
   */
  private findNextNodeInTopic(test: AdaptiveTest): string | null {
    const untestedNodes = test.nodesToTest.filter(
      (id) => !test.testedNodes.includes(id),
    );

    if (untestedNodes.length === 0) {
      // All nodes tested - use current node with different difficulty
      return test.currentNodeId;
    }

    // Move to next node
    const nextNodeId = untestedNodes[0];
    test.currentNodeId = nextNodeId;
    test.testedNodes.push(nextNodeId);

    return nextNodeId;
  }

  /**
   * Calculate topic level based on performance
   */
  private calculateTopicLevel(correct: number, total: number): DifficultyLevel {
    if (total === 0) return DifficultyLevel.BEGINNER;
    const percentage = (correct / total) * 100;

    if (percentage >= 80) return DifficultyLevel.ADVANCED;
    if (percentage >= 50) return DifficultyLevel.INTERMEDIATE;
    return DifficultyLevel.BEGINNER;
  }

  /**
   * Record assessment for current topic
   */
  private recordTopicAssessment(test: AdaptiveTest, level: DifficultyLevel): void {
    const state = test.adaptiveState;
    const score =
      state.currentTopicAnswered > 0
        ? Math.round((state.currentTopicCorrect / state.currentTopicAnswered) * 100)
        : 0;

    // Get responses for this topic
    const topicResponses = test.responses.filter(
      (r) => r.topicId === test.currentTopicId,
    );

    const assessment: TopicAssessment = {
      topicId: test.currentTopicId,
      topicName: '', // Will be filled from node
      domainId: test.currentDomainId,
      domainName: '', // Will be filled from domain
      nodesTested: topicResponses.map((r) => r.nodeId),
      nodesCorrect: topicResponses.filter((r) => r.isCorrect).map((r) => r.nodeId),
      nodesIncorrect: topicResponses.filter((r) => !r.isCorrect).map((r) => r.nodeId),
      level,
      score,
    };

    test.topicAssessments.push(assessment);
  }

  /**
   * Generate a question for a node at specific difficulty.
   * First tries to use existing endQuiz questions from LessonTypeContent,
   * then falls back to AI generation if none available.
   */
  private async generateQuestion(
    test: AdaptiveTest,
    node: any,
    difficulty: DifficultyLevel,
  ): Promise<any> {
    try {
      let question: string;
      let options: string[];
      let correctAnswer: number;

      // Collect already-used question texts so we don't repeat
      const usedQuestions = new Set(
        test.responses.map((r) => r.question),
      );

      // 1. Try to find an unused endQuiz question from LessonTypeContent
      let foundFromEndQuiz = false;
      try {
        const contents = await this.lessonTypeContentsService.getByNodeId(node.id);
        // Gather all endQuiz questions across all lesson types for this node
        const allEndQuizQuestions: Array<{
          question: string;
          options: string[];
          correctAnswer: number; // index of the correct option
        }> = [];

        // Only use text-based lesson types (skip video, image_gallery, image_quiz
        // because adaptive test UI cannot display images/videos)
        const textContents = contents.filter(
          (c) => c.lessonType === 'text',
        );

        for (const content of textContents) {
          const endQuiz = content.endQuiz as any;
          if (endQuiz?.questions && Array.isArray(endQuiz.questions)) {
            for (const q of endQuiz.questions) {
              if (q.question && q.options && q.correctAnswer != null) {
                // Convert options: [{text, explanation}] -> string[]
                const opts: string[] = Array.isArray(q.options)
                  ? q.options.map((o: any) =>
                      typeof o === 'string' ? o : o.text || String(o),
                    )
                  : [];
                if (opts.length >= 2) {
                  // correctAnswer may be a string (answer text) or number (index)
                  // Convert to index if it's a string
                  let correctIdx: number;
                  if (typeof q.correctAnswer === 'number') {
                    correctIdx = q.correctAnswer;
                  } else {
                    // Find index of the matching option text
                    correctIdx = opts.findIndex(
                      (o) => o === q.correctAnswer || o === String(q.correctAnswer),
                    );
                    if (correctIdx === -1) correctIdx = 0; // fallback to first option
                  }

                  allEndQuizQuestions.push({
                    question: q.question,
                    options: opts,
                    correctAnswer: correctIdx,
                  });
                }
              }
            }
          }
        }

        // Filter out already-used questions
        const unusedQuestions = allEndQuizQuestions.filter(
          (q) => !usedQuestions.has(q.question),
        );

        if (unusedQuestions.length > 0) {
          // Pick a random unused question
          const picked =
            unusedQuestions[Math.floor(Math.random() * unusedQuestions.length)];
          question = picked.question;
          options = picked.options;
          correctAnswer = picked.correctAnswer;
          foundFromEndQuiz = true;
        }
      } catch (err) {
        // If fetching endQuiz fails, fall through to AI generation
        console.warn('Failed to fetch endQuiz questions for node', node.id, err);
      }

      // 2. Fallback: generate question using AI
      if (!foundFromEndQuiz) {
        const aiQuestion = await this.aiService.generatePlacementQuestion(
          node.title,
          difficulty,
        );
        question = aiQuestion.question;
        options = aiQuestion.options;
        correctAnswer = Number(aiQuestion.correctAnswer);
      }

      // Create response record (without answer yet)
      const response: QuestionResponse = {
        questionId: `${test.id}-${test.responses.length}`,
        nodeId: node.id,
        topicId: test.currentTopicId,
        domainId: test.currentDomainId,
        question,
        options,
        correctAnswer,
        userAnswer: undefined,
        isCorrect: undefined,
        difficulty,
        answeredAt: undefined,
      };

      test.responses.push(response);
      await this.testRepository.save(test);

      return {
        id: response.questionId,
        question,
        options,
        difficulty,
        correctAnswer, // Include for debugging, remove in production
      };
    } catch (error) {
      console.error('Error generating question:', error);
      throw new BadRequestException('Failed to generate question');
    }
  }

  /**
   * Complete test and calculate final results
   */
  private async completeTest(test: AdaptiveTest): Promise<void> {
    test.status = AdaptiveTestStatus.COMPLETED;
    test.completedAt = new Date();

    // Calculate overall score
    const state = test.adaptiveState;
    test.score =
      state.totalAnswered > 0
        ? Math.round((state.totalCorrect / state.totalAnswered) * 100)
        : 0;

    // Determine overall level
    const avgDifficulty = this.calculateAverageDifficulty(state.difficultyHistory);
    test.overallLevel = this.determineOverallLevel(test.score, avgDifficulty);

    // Identify strong and weak areas
    const strongTopics: string[] = [];
    const weakTopics: string[] = [];

    for (const assessment of test.topicAssessments) {
      // Get topic name
      const topic = await this.nodesService.findById(assessment.topicId);
      const topicName = topic?.title || assessment.topicId;

      if (assessment.level === DifficultyLevel.ADVANCED || assessment.score >= 80) {
        strongTopics.push(topicName);
      } else if (assessment.level === DifficultyLevel.BEGINNER || assessment.score < 50) {
        weakTopics.push(topicName);
      }
    }

    test.strongAreas = strongTopics;
    test.weakAreas = weakTopics;

    // Generate recommended learning path
    test.recommendedPath = this.generateRecommendedPath(test);

    await this.testRepository.save(test);

    // Update user's placement level
    await this.usersService.updatePlacementTest(
      test.userId,
      test.score,
      test.overallLevel,
    );

    // Auto-generate personalized learning path (mind map) from test results
    try {
      await this.personalMindMapService.generateFromAdaptiveTest(
        test.userId,
        test.subjectId,
        {
          score: test.score,
          overallLevel: test.overallLevel,
          weakAreas: test.weakAreas,
          strongAreas: test.strongAreas,
          recommendedPath: test.recommendedPath,
          topicAssessments: test.topicAssessments.map(a => ({
            topicId: a.topicId,
            topicName: a.topicName,
            score: a.score,
            level: a.level,
          })),
        },
      );
      console.log('✅ Personalized learning path generated from adaptive test results');
    } catch (error) {
      console.error('Error generating personalized learning path:', error);
    }
  }

  /**
   * Calculate average difficulty from history
   */
  private calculateAverageDifficulty(history: DifficultyLevel[]): number {
    if (history.length === 0) return 1;

    const values = history.map((d) => {
      switch (d) {
        case DifficultyLevel.BEGINNER:
          return 0;
        case DifficultyLevel.INTERMEDIATE:
          return 1;
        case DifficultyLevel.ADVANCED:
          return 2;
      }
    });

    return values.reduce((a, b) => a + b, 0) / values.length;
  }

  /**
   * Determine overall level based on score and difficulty
   */
  private determineOverallLevel(
    score: number,
    avgDifficulty: number,
  ): DifficultyLevel {
    // High score at high difficulty = Advanced
    if (score >= 80 && avgDifficulty >= 1.5) {
      return DifficultyLevel.ADVANCED;
    }

    // Good score or medium difficulty = Intermediate
    if (score >= 60 || avgDifficulty >= 1) {
      return DifficultyLevel.INTERMEDIATE;
    }

    // Low score at low difficulty = Beginner
    return DifficultyLevel.BEGINNER;
  }

  /**
   * Generate recommended learning path based on assessment
   */
  private generateRecommendedPath(test: AdaptiveTest): string[] {
    // Sort topics by score (weak first)
    const sortedAssessments = [...test.topicAssessments].sort(
      (a, b) => a.score - b.score,
    );

    // Return node IDs prioritizing weak areas
    return sortedAssessments.map((a) => a.topicId);
  }
}
