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

  /// Get all learning nodes for a subject (includes all nodes, not just unlocked)
  Future<List<dynamic>> getLearningNodesBySubject(String subjectId) async {
    final response = await _apiClient.get(ApiConstants.nodesBySubject(subjectId));
    return List<Map<String, dynamic>>.from(response.data);
  }

  // Subject Learning Goals
  Future<Map<String, dynamic>> startLearningGoals(String subjectId) async {
    final response =
        await _apiClient.post(ApiConstants.startLearningGoals(subjectId));
    return response.data;
  }

  Future<Map<String, dynamic>> chatLearningGoals(
      String subjectId, String message) async {
    final response = await _apiClient.post(
      ApiConstants.chatLearningGoals(subjectId),
      data: {'message': message},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getLearningGoalsSession(String subjectId) async {
    final response =
        await _apiClient.get(ApiConstants.getLearningGoalsSession(subjectId));
    return response.data;
  }

  Future<Map<String, dynamic>> generateSkillTreeWithGoals(
      String subjectId) async {
    final response = await _apiClient
        .post(ApiConstants.generateSkillTreeWithGoals(subjectId));
    return response.data;
  }

  Future<Map<String, dynamic>> generateLearningNodesFromTopic(
      String subjectId, String topicNodeId) async {
    final response = await _apiClient.post(
        ApiConstants.generateLearningNodesFromTopic(subjectId, topicNodeId));
    return response.data;
  }

  Future<Map<String, dynamic>> getGenerationProgress(
      String subjectId, String taskId) async {
    final response = await _apiClient
        .get(ApiConstants.getGenerationProgress(subjectId, taskId));
    return response.data;
  }

  // Domains
  Future<List<dynamic>> getDomainsBySubject(String subjectId) async {
    final response =
        await _apiClient.get(ApiConstants.domainsBySubject(subjectId));
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> getDomainDetail(String domainId) async {
    final response = await _apiClient.get(ApiConstants.domainDetail(domainId));
    return response.data;
  }

  // Knowledge Graph
  Future<List<dynamic>> getPrerequisites(String nodeId) async {
    final response =
        await _apiClient.get(ApiConstants.getPrerequisites(nodeId));
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<dynamic>> findLearningPath(
      String fromNodeId, String toNodeId) async {
    final response =
        await _apiClient.get(ApiConstants.findPath(fromNodeId, toNodeId));
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<dynamic>> recommendNextTopics(String nodeId,
      {int limit = 5}) async {
    final response =
        await _apiClient.get(ApiConstants.recommendNext(nodeId, limit: limit));
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<dynamic>> getRelatedNodes(String nodeId, {int limit = 10}) async {
    final response = await _apiClient
        .get(ApiConstants.getRelatedNodes(nodeId, limit: limit));
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>?> getNodeByEntity(
      String type, String entityId) async {
    try {
      final response =
          await _apiClient.get(ApiConstants.getNodeByEntity(type, entityId));
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return null; // Node not found
    }
  }

  Future<List<dynamic>> getNodesByType(String type) async {
    final response = await _apiClient.get(ApiConstants.getNodesByType(type));
    return List<Map<String, dynamic>>.from(response.data);
  }

  // RAG (Semantic Search)
  Future<List<dynamic>> semanticSearch(
    String query, {
    int limit = 10,
    String? types,
    double minSimilarity = 0.7,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.semanticSearch(query,
          limit: limit, types: types, minSimilarity: minSimilarity),
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<dynamic>> retrieveRelevantNodes(
    String query, {
    int topK = 5,
    String? types,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.retrieveRelevantNodes(query, topK: topK, types: types),
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> generateRAGContext(
    String query, {
    int topK = 5,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.generateRAGContext(query, topK: topK),
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> getNodeDetail(String nodeId) async {
    final response = await _apiClient.get(ApiConstants.nodeDetail(nodeId));
    return response.data;
  }

  Future<List<dynamic>> getContentByNode(String nodeId) async {
    final response = await _apiClient.get(ApiConstants.contentByNode(nodeId));
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Lấy content theo node và độ khó
  Future<List<dynamic>> getContentByNodeAndDifficulty(
      String nodeId, String difficulty) async {
    final response = await _apiClient.get(
      ApiConstants.contentByNodeAndDifficulty(nodeId, difficulty),
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Tạo content mới theo độ khó
  Future<Map<String, dynamic>> generateContentByDifficulty(
    String nodeId,
    String difficulty,
  ) async {
    final response = await _apiClient.post(
      ApiConstants.generateContentByDifficulty(nodeId),
      data: {'difficulty': difficulty},
    );
    return response.data;
  }

  /// Tạo video/image placeholders cho node
  Future<Map<String, dynamic>> generatePlaceholders(String nodeId) async {
    final response = await _apiClient.post(
      ApiConstants.generatePlaceholders(nodeId),
    );
    return response.data;
  }

  /// Lấy tất cả placeholders
  Future<List<dynamic>> getAllPlaceholders() async {
    final response = await _apiClient.get(ApiConstants.allPlaceholders);
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Lấy placeholders của một node
  Future<List<dynamic>> getNodePlaceholders(String nodeId) async {
    final response =
        await _apiClient.get(ApiConstants.nodePlaceholders(nodeId));
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Submit contribution cho một placeholder
  Future<Map<String, dynamic>> submitContribution(
    String contentId,
    String mediaUrl,
  ) async {
    final response = await _apiClient.post(
      ApiConstants.submitContribution(contentId),
      data: {'mediaUrl': mediaUrl},
    );
    return response.data;
  }

  /// Approve contribution (admin only)
  Future<Map<String, dynamic>> approveContribution(String contentId) async {
    final response = await _apiClient.post(
      ApiConstants.approveContribution(contentId),
    );
    return response.data;
  }

  /// Reject contribution (admin only)
  Future<Map<String, dynamic>> rejectContribution(
    String contentId, {
    String? reason,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.rejectContribution(contentId),
      data: {'reason': reason},
    );
    return response.data;
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

  Future<Map<String, dynamic>> getRewardsHistory({
    int? limit,
    int? offset,
    String? source,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.rewardsHistory(
        limit: limit,
        offset: offset,
        source: source,
      ),
    );
    return response.data;
  }

  // Achievements
  Future<List<dynamic>> getAchievements() async {
    final response = await _apiClient.get(ApiConstants.achievements);
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<dynamic>> getUserAchievements() async {
    final response = await _apiClient.get(ApiConstants.userAchievements);
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> checkAchievements() async {
    final response = await _apiClient.post(ApiConstants.checkAchievements);
    return response.data;
  }

  Future<Map<String, dynamic>> claimAchievementRewards(
      String userAchievementId) async {
    final response = await _apiClient.post(
      ApiConstants.claimAchievementRewards(userAchievementId),
    );
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

  /// Get completed content item IDs for a subject
  /// Used for "Lộ trình tổng quát" to determine unlocked lessons
  Future<List<String>> getCompletedContentItemsBySubject(String subjectId) async {
    final response = await _apiClient.get(
      ApiConstants.completedContentItemsBySubject(subjectId),
    );
    final data = response.data as Map<String, dynamic>;
    final completedIds = data['completedContentIds'] as List<dynamic>? ?? [];
    return completedIds.map((e) => e.toString()).toList();
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

  // Adaptive Placement Test
  Future<Map<String, dynamic>> startAdaptivePlacementTest(String subjectId) async {
    final response = await _apiClient.post(
      ApiConstants.startAdaptiveTest(subjectId),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> submitAdaptiveAnswer(String testId, int answer) async {
    final response = await _apiClient.post(
      ApiConstants.submitAdaptiveAnswer(testId),
      data: {'answer': answer},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getAdaptiveTestResult(String testId) async {
    final response = await _apiClient.get(
      ApiConstants.getAdaptiveTestResult(testId),
    );
    return response.data;
  }

  // User Profile
  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await _apiClient.get(ApiConstants.me);
    return response.data;
  }

  // Switch Role (user <-> contributor)
  Future<Map<String, dynamic>> switchRole(String role) async {
    final response = await _apiClient.patch(
      ApiConstants.switchRole,
      data: {'role': role},
    );
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
    required String
        type, // 'add_video', 'add_image', 'add_text', 'update_content'
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

  Future<Map<String, dynamic>> submitLessonEdit({
    required String contentItemId,
    required String title,
    dynamic richContent, // Optional for quiz
    List<String>? imageUrls,
    String? videoUrl,
    String? description,
    Map<String, dynamic>?
        quizData, // Quiz data: {question, options, correctAnswer, explanation}
    Map<String, dynamic>?
        textVariants, // Text variants: {simple, detailed, comprehensive}
  }) async {
    final response = await _apiClient.post(
      ApiConstants.submitLessonEdit(contentItemId),
      data: {
        'title': title,
        if (richContent != null) 'richContent': richContent,
        if (imageUrls != null) 'imageUrls': imageUrls,
        if (videoUrl != null) 'videoUrl': videoUrl,
        if (description != null) 'description': description,
        if (quizData != null) 'quizData': quizData,
        if (textVariants != null) 'textVariants': textVariants,
      },
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
    final response =
        await _apiClient.put(ApiConstants.approveContentEdit(editId));
    return response.data;
  }

  Future<Map<String, dynamic>> rejectContentEdit(String editId) async {
    final response =
        await _apiClient.put(ApiConstants.rejectContentEdit(editId));
    return response.data;
  }

  Future<Map<String, dynamic>> removeContentEdit(String editId) async {
    final response =
        await _apiClient.delete(ApiConstants.removeContentEdit(editId));
    return response.data;
  }

  Future<Map<String, dynamic>> getEditComparison(String editId) async {
    final response =
        await _apiClient.get(ApiConstants.getEditComparison(editId));
    return response.data;
  }

  Future<List<dynamic>> getAllContentItemsWithEdits() async {
    final response = await _apiClient.get(ApiConstants.allContentWithEdits);
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<dynamic>> getMyContentEdits() async {
    final response = await _apiClient.get(ApiConstants.getMyContentEdits);
    return List<Map<String, dynamic>>.from(response.data);
  }

  // Edit History
  Future<List<dynamic>> getHistoryForContent(String contentItemId) async {
    final response =
        await _apiClient.get(ApiConstants.getHistoryForContent(contentItemId));
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<dynamic>> getHistoryForUser() async {
    final response = await _apiClient.get(ApiConstants.getHistoryForUser);
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<dynamic>> getAllHistory() async {
    final response = await _apiClient.get(ApiConstants.getAllHistory);
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<dynamic>> getHistoryForEdit(String editId) async {
    final response =
        await _apiClient.get(ApiConstants.getHistoryForEdit(editId));
    return List<Map<String, dynamic>>.from(response.data);
  }

  // Content Versions
  Future<List<dynamic>> getVersionsForContent(String contentItemId) async {
    final response =
        await _apiClient.get(ApiConstants.getVersionsForContent(contentItemId));
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<dynamic>> getMyVersions({String? contentItemId}) async {
    final response = await _apiClient.post(
      ApiConstants.getMyVersions,
      data: contentItemId != null ? {'contentItemId': contentItemId} : null,
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<dynamic>> getMyVersionsForContent(String contentItemId) async {
    final response = await _apiClient
        .get(ApiConstants.getMyVersionsForContent(contentItemId));
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> revertToVersion(String versionId) async {
    final response =
        await _apiClient.post(ApiConstants.revertToVersion(versionId));
    return Map<String, dynamic>.from(response.data);
  }

  // Personal Mind Map
  Future<Map<String, dynamic>> checkPersonalMindMap(String subjectId) async {
    final response =
        await _apiClient.get(ApiConstants.checkPersonalMindMap(subjectId));
    return response.data;
  }

  Future<Map<String, dynamic>> getPersonalMindMap(String subjectId) async {
    final response =
        await _apiClient.get(ApiConstants.getPersonalMindMap(subjectId));
    return response.data;
  }

  Future<Map<String, dynamic>> createPersonalMindMap(
      String subjectId, String learningGoal) async {
    final response = await _apiClient.post(
      ApiConstants.createPersonalMindMap(subjectId),
      data: {'learningGoal': learningGoal},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updatePersonalMindMapNode(
    String subjectId,
    String nodeId,
    String status,
  ) async {
    final response = await _apiClient.patch(
      ApiConstants.updatePersonalMindMapNode(subjectId, nodeId),
      data: {'status': status},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> deletePersonalMindMap(String subjectId) async {
    final response =
        await _apiClient.delete(ApiConstants.deletePersonalMindMap(subjectId));
    return response.data;
  }

  // Personal Mind Map - Chat riêng cho từng môn học
  // AI sẽ hỏi dựa trên domains, topics, bài học có sẵn

  /// Bắt đầu chat session để tạo lộ trình cá nhân
  /// AI sẽ hỏi dựa trên nội dung môn học cụ thể
  Future<Map<String, dynamic>> startPersonalMindMapChat(
      String subjectId) async {
    final response = await _apiClient.post(
      ApiConstants.startPersonalMindMapChat(subjectId),
    );
    return response.data;
  }

  /// Gửi tin nhắn trong chat session
  Future<Map<String, dynamic>> personalMindMapChat(
    String subjectId,
    String message,
  ) async {
    final response = await _apiClient.post(
      ApiConstants.personalMindMapChat(subjectId),
      data: {'message': message},
    );
    return response.data;
  }

  /// Lấy thông tin chat session hiện tại
  Future<Map<String, dynamic>> getPersonalMindMapChatSession(
      String subjectId) async {
    final response = await _apiClient.get(
      ApiConstants.getPersonalMindMapChatSession(subjectId),
    );
    return response.data;
  }

  /// Tạo lộ trình từ chat đã hoàn thành
  Future<Map<String, dynamic>> generatePersonalMindMapFromChat(
      String subjectId) async {
    final response = await _apiClient.post(
      ApiConstants.generatePersonalMindMapFromChat(subjectId),
    );
    return response.data;
  }

  /// Reset chat session để bắt đầu lại
  Future<Map<String, dynamic>> resetPersonalMindMapChat(
      String subjectId) async {
    final response = await _apiClient.post(
      ApiConstants.resetPersonalMindMapChat(subjectId),
    );
    return response.data;
  }

  // === CONTRIBUTION HELPER METHODS ===
  // Tất cả contribution đều sử dụng content-edits system để có:
  // - Lịch sử đóng góp
  // - Phiên bản
  // - Voting
  // - Preview & So sánh
  // - Admin duyệt/từ chối

  /// Upload và submit contribution cho video (dùng content-edits flow)
  Future<Map<String, dynamic>> contributeVideo(
      String contentId, String videoPath,
      {String? description, String? caption}) async {
    // 1. Upload video qua content-edits upload endpoint
    final uploadResult = await uploadVideoForEdit(videoPath);
    final videoUrl =
        uploadResult['videoUrl'] as String? ?? uploadResult['url'] as String;

    // 2. Submit contribution qua content-edits flow
    return submitContentEdit(
      contentItemId: contentId,
      type: 'add_video',
      videoUrl: videoUrl,
      description: description,
      caption: caption,
    );
  }

  /// Upload và submit contribution cho image (dùng content-edits flow)
  Future<Map<String, dynamic>> contributeImage(
      String contentId, String imagePath,
      {String? description, String? caption}) async {
    // 1. Upload image qua content-edits upload endpoint
    final uploadResult = await uploadImageForEdit(imagePath);
    final imageUrl =
        uploadResult['imageUrl'] as String? ?? uploadResult['url'] as String;

    // 2. Submit contribution qua content-edits flow
    return submitContentEdit(
      contentItemId: contentId,
      type: 'add_image',
      imageUrl: imageUrl,
      description: description,
      caption: caption,
    );
  }

  /// Tạo mới video contribution cho một node (dùng content-edits flow)
  /// Trước tiên tạo placeholder content item, sau đó submit edit
  Future<Map<String, dynamic>> createNewVideoContribution(
      String nodeId, String videoPath,
      {String? title, String? description}) async {
    // 1. Tạo placeholder content item
    final placeholderResponse = await _apiClient.post(
      ApiConstants.createNewContribution(nodeId),
      data: {
        'format': 'video',
        'title': title ?? 'Video đóng góp mới',
      },
    );
    final contentItemId = placeholderResponse.data['id'] as String;

    // 2. Upload video
    final uploadResult = await uploadVideoForEdit(videoPath);
    final videoUrl =
        uploadResult['videoUrl'] as String? ?? uploadResult['url'] as String;

    // 3. Submit contribution qua content-edits flow
    return submitContentEdit(
      contentItemId: contentItemId,
      type: 'add_video',
      videoUrl: videoUrl,
      description: description ?? 'Video đóng góp mới cho bài học',
    );
  }

  /// Tạo mới image contribution cho một node (dùng content-edits flow)
  Future<Map<String, dynamic>> createNewImageContribution(
      String nodeId, String imagePath,
      {String? title, String? description}) async {
    // 1. Tạo placeholder content item
    final placeholderResponse = await _apiClient.post(
      ApiConstants.createNewContribution(nodeId),
      data: {
        'format': 'image',
        'title': title ?? 'Hình ảnh đóng góp mới',
      },
    );
    final contentItemId = placeholderResponse.data['id'] as String;

    // 2. Upload image
    final uploadResult = await uploadImageForEdit(imagePath);
    final imageUrl =
        uploadResult['imageUrl'] as String? ?? uploadResult['url'] as String;

    // 3. Submit contribution qua content-edits flow
    return submitContentEdit(
      contentItemId: contentItemId,
      type: 'add_image',
      imageUrl: imageUrl,
      description: description ?? 'Hình ảnh đóng góp mới cho bài học',
    );
  }

  /// Submit text contribution cho một content item (dùng content-edits flow)
  Future<Map<String, dynamic>> contributeText(
      String contentId, String textContent,
      {String? description}) async {
    return submitContentEdit(
      contentItemId: contentId,
      type: 'add_text',
      textContent: textContent,
      description: description,
    );
  }

  /// Cập nhật nội dung bài học (full lesson edit với history)
  Future<Map<String, dynamic>> updateLessonContent({
    required String contentItemId,
    required String title,
    String? textContent,
    String? videoUrl,
    String? imageUrl,
    List<String>? imageUrls,
    String? description,
    Map<String, dynamic>? quizData,
    dynamic richContent,
  }) async {
    return submitLessonEdit(
      contentItemId: contentItemId,
      title: title,
      richContent: richContent,
      imageUrls: imageUrls,
      videoUrl: videoUrl,
      description: description,
      quizData: quizData,
    );
  }

  // =====================
  // Pending Contributions (Contributor mode)
  // =====================

  Future<List<dynamic>> getMyPendingContributions() async {
    final response = await _apiClient.get(ApiConstants.myPendingContributions);
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> createSubjectContribution({
    required String name,
    String? description,
    String? track,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.createSubjectContribution,
      data: {
        'name': name,
        if (description != null) 'description': description,
        if (track != null) 'track': track,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> createDomainContribution({
    required String name,
    required String subjectId,
    String? description,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.createDomainContribution,
      data: {
        'name': name,
        'subjectId': subjectId,
        if (description != null) 'description': description,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> createTopicContribution({
    required String name,
    required String domainId,
    required String subjectId,
    String? description,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.createTopicContribution,
      data: {
        'name': name,
        'domainId': domainId,
        'subjectId': subjectId,
        if (description != null) 'description': description,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> createLessonContribution({
    required String title,
    required String nodeId,
    required String subjectId,
    String? content,
    dynamic richContent,
    String? description,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.createLessonContribution,
      data: {
        'title': title,
        'nodeId': nodeId,
        'subjectId': subjectId,
        if (content != null) 'content': content,
        if (richContent != null) 'richContent': richContent,
        if (description != null) 'description': description,
      },
    );
    return response.data;
  }

  Future<void> deletePendingContribution(String id) async {
    await _apiClient.delete(ApiConstants.pendingContributionDetail(id));
  }

  // Admin: pending contributions
  Future<List<dynamic>> getAdminPendingContributions() async {
    final response =
        await _apiClient.get(ApiConstants.adminPendingContributions);
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> approvePendingContribution(
    String id, {
    String? note,
  }) async {
    final response = await _apiClient.put(
      ApiConstants.approvePendingContribution(id),
      data: note != null ? {'note': note} : {},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> rejectPendingContribution(
    String id, {
    String? note,
  }) async {
    final response = await _apiClient.put(
      ApiConstants.rejectPendingContribution(id),
      data: note != null ? {'note': note} : {},
    );
    return response.data;
  }

  // =====================
  // Quiz APIs
  // =====================

  /// Generate quiz for a content item (concept or example)
  Future<Map<String, dynamic>> generateQuiz(String contentItemId) async {
    final response = await _apiClient.post(
      ApiConstants.generateQuiz,
      data: {'contentItemId': contentItemId},
    );
    return response.data;
  }

  /// Generate boss quiz for a learning node
  Future<Map<String, dynamic>> generateBossQuiz(String nodeId) async {
    final response = await _apiClient.post(
      ApiConstants.generateBossQuiz,
      data: {'nodeId': nodeId},
    );
    return response.data;
  }

  /// Submit quiz answers
  Future<Map<String, dynamic>> submitQuiz(
    String sessionId,
    Map<String, String> answers,
  ) async {
    final response = await _apiClient.post(
      ApiConstants.submitQuiz,
      data: {
        'sessionId': sessionId,
        'answers': answers,
      },
    );
    return response.data;
  }

  // =====================
  // Payment APIs
  // =====================

  /// Get available payment packages
  Future<Map<String, dynamic>> getPaymentPackages() async {
    final response = await _apiClient.get(ApiConstants.paymentPackages);
    return response.data;
  }

  /// Create a payment order
  Future<Map<String, dynamic>> createPayment(String packageId) async {
    final response = await _apiClient.post(
      ApiConstants.createPayment,
      data: {'packageId': packageId},
    );
    return response.data;
  }

  /// Get payment details
  Future<Map<String, dynamic>> getPayment(String paymentId) async {
    final response = await _apiClient.get(ApiConstants.getPayment(paymentId));
    return response.data;
  }

  /// Get payment history
  Future<List<dynamic>> getPaymentHistory() async {
    final response = await _apiClient.get(ApiConstants.paymentHistory);
    return response.data['payments'] ?? [];
  }

  /// Get premium status
  Future<Map<String, dynamic>> getPremiumStatus() async {
    final response = await _apiClient.get(ApiConstants.premiumStatus);
    return response.data;
  }

  /// Get pending payment
  Future<Map<String, dynamic>> getPendingPayment() async {
    final response = await _apiClient.get(ApiConstants.pendingPayment);
    return response.data;
  }
}
