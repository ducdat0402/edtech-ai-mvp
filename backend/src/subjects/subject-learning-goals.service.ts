import { Injectable } from '@nestjs/common';
import { AiService } from '../ai/ai.service';
import { SubjectsService } from './subjects.service';
import { DomainsService } from '../domains/domains.service';

export interface LearningGoalsSession {
  userId: string;
  subjectId: string;
  messages: Array<{ role: string; content: string }>;
  extractedData: {
    currentLevel?: 'beginner' | 'intermediate' | 'advanced';
    interestedTopics?: string[]; // Tên các topics/concepts trong mind map mà user muốn học
    learningGoals?: string; // Mục tiêu học tập cụ thể
    preferredPace?: 'slow' | 'normal' | 'fast';
  };
  completed: boolean;
  turnCount: number;
}

@Injectable()
export class SubjectLearningGoalsService {
  private sessions: Map<string, LearningGoalsSession> = new Map();

  constructor(
    private aiService: AiService,
    private domainsService: DomainsService,
    private subjectsService: SubjectsService,
  ) {}

  private getSessionKey(userId: string, subjectId: string): string {
    return `${userId}_${subjectId}`;
  }

  private getOrCreateSession(
    userId: string,
    subjectId: string,
  ): LearningGoalsSession {
    const key = this.getSessionKey(userId, subjectId);

    if (!this.sessions.has(key)) {
      this.sessions.set(key, {
        userId,
        subjectId,
        messages: [],
        extractedData: {},
        completed: false,
        turnCount: 0,
      });
    }

    return this.sessions.get(key)!;
  }

  /**
   * Start learning goals conversation for a subject
   */
  async startConversation(
    userId: string,
    subjectId: string,
  ): Promise<{
    response: string;
    sessionId: string;
    mindMap?: any;
  }> {
    const session = this.getOrCreateSession(userId, subjectId);
    const subject = await this.subjectsService.findById(subjectId);

    if (!subject) {
      throw new Error('Subject not found');
    }

    // Get domains for this subject
    const domains = await this.domainsService.findBySubject(subjectId);
    const subjectDomains = domains.map(d => ({ name: d.name, description: d.description || '' }));

    // Build mind map structure for AI
    const mindMapStructure = {
      subject: subject.name,
      domains: subjectDomains.map((d) => ({
        name: d.name,
        description: d.description,
        concepts: [], // Will be populated if needed
      })),
    };

    // Generate initial AI message
    const initialPrompt = `Bạn là một AI tutor thân thiện. Người dùng muốn học môn "${subject.name}".

${subject.description ? `Mô tả môn học: ${subject.description}` : ''}

Mind map của môn học này có các chương/domain chính:
${subjectDomains.map((d, i) => `${i + 1}. ${d.name}: ${d.description}`).join('\n')}

Nhiệm vụ của bạn:
1. Chào hỏi người dùng một cách thân thiện
2. Hỏi về trình độ hiện tại của họ (beginner/intermediate/advanced)
3. Hỏi về phần nào trong mind map họ muốn học (có thể là một hoặc nhiều domains/concepts)
4. Hỏi về mục tiêu học tập cụ thể

Hãy bắt đầu cuộc trò chuyện một cách tự nhiên và thân thiện.`;

    const aiResponse = await this.aiService.chat([
      {
        role: 'system',
        content: initialPrompt,
      },
    ]);

    session.messages.push({
      role: 'assistant',
      content: aiResponse,
    });

    return {
      response: aiResponse,
      sessionId: this.getSessionKey(userId, subjectId),
      mindMap: mindMapStructure,
    };
  }

