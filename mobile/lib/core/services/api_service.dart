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

  Future<Map<String, dynamic>> getSubjectIntro(String subjectId) async {
    final response = await _apiClient.get(ApiConstants.subjectIntro(subjectId));
    return response.data;
  }

  Future<List<dynamic>> getSubjectNodes(String subjectId) async {
    final response = await _apiClient.get(ApiConstants.subjectNodes(subjectId));
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> getNodeDetail(String nodeId) async {
    final response = await _apiClient.get(ApiConstants.nodeDetail(nodeId));
    return response.data;
  }

  Future<List<dynamic>> getContentByNode(String nodeId) async {
    final response = await _apiClient.get(ApiConstants.contentByNode(nodeId));
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> getContentDetail(String contentId) async {
    final response =
        await _apiClient.get(ApiConstants.contentDetail(contentId));
    return response.data;
  }

  // Currency
  Future<Map<String, dynamic>> getCurrency() async {
    final response = await _apiClient.get(ApiConstants.currency);
    return response.data;
  }

  // Daily Quests
  Future<List<dynamic>> getDailyQuests() async {
    final response = await _apiClient.get(ApiConstants.dailyQuests);
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> claimQuest(String userQuestId) async {
    final response =
        await _apiClient.post(ApiConstants.claimQuest(userQuestId));
    return response.data;
  }

  Future<List<dynamic>> getQuestHistory() async {
    final response = await _apiClient.get(ApiConstants.questHistory);
    return List<Map<String, dynamic>>.from(response.data);
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

  Future<Map<String, dynamic>> getSubjectLeaderboard(
    String subjectId, {
    int limit = 100,
    int page = 1,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.subjectLeaderboard(subjectId),
      queryParameters: {'limit': limit, 'page': page},
    );
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

  Future<Map<String, dynamic>?> getRoadmap({String? subjectId}) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.getRoadmap,
        queryParameters: subjectId != null ? {'subjectId': subjectId} : null,
      );

      // Handle null or empty response (no roadmap exists)
      if (response.data == null ||
          (response.data is String && (response.data as String).isEmpty)) {
        return null;
      }

      // Handle empty string response
      if (response.data is String) {
        final dataStr = response.data as String;
        if (dataStr.isEmpty || dataStr.trim().isEmpty) {
          return null;
        }
        // If it's a non-empty string, might be error message
        throw Exception(dataStr);
      }

      // Handle Map response
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }

      // Unknown type
      return null;
    } catch (e) {
      // If 404 or no roadmap, return null instead of throwing
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('404') ||
          errorStr.contains('not found') ||
          errorStr.contains('null')) {
        return null;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getTodayLesson(String roadmapId) async {
    try {
      final response =
          await _apiClient.get(ApiConstants.todayLesson(roadmapId));
      // Handle null response
      if (response.data == null) {
        return null;
      }
      // Handle string response (error message)
      if (response.data is String) {
        throw Exception(response.data as String);
      }
      // Return Map
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      // If 404 or not found, return null instead of throwing
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        return null;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> completeDay(
      String roadmapId, int dayNumber) async {
    final response = await _apiClient.post(
      ApiConstants.completeDay(roadmapId),
      data: {'dayNumber': dayNumber},
    );
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
    int? score,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.completeItem,
      data: {
        'nodeId': nodeId,
        'contentItemId': contentItemId,
        'itemType': itemType,
        if (score != null) 'score': score,
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

  Future<Map<String, dynamic>> resetOnboarding({String? sessionId}) async {
    final response = await _apiClient.post(
      ApiConstants.resetOnboarding,
      data: sessionId != null ? {'sessionId': sessionId} : {},
    );
    return response.data;
  }

  // Placement Test Analysis
  Future<Map<String, dynamic>> getTestAnalysis(String testId) async {
    final response = await _apiClient.get(
      ApiConstants.testResult(testId),
    );
    return response.data;
  }

  // User Profile
  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await _apiClient.get(ApiConstants.me);
    return response.data;
  }

  // Skill Tree
  Future<Map<String, dynamic>> generateSkillTree(String subjectId) async {
    final response = await _apiClient.post(
      ApiConstants.generateSkillTree,
      data: {'subjectId': subjectId},
    );
    return response.data;
  }

  Future<Map<String, dynamic>?> getSkillTree({String? subjectId}) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.getSkillTree,
        queryParameters: subjectId != null ? {'subjectId': subjectId} : null,
      );

      // Handle null or empty response
      if (response.data == null ||
          (response.data is String && (response.data as String).isEmpty)) {
        return null;
      }

      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }

      return null;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('404') || errorStr.contains('not found')) {
        return null;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> unlockSkillNode(String nodeId) async {
    final response = await _apiClient.post(ApiConstants.unlockNode(nodeId));
    return response.data;
  }

  Future<Map<String, dynamic>> completeSkillNode(String nodeId,
      {Map<String, dynamic>? progressData}) async {
    final response = await _apiClient.post(
      ApiConstants.completeNode(nodeId),
      data: progressData != null ? {'progressData': progressData} : null,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> unlockNextSkillNode(String subjectId) async {
    final response = await _apiClient.post(
      ApiConstants.unlockNextNode,
      data: {'subjectId': subjectId},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getNextUnlockableNodes(String subjectId) async {
    final response = await _apiClient.get(
      ApiConstants.getNextUnlockableNodes,
      queryParameters: {'subjectId': subjectId},
    );
    return response.data;
  }

  // Content Edits (Wiki-style Community Edit)
  Future<Map<String, dynamic>> submitContentEdit({
    required String contentItemId,
    required String type, // 'add_video', 'add_image', 'add_text', 'update_content'
    String? videoUrl,
    String? imageUrl,
    String? textContent,
    String? description,
    String? caption,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.submitContentEdit(contentItemId),
      data: {
        'type': type,
        if (videoUrl != null) 'videoUrl': videoUrl,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (textContent != null) 'textContent': textContent,
        if (description != null) 'description': description,
        if (caption != null) 'caption': caption,
      },
    );
    return response.data;
  }

  Future<List<dynamic>> getContentEdits(String contentItemId) async {
    final response = await _apiClient.get(
      ApiConstants.getContentEdits(contentItemId),
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> uploadImageForEdit(String imagePath) async {
    final response = await _apiClient.postFile(
      ApiConstants.uploadImage,
      fileKey: 'image',
      filePath: imagePath,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> uploadVideoForEdit(String videoPath) async {
    final response = await _apiClient.postFile(
      ApiConstants.uploadVideo,
      fileKey: 'video',
      filePath: videoPath,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> voteOnContentEdit(
    String editId, {
    required bool isUpvote,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.voteOnContentEdit(editId),
      data: {'isUpvote': isUpvote},
    );
    return response.data;
  }

  // Admin endpoints
  Future<List<dynamic>> getPendingContentEdits() async {
    final response = await _apiClient.get(ApiConstants.pendingContentEdits);
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> approveContentEdit(String editId) async {
    final response = await _apiClient.put(ApiConstants.approveContentEdit(editId));
    return response.data;
  }

  Future<Map<String, dynamic>> rejectContentEdit(String editId) async {
    final response = await _apiClient.put(ApiConstants.rejectContentEdit(editId));
    return response.data;
  }

  Future<Map<String, dynamic>> removeContentEdit(String editId) async {
    final response = await _apiClient.delete(ApiConstants.removeContentEdit(editId));
    return response.data;
  }

  Future<List<dynamic>> getAllContentItemsWithEdits() async {
    final response = await _apiClient.get(ApiConstants.allContentWithEdits);
    return List<Map<String, dynamic>>.from(response.data);
  }
}
