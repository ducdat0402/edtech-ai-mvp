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

  // Topics
  Future<List<dynamic>> getTopicsByDomain(String domainId) async {
    final response =
        await _apiClient.get(ApiConstants.topicsByDomain(domainId));
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> getTopicDetail(String topicId) async {
    final response = await _apiClient.get(ApiConstants.topicDetail(topicId));
    return response.data;
  }

  // Learning nodes by topic
  Future<List<dynamic>> getNodesByTopic(String topicId) async {
    final response = await _apiClient.get(ApiConstants.nodesByTopic(topicId));
    return List<Map<String, dynamic>>.from(response.data);
  }

  // Learning Node Detail
  Future<Map<String, dynamic>> getNodeDetail(String nodeId) async {
    final response = await _apiClient.get(ApiConstants.nodeDetail(nodeId));
    return response.data;
  }

  // === Lesson Content (4 lesson types) ===
  Future<Map<String, dynamic>> getLessonData(String nodeId) async {
    final response = await _apiClient.get(ApiConstants.getLessonData(nodeId));
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> updateLessonContent(String nodeId, Map<String, dynamic> data) async {
    final response = await _apiClient.put(ApiConstants.updateLessonContent(nodeId), data: data);
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> generateEndQuiz(String nodeId) async {
    final response = await _apiClient.post(ApiConstants.generateEndQuiz(nodeId));
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> submitEndQuiz(String nodeId, List<int> answers) async {
    final response = await _apiClient.post(
      ApiConstants.submitEndQuiz(nodeId),
      data: {'answers': answers},
    );
    return Map<String, dynamic>.from(response.data);
  }

  // Uploads
  Future<String> uploadImage(String imagePath) async {
    final response = await _apiClient.postFile(
      ApiConstants.uploadImage,
      fileKey: 'image',
      filePath: imagePath,
    );
    final data = response.data;
    return data['imageUrl'] as String? ?? data['url'] as String;
  }

  Future<Map<String, dynamic>> uploadVideo(String videoPath) async {
    final response = await _apiClient.postFile(
      ApiConstants.uploadVideo,
      fileKey: 'video',
      filePath: videoPath,
    );
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

  Future<Map<String, dynamic>> completeNode(String nodeId) async {
    final response = await _apiClient.post(
      ApiConstants.completeNode,
      data: {'nodeId': nodeId},
    );
    return response.data;
  }

  // === New: Lesson type completion cascade ===

  /// Complete a specific lesson type for a node (triggers cascade rewards)
  Future<Map<String, dynamic>> completeLessonType(String nodeId, String lessonType) async {
    final response = await _apiClient.post(
      ApiConstants.completeLessonType,
      data: {'nodeId': nodeId, 'lessonType': lessonType},
    );
    return Map<String, dynamic>.from(response.data);
  }

  /// Get lesson type progress for a node (which types completed)
  Future<Map<String, dynamic>> getLessonTypeProgress(String nodeId) async {
    final response = await _apiClient.get(ApiConstants.lessonTypeProgress(nodeId));
    return Map<String, dynamic>.from(response.data);
  }

  /// Get topic progress for current user
  Future<Map<String, dynamic>> getTopicProgress(String topicId) async {
    final response = await _apiClient.get(ApiConstants.topicProgress(topicId));
    return Map<String, dynamic>.from(response.data);
  }

  /// Get domain progress for current user
  Future<Map<String, dynamic>> getDomainProgress(String domainId) async {
    final response = await _apiClient.get(ApiConstants.domainProgress(domainId));
    return Map<String, dynamic>.from(response.data);
  }

  /// Get all lesson type contents for a node
  Future<Map<String, dynamic>> getLessonTypeContents(String nodeId) async {
    final response = await _apiClient.get(ApiConstants.lessonTypeContentsByNode(nodeId));
    return Map<String, dynamic>.from(response.data);
  }

  /// Submit end quiz for a specific lesson type
  Future<Map<String, dynamic>> submitEndQuizForType(
    String nodeId,
    String lessonType,
    List<int> answers,
  ) async {
    final response = await _apiClient.post(
      ApiConstants.submitEndQuizForType(nodeId, lessonType),
      data: {'answers': answers},
    );
    return Map<String, dynamic>.from(response.data);
  }

  /// Get lesson data for a specific type
  Future<Map<String, dynamic>> getLessonDataByType(String nodeId, String lessonType) async {
    final response = await _apiClient.get(ApiConstants.getLessonDataByType(nodeId, lessonType));
    return Map<String, dynamic>.from(response.data);
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

  // Personal Mind Map - Chat
  Future<Map<String, dynamic>> startPersonalMindMapChat(String subjectId) async {
    final response = await _apiClient.post(
      ApiConstants.startPersonalMindMapChat(subjectId),
    );
    return response.data;
  }

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

  Future<Map<String, dynamic>> getPersonalMindMapChatSession(String subjectId) async {
    final response = await _apiClient.get(
      ApiConstants.getPersonalMindMapChatSession(subjectId),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> generatePersonalMindMapFromChat(String subjectId) async {
    final response = await _apiClient.post(
      ApiConstants.generatePersonalMindMapFromChat(subjectId),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> resetPersonalMindMapChat(String subjectId) async {
    final response = await _apiClient.post(
      ApiConstants.resetPersonalMindMapChat(subjectId),
    );
    return response.data;
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
    String? difficulty,
    String? afterEntityId,
    int? expReward,
    int? coinReward,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.createDomainContribution,
      data: {
        'name': name,
        'subjectId': subjectId,
        if (description != null) 'description': description,
        if (difficulty != null) 'difficulty': difficulty,
        if (afterEntityId != null) 'afterEntityId': afterEntityId,
        if (expReward != null) 'expReward': expReward,
        if (coinReward != null) 'coinReward': coinReward,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> createTopicContribution({
    required String name,
    required String domainId,
    required String subjectId,
    String? description,
    String? difficulty,
    String? afterEntityId,
    int? expReward,
    int? coinReward,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.createTopicContribution,
      data: {
        'name': name,
        'domainId': domainId,
        'subjectId': subjectId,
        if (description != null) 'description': description,
        if (difficulty != null) 'difficulty': difficulty,
        if (afterEntityId != null) 'afterEntityId': afterEntityId,
        if (expReward != null) 'expReward': expReward,
        if (coinReward != null) 'coinReward': coinReward,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> createLessonContribution(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      ApiConstants.createLessonContribution,
      data: data,
    );
    return response.data;
  }

  Future<void> deletePendingContribution(String id) async {
    await _apiClient.delete(ApiConstants.pendingContributionDetail(id));
  }

  Future<Map<String, dynamic>> createEditContribution({
    required String type,
    required String entityId,
    required String newName,
    String? newDescription,
    String? reason,
    String? domainId,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.createEditContribution,
      data: {
        'type': type,
        'entityId': entityId,
        'newName': newName,
        if (newDescription != null) 'newDescription': newDescription,
        if (reason != null) 'reason': reason,
        if (domainId != null) 'domainId': domainId,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> createDeleteContribution({
    required String type,
    required String entityId,
    String? reason,
    String? domainId,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.createDeleteContribution,
      data: {
        'type': type,
        'entityId': entityId,
        if (reason != null) 'reason': reason,
        if (domainId != null) 'domainId': domainId,
      },
    );
    return response.data;
  }

  // Lesson Content Edit contribution
  Future<Map<String, dynamic>> createLessonContentEditContribution(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      ApiConstants.createLessonContentEdit,
      data: data,
    );
    return response.data;
  }

  // Lesson Type Version History
  Future<Map<String, dynamic>> getLessonTypeHistory(String nodeId, String lessonType) async {
    final response = await _apiClient.get(
      ApiConstants.lessonTypeHistory(nodeId, lessonType),
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> getLessonTypeVersion(String versionId) async {
    final response = await _apiClient.get(
      ApiConstants.lessonTypeVersionDetail(versionId),
    );
    return Map<String, dynamic>.from(response.data);
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
  // Payment APIs
  // =====================

  Future<Map<String, dynamic>> getPaymentPackages() async {
    final response = await _apiClient.get(ApiConstants.paymentPackages);
    return response.data;
  }

  Future<Map<String, dynamic>> createPayment(String packageId) async {
    final response = await _apiClient.post(
      ApiConstants.createPayment,
      data: {'packageId': packageId},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getPayment(String paymentId) async {
    final response = await _apiClient.get(ApiConstants.getPayment(paymentId));
    return response.data;
  }

  Future<List<dynamic>> getPaymentHistory() async {
    final response = await _apiClient.get(ApiConstants.paymentHistory);
    return response.data['payments'] ?? [];
  }

  Future<Map<String, dynamic>> getPremiumStatus() async {
    final response = await _apiClient.get(ApiConstants.premiumStatus);
    return response.data;
  }

  Future<Map<String, dynamic>> getPendingPayment() async {
    final response = await _apiClient.get(ApiConstants.pendingPayment);
    return response.data;
  }
}
