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
  static String claimQuest(String questId) => '/quests/$questId/claim';
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

  // Roadmap
  static const String generateRoadmap = '/roadmap/generate';
  static const String getRoadmap = '/roadmap';
  static String todayLesson(String roadmapId) => '/roadmap/$roadmapId/today';
  static String completeDay(String roadmapId) => '/roadmap/$roadmapId/complete-day';

  // Onboarding
  static const String onboardingChat = '/onboarding/chat';
  static const String onboardingStatus = '/onboarding/status';
  static const String resetOnboarding = '/onboarding/reset';

  // Unlock
  static const String unlockScholar = '/unlock/scholar';
  static const String unlockTransactions = '/unlock/transactions';

  // Health
  static const String health = '/health';
}

