import '../config/api_config.dart';

class ApiConstants {
  // Base URL - Change in api_config.dart
  static const String baseUrl = ApiConfig.baseUrl;

  // Auth Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String verify = '/auth/verify';
  static const String me = '/auth/me';

  // Dashboard
  static const String dashboard = '/dashboard';

  // Subjects
  static const String explorerSubjects = '/subjects/explorer';
  static const String scholarSubjects = '/subjects/scholar';
  static String subjectDetail(String id) => '/subjects/$id';
  static String subjectNodes(String id) => '/subjects/$id/nodes';
  static String subjectIntro(String id) => '/subjects/$id/intro';
  static String startLearningGoals(String subjectId) => '/subjects/$subjectId/learning-goals/start';
  static String chatLearningGoals(String subjectId) => '/subjects/$subjectId/learning-goals/chat';
  static String getLearningGoalsSession(String subjectId) => '/subjects/$subjectId/learning-goals/session';
  static String generateSkillTreeWithGoals(String subjectId) => '/subjects/$subjectId/learning-goals/generate-skill-tree';
  static String generateLearningNodesFromTopic(String subjectId, String topicNodeId) => '/subjects/$subjectId/mind-map/$topicNodeId/generate-learning-nodes';
  static String getGenerationProgress(String subjectId, String taskId) => '/subjects/$subjectId/generation-progress/$taskId';
  
  // Domains
  static String domainsBySubject(String subjectId) => '/domains/subject/$subjectId';
  static String domainDetail(String id) => '/domains/$id';

  // Topics
  static String topicsByDomain(String domainId) => '/topics/domain/$domainId';
  static String topicDetail(String id) => '/topics/$id';

  // Learning Nodes
  static String nodesBySubject(String subjectId) => '/nodes/subject/$subjectId';
  static String nodesByTopic(String topicId) => '/nodes/topic/$topicId';
  static String nodeDetail(String id) => '/nodes/$id';

  // Progress
  static String nodeProgress(String nodeId) => '/progress/node/$nodeId';
  static const String completeNode = '/progress/complete-node';

  // Currency
  static const String currency = '/currency';
  static String rewardsHistory({int? limit, int? offset, String? source}) {
    final params = <String>[];
    if (limit != null) params.add('limit=$limit');
    if (offset != null) params.add('offset=$offset');
    if (source != null) params.add('source=$source');
    return '/currency/history${params.isNotEmpty ? '?${params.join('&')}' : ''}';
  }

  // Achievements
  static const String achievements = '/achievements';
  static const String userAchievements = '/achievements/user';
  static const String checkAchievements = '/achievements/check';
  static String claimAchievementRewards(String userAchievementId) => '/achievements/$userAchievementId/claim-rewards';

  // Quests
  static const String dailyQuests = '/quests/daily';
  static String claimQuest(String userQuestId) => '/quests/claim/$userQuestId';
  static const String questHistory = '/quests/history';

  // Leaderboard
  static const String globalLeaderboard = '/leaderboard/global';
  static const String weeklyLeaderboard = '/leaderboard/weekly';
  static String subjectLeaderboard(String subjectId) => '/leaderboard/subject/$subjectId';
  static const String myRank = '/leaderboard/me';

  // Placement Test
  static const String startTest = '/test/start';
  static const String currentTest = '/test/current';
  static const String submitAnswer = '/test/submit';
  static String testResult(String testId) => '/test/result/$testId';

  // Adaptive Placement Test
  static String startAdaptiveTest(String subjectId) => '/adaptive-test/start/$subjectId';
  static String submitAdaptiveAnswer(String testId) => '/adaptive-test/$testId/submit';
  static String getAdaptiveTestResult(String testId) => '/adaptive-test/$testId/result';

  // Onboarding
  static const String onboardingChat = '/onboarding/chat';
  static const String onboardingStatus = '/onboarding/status';
  static const String resetOnboarding = '/onboarding/reset';

  // Unlock (Diamond-based)
  static String unlockPricing(String subjectId) => '/unlock/pricing/$subjectId';
  static const String unlockSubject = '/unlock/subject';
  static const String unlockDomain = '/unlock/domain';
  static const String unlockTopic = '/unlock/topic';
  static String checkNodeAccess(String nodeId) => '/unlock/check-access/$nodeId';
  static const String myUnlocks = '/unlock/my-unlocks';
  static const String unlockTransactions = '/unlock/transactions';

