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

  // Learning Nodes
  static String nodesBySubject(String subjectId) => '/nodes/subject/$subjectId';
  static String nodeDetail(String id) => '/nodes/$id';

  // Content Items
  static String contentByNode(String nodeId) => '/content/node/$nodeId';
  static String contentDetail(String id) => '/content/$id';

  // Progress
  static String nodeProgress(String nodeId) => '/progress/node/$nodeId';
  static const String completeItem = '/progress/complete-item';

  // Currency
  static const String currency = '/currency';

  // Quests
  static const String dailyQuests = '/quests/daily';
  static String claimQuest(String userQuestId) => '/quests/$userQuestId/claim';
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

  // Roadmap (Legacy - có thể giữ lại hoặc xóa sau)
  static const String generateRoadmap = '/roadmap/generate';
  static const String getRoadmap = '/roadmap';
  static String todayLesson(String roadmapId) => '/roadmap/$roadmapId/today';
  static String completeDay(String roadmapId) => '/roadmap/$roadmapId/complete-day';

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
  static String getContentEdits(String contentItemId) => '/content-edits/content/$contentItemId';
  static String getContentEdit(String id) => '/content-edits/$id';
  static String approveContentEdit(String id) => '/content-edits/$id/approve';
  static String rejectContentEdit(String id) => '/content-edits/$id/reject';
  static String voteOnContentEdit(String id) => '/content-edits/$id/vote';
  static const String uploadImage = '/content-edits/upload-image';
  static const String uploadVideo = '/content-edits/upload-video';
  static const String pendingContentEdits = '/content-edits/pending/list';
  static const String allContentWithEdits = '/content-edits/admin/all-content-with-edits';
  static String removeContentEdit(String id) => '/content-edits/$id';
}