  /**
   * Continue conversation
   */
  async chat(
    userId: string,
    subjectId: string,
    message: string,
  ): Promise<{
    response: string;
    extractedData: any;
    completed: boolean;
    shouldSkipPlacementTest: boolean;
  }> {
    const session = this.getOrCreateSession(userId, subjectId);

    // Add user message
    session.messages.push({
      role: 'user',
      content: message,
    });

    session.turnCount++;

    // Extract data every 2-3 messages
    if (session.turnCount % 2 === 0) {
      const extracted = await this.extractLearningGoals(
        session.messages,
        subjectId,
      );
      session.extractedData = { ...session.extractedData, ...extracted };
    }

    // Generate AI response
    const subject = await this.subjectsService.findById(subjectId);
    const domains = await this.domainsService.findBySubject(subjectId);
    const subjectDomains = domains.map(d => ({ name: d.name, description: d.description || '' }));

    const contextPrompt = `Bạn đang trò chuyện với người dùng về môn học "${subject?.name}".

Mind map có các chương:
${subjectDomains.map((d, i) => `${i + 1}. ${d.name}`).join('\n')}

Thông tin đã thu thập:
- Trình độ: ${session.extractedData.currentLevel || 'chưa biết'}
- Topics quan tâm: ${session.extractedData.interestedTopics?.join(', ') || 'chưa có'}
- Mục tiêu: ${session.extractedData.learningGoals || 'chưa có'}

Tiếp tục cuộc trò chuyện để thu thập đủ thông tin.`;

    const conversationMessages = [
      {
        role: 'system',
        content: contextPrompt,
      },
      ...session.messages,
    ];

    const aiResponse = await this.aiService.chat(conversationMessages);

    session.messages.push({
      role: 'assistant',
      content: aiResponse,
    });

    // Check if conversation is complete
    const completed =
      !!session.extractedData.currentLevel &&
      (session.extractedData.interestedTopics?.length > 0 ||
        !!session.extractedData.learningGoals);

    // Skip placement test if beginner
    const shouldSkipPlacementTest =
      session.extractedData.currentLevel === 'beginner';

    return {
      response: aiResponse,
      extractedData: session.extractedData,
      completed,
      shouldSkipPlacementTest,
    };
  }

  /**
   * Extract learning goals from conversation
   */
  private async extractLearningGoals(
    messages: Array<{ role: string; content: string }>,
    subjectId: string,
  ): Promise<{
    currentLevel?: 'beginner' | 'intermediate' | 'advanced';
    interestedTopics?: string[];
    learningGoals?: string;
    preferredPace?: 'slow' | 'normal' | 'fast';
  }> {
    const prompt = `Extract learning goals information from this conversation about a subject.

Extract:
1. currentLevel: "beginner" | "intermediate" | "advanced" (based on user's self-assessment)
2. interestedTopics: Array of topic/domain names from the mind map that user wants to learn
3. learningGoals: Specific learning goals in Vietnamese
4. preferredPace: "slow" | "normal" | "fast"

Return JSON:
{
  "currentLevel": "beginner" | "intermediate" | "advanced" | null,
  "interestedTopics": ["topic1", "topic2"] | null,
  "learningGoals": "string" | null,
  "preferredPace": "slow" | "normal" | "fast" | null
}

Conversation:
${JSON.stringify(messages, null, 2)}`;

    try {
      const response = await this.aiService.chat([
        {
          role: 'user',
          content: prompt,
        },
      ]);

      // Try to parse JSON from response
      const jsonMatch = response.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        const parsed = JSON.parse(jsonMatch[0]);
        return parsed;
      }

      return {};
    } catch (error) {
      console.error('Error extracting learning goals:', error);
      return {};
    }
  }

  /**
   * Get session data
   */
  getSession(userId: string, subjectId: string): LearningGoalsSession | null {
    const key = this.getSessionKey(userId, subjectId);
    return this.sessions.get(key) || null;
  }

  /**
   * Clear session
   */
  clearSession(userId: string, subjectId: string): void {
    const key = this.getSessionKey(userId, subjectId);
    this.sessions.delete(key);
  }

  /**
   * Generate skill tree with learning goals data
   */
  async generateSkillTreeWithGoals(
    userId: string,
    subjectId: string,
  ): Promise<any> {
    const session = this.getSession(userId, subjectId);
    if (!session || !session.completed) {
      throw new Error('Learning goals session not completed');
    }

    const learningGoalsData = {
      currentLevel: session.extractedData.currentLevel,
      interestedTopics: session.extractedData.interestedTopics,
      learningGoals: session.extractedData.learningGoals,
    };

    // Return learning goals data (skill tree generation removed)
    return {
      message: 'Learning goals generated successfully',
      learningGoals: learningGoalsData,
    };
  }
}