  // Health
  static const String health = '/health';

  // Uploads
  static const String uploadImage = '/uploads/image';
  static const String uploadVideo = '/uploads/video';

  // Lesson Content (4 lesson types)
  static String getLessonData(String nodeId) => '/nodes/$nodeId/lesson';
  static String getLessonDataByType(String nodeId, String lessonType) => '/nodes/$nodeId/lesson/$lessonType';
  static String updateLessonContent(String nodeId) => '/nodes/$nodeId/lesson-content';
  static String generateEndQuiz(String nodeId) => '/nodes/$nodeId/end-quiz/generate';
  static const String generateExample = '/nodes/generate-example';
  static const String generateQuizExplanations = '/nodes/generate-quiz-explanations';
  static String submitEndQuiz(String nodeId) => '/nodes/$nodeId/submit-quiz';
  static String submitEndQuizForType(String nodeId, String lessonType) => '/nodes/$nodeId/submit-quiz/$lessonType';

  // Lesson Type Contents
  static String lessonTypeContentsByNode(String nodeId) => '/lesson-type-contents/node/$nodeId';
  static String lessonTypeContentByType(String nodeId, String lessonType) => '/lesson-type-contents/node/$nodeId/$lessonType';
  static String lessonTypeHistory(String nodeId, String lessonType) => '/lesson-type-contents/node/$nodeId/$lessonType/history';
  static String lessonTypeVersionDetail(String versionId) => '/lesson-type-contents/history/$versionId';

  // Lesson Content Edit (via contributions)
  static const String createLessonContentEdit = '/pending-contributions/lesson-content-edit';

  // Progress - Lesson Types, Topics, Domains
  static const String completeLessonType = '/progress/complete-lesson-type';
  static String lessonTypeProgress(String nodeId) => '/progress/lesson/$nodeId/types';
  static String topicProgress(String topicId) => '/progress/topic/$topicId';
  static String domainProgress(String domainId) => '/progress/domain/$domainId';

  // Personal Mind Map
  static String checkPersonalMindMap(String subjectId) => '/personal-mind-map/check/$subjectId';
  static String getPersonalMindMap(String subjectId) => '/personal-mind-map/$subjectId';
  static String createPersonalMindMap(String subjectId) => '/personal-mind-map/$subjectId';
  static String updatePersonalMindMapNode(String subjectId, String nodeId) => '/personal-mind-map/$subjectId/nodes/$nodeId';
  static String deletePersonalMindMap(String subjectId) => '/personal-mind-map/$subjectId';
  
  // Personal Mind Map - Chat riêng cho từng môn học
  static String startPersonalMindMapChat(String subjectId) => '/personal-mind-map/$subjectId/chat/start';
  static String personalMindMapChat(String subjectId) => '/personal-mind-map/$subjectId/chat';
  static String getPersonalMindMapChatSession(String subjectId) => '/personal-mind-map/$subjectId/chat/session';
  static String generatePersonalMindMapFromChat(String subjectId) => '/personal-mind-map/$subjectId/chat/generate';
  static String resetPersonalMindMapChat(String subjectId) => '/personal-mind-map/$subjectId/chat/reset';

  // User Role
  static const String switchRole = '/users/switch-role';

  // Pending Contributions (Contributor mode)
  static const String myPendingContributions = '/pending-contributions/my';
  static const String adminPendingContributions = '/pending-contributions/admin/pending';
  static const String createSubjectContribution = '/pending-contributions/subject';
  static const String createDomainContribution = '/pending-contributions/domain';
  static const String createTopicContribution = '/pending-contributions/topic';
  static const String createLessonContribution = '/pending-contributions/lesson';
  static const String createEditContribution = '/pending-contributions/edit';
  static const String createDeleteContribution = '/pending-contributions/delete';
  static String pendingContributionDetail(String id) => '/pending-contributions/$id';
  static String approvePendingContribution(String id) => '/pending-contributions/$id/approve';
  static String rejectPendingContribution(String id) => '/pending-contributions/$id/reject';

  // Payment (Diamond purchase)
  static const String paymentPackages = '/payment/packages';
  static const String createPayment = '/payment/create';
  static String getPayment(String paymentId) => '/payment/order/$paymentId';
  static const String paymentHistory = '/payment/history';
  static const String diamondBalance = '/payment/diamond-balance';
  static const String pendingPayment = '/payment/pending';
}
