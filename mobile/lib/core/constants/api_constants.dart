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

  // Learning Nodes
  static String nodesBySubject(String subjectId) => '/nodes/subject/$subjectId';
  static String nodeDetail(String id) => '/nodes/$id';

  // Content Items
  static String contentByNode(String nodeId) => '/content/node/$nodeId';
  static String contentDetail(String id) => '/content/$id';
  static String contentByNodeAndDifficulty(String nodeId, String difficulty) => '/content/node/$nodeId/difficulty/$difficulty';
  static String generateContentByDifficulty(String nodeId) => '/content/node/$nodeId/generate-by-difficulty';
<<<<<<< Updated upstream
=======
  
  // Media Placeholders & Contribution
  static String generatePlaceholders(String nodeId) => '/content/node/$nodeId/generate-placeholders';
  static const String allPlaceholders = '/content/placeholders';
  static String nodePlaceholders(String nodeId) => '/content/node/$nodeId/placeholders';
  static String submitContribution(String contentId) => '/content/$contentId/contribute';
  static String approveContribution(String contentId) => '/content/$contentId/approve';
  static String rejectContribution(String contentId) => '/content/$contentId/reject';
  static String createNewContribution(String nodeId) => '/content/node/$nodeId/contribute-new';
>>>>>>> Stashed changes

  // Progress
  static String nodeProgress(String nodeId) => '/progress/node/$nodeId';
  static const String completeItem = '/progress/complete-item';
  static String completedContentItemsBySubject(String subjectId) => '/progress/subject/$subjectId/completed-items';

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

<<<<<<< Updated upstream
=======
  // Adaptive Placement Test
  static String startAdaptiveTest(String subjectId) => '/adaptive-test/start/$subjectId';
  static String submitAdaptiveAnswer(String testId) => '/adaptive-test/$testId/submit';
  static String getAdaptiveTestResult(String testId) => '/adaptive-test/$testId/result';

>>>>>>> Stashed changes

  // Skill Tree
  static const String generateSkillTree = '/skill-tree/generate';
  static const String getSkillTree = '/skill-tree';
  static String unlockNode(String nodeId) => '/skill-tree/$nodeId/unlock';
  static String completeNode(String nodeId) => '/skill-tree/$nodeId/complete';
  static const String unlockNextNode = '/skill-tree/unlock-next';
  static const String getNextUnlockableNodes = '/skill-tree/next-unlockable';

  // Onboarding
  static const String onboardingChat = '/onboarding/chat';
  static const String onboardingStatus = '/onboarding/status';
  static const String resetOnboarding = '/onboarding/reset';

  // Unlock
  static const String unlockScholar = '/unlock/scholar';
  static const String unlockTransactions = '/unlock/transactions';

  // Health
  static const String health = '/health';

  // Content Edits (Wiki-style Community Edit)
  static String submitContentEdit(String contentItemId) => '/content-edits/content/$contentItemId/submit';
  static String submitLessonEdit(String contentItemId) => '/content-edits/content/$contentItemId/lesson-edit';
  static String getContentEdits(String contentItemId) => '/content-edits/content/$contentItemId';
  static String getContentEdit(String id) => '/content-edits/$id';
  static String getEditComparison(String id) => '/content-edits/$id/comparison';
  static String approveContentEdit(String id) => '/content-edits/$id/approve';
  static String rejectContentEdit(String id) => '/content-edits/$id/reject';
  static String voteOnContentEdit(String id) => '/content-edits/$id/vote';
  static const String uploadImage = '/content-edits/upload-image';
  static const String uploadVideo = '/content-edits/upload-video';
  static const String pendingContentEdits = '/content-edits/pending/list';
  static const String allContentWithEdits = '/content-edits/admin/all-content-with-edits';
  static String removeContentEdit(String id) => '/content-edits/$id';
  static const String getMyContentEdits = '/content-edits/user/my-edits';
  
  // Edit History
  static String getHistoryForContent(String contentItemId) => '/content-edits/history/content/$contentItemId';
  static const String getHistoryForUser = '/content-edits/history/user';
  static const String getAllHistory = '/content-edits/history/all';
  
  // Content Versions
  static String getVersionsForContent(String contentItemId) => '/content-edits/content/$contentItemId/versions';
  static const String getMyVersions = '/content-edits/versions/my-versions';
  static String getMyVersionsForContent(String contentItemId) => '/content-edits/content/$contentItemId/my-versions';
  static String revertToVersion(String versionId) => '/content-edits/versions/$versionId/revert';
  static String getHistoryForEdit(String editId) => '/content-edits/history/edit/$editId';

  // Knowledge Graph
  static String getPrerequisites(String nodeId) => '/knowledge-graph/nodes/$nodeId/prerequisites';
  static String findPath(String fromNodeId, String toNodeId) => '/knowledge-graph/path/$fromNodeId/$toNodeId';
  static String recommendNext(String nodeId, {int? limit}) {
    final limitParam = limit != null ? '?limit=$limit' : '';
    return '/knowledge-graph/nodes/$nodeId/recommend-next$limitParam';
  }
  static String getRelatedNodes(String nodeId, {int? limit}) {
    final limitParam = limit != null ? '?limit=$limit' : '';
    return '/knowledge-graph/nodes/$nodeId/related$limitParam';
  }
  static String getNodeByEntity(String type, String entityId) => '/knowledge-graph/entity/$type/$entityId';
  static String getNodesByType(String type) => '/knowledge-graph/nodes/type/$type';
  
  // RAG (Semantic Search)
  static String semanticSearch(String query, {int? limit, String? types, double? minSimilarity}) {
    final params = <String>[];
    if (limit != null) params.add('limit=$limit');
    if (types != null) params.add('types=$types');
    if (minSimilarity != null) params.add('minSimilarity=$minSimilarity');
    final queryParam = 'q=${Uri.encodeComponent(query)}';
    return '/knowledge-graph/search?$queryParam${params.isNotEmpty ? '&${params.join('&')}' : ''}';
  }
  static String retrieveRelevantNodes(String query, {int? topK, String? types}) {
    final params = <String>[];
    if (topK != null) params.add('topK=$topK');
    if (types != null) params.add('types=$types');
    final queryParam = 'q=${Uri.encodeComponent(query)}';
    return '/knowledge-graph/retrieve?$queryParam${params.isNotEmpty ? '&${params.join('&')}' : ''}';
  }
  static String generateRAGContext(String query, {int? topK}) {
    final topKParam = topK != null ? '&topK=$topK' : '';
    final queryParam = 'q=${Uri.encodeComponent(query)}';
    return '/knowledge-graph/context?$queryParam$topKParam';
  }

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
<<<<<<< Updated upstream
=======

  // Quiz
  static const String generateQuiz = '/quiz/generate';
  static const String generateBossQuiz = '/quiz/boss/generate';
  static const String submitQuiz = '/quiz/submit';

  // Payment
  static const String paymentPackages = '/payment/packages';
  static const String createPayment = '/payment/create';
  static String getPayment(String paymentId) => '/payment/order/$paymentId';
  static const String paymentHistory = '/payment/history';
  static const String premiumStatus = '/payment/premium/status';
  static const String pendingPayment = '/payment/pending';
>>>>>>> Stashed changes
}

