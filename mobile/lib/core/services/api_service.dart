import 'package:edtech_mobile/core/api/api_client.dart';
import 'package:edtech_mobile/core/constants/api_constants.dart';

class ApiService {
  final ApiClient _apiClient;

  ApiService(this._apiClient);

  // Dashboard
  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _apiClient.get(ApiConstants.dashboard);
    return response.data;
  }

  // Subjects
  Future<List<dynamic>> getExplorerSubjects() async {
    final response = await _apiClient.get(ApiConstants.explorerSubjects);
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<dynamic>> getScholarSubjects() async {
    final response = await _apiClient.get(ApiConstants.scholarSubjects);
    return List<Map<String, dynamic>>.from(response.data);
  }

  // Currency
  Future<Map<String, dynamic>> getCurrency() async {
    final response = await _apiClient.get(ApiConstants.currency);
    return response.data;
  }

  // Daily Quests
  Future<Map<String, dynamic>> getDailyQuests() async {
    final response = await _apiClient.get(ApiConstants.dailyQuests);
    return response.data;
  }

  // Leaderboard
  Future<Map<String, dynamic>> getGlobalLeaderboard(
      {int limit = 100, int page = 1}) async {
    final response = await _apiClient.get(
      ApiConstants.globalLeaderboard,
      queryParameters: {'limit': limit, 'page': page},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getWeeklyLeaderboard(
      {int limit = 100, int page = 1}) async {
    final response = await _apiClient.get(
      ApiConstants.weeklyLeaderboard,
      queryParameters: {'limit': limit, 'page': page},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getMyRank() async {
    final response = await _apiClient.get(ApiConstants.myRank);
    return response.data;
  }

  // Placement Test
  Future<Map<String, dynamic>> startPlacementTest({String? subjectId}) async {
    final response = await _apiClient.post(
      ApiConstants.startTest,
      data: subjectId != null ? {'subjectId': subjectId} : {},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getCurrentTest() async {
    final response = await _apiClient.get(ApiConstants.currentTest);
    return response.data;
  }

  Future<Map<String, dynamic>> submitAnswer(int answer) async {
    final response = await _apiClient.post(
      ApiConstants.submitAnswer,
      data: {'answer': answer},
    );
    return response.data;
  }

  // Roadmap
  Future<Map<String, dynamic>> generateRoadmap(String subjectId) async {
    final response = await _apiClient.post(
      ApiConstants.generateRoadmap,
      data: {'subjectId': subjectId},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getTodayLesson(String roadmapId) async {
    final response = await _apiClient.get(ApiConstants.todayLesson(roadmapId));
    return response.data;
  }

  // Progress
  Future<Map<String, dynamic>> getNodeProgress(String nodeId) async {
    final response = await _apiClient.get(ApiConstants.nodeProgress(nodeId));
    return response.data;
  }

  Future<Map<String, dynamic>> completeContentItem({
    required String nodeId,
    required String contentItemId,
    required String itemType,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.completeItem,
      data: {
        'nodeId': nodeId,
        'contentItemId': contentItemId,
        'itemType': itemType,
      },
    );
    return response.data;
  }

  // Onboarding
  Future<Map<String, dynamic>> onboardingChat({
    required String message,
    String? sessionId,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.onboardingChat,
      data: {
        'message': message,
        if (sessionId != null) 'sessionId': sessionId,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getOnboardingStatus({String? sessionId}) async {
    final response = await _apiClient.get(
      ApiConstants.onboardingStatus,
      queryParameters: sessionId != null ? {'sessionId': sessionId} : null,
    );
    return response.data;
  }
}
