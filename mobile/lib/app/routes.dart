import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/colors.dart';
import 'package:edtech_mobile/features/auth/screens/login_screen.dart';
import 'package:edtech_mobile/features/auth/screens/register_screen.dart';
import 'package:edtech_mobile/features/dashboard/screens/dashboard_screen.dart';
import 'package:edtech_mobile/features/onboarding/screens/onboarding_chat_screen.dart';
import 'package:edtech_mobile/features/placement_test/screens/placement_test_screen.dart';
import 'package:edtech_mobile/features/placement_test/screens/analysis_complete_screen.dart';
import 'package:edtech_mobile/features/subjects/screens/subject_intro_screen.dart';
import 'package:edtech_mobile/features/subjects/screens/subject_learning_goals_screen.dart';
import 'package:edtech_mobile/features/subjects/screens/personal_mind_map_screen.dart';
import 'package:edtech_mobile/features/subjects/screens/learning_path_choice_screen.dart';
import 'package:edtech_mobile/features/placement_test/screens/adaptive_placement_test_screen.dart';
import 'package:edtech_mobile/features/domains/screens/domains_list_screen.dart';
import 'package:edtech_mobile/features/domains/screens/domain_detail_screen.dart';
import 'package:edtech_mobile/features/learning_nodes/screens/all_lessons_screen.dart';
import 'package:edtech_mobile/features/learning_nodes/screens/node_detail_screen.dart';
import 'package:edtech_mobile/features/learning_nodes/screens/contribution_upload_screen.dart';
import 'package:edtech_mobile/features/quests/screens/daily_quests_screen.dart';
import 'package:edtech_mobile/features/leaderboard/screens/leaderboard_screen.dart';
import 'package:edtech_mobile/features/currency/screens/currency_screen.dart';
import 'package:edtech_mobile/features/profile/screens/profile_screen.dart';
import 'package:edtech_mobile/features/profile/screens/journey_log_screen.dart';
import 'package:edtech_mobile/features/admin/screens/admin_panel_screen.dart';
import 'package:edtech_mobile/features/learning_nodes/screens/my_contributions_screen.dart';
import 'package:edtech_mobile/features/payment/screens/payment_screen.dart';
import 'package:edtech_mobile/features/contributor/screens/create_subject_screen.dart';
import 'package:edtech_mobile/features/contributor/screens/create_domain_screen.dart';
import 'package:edtech_mobile/features/contributor/screens/create_topic_screen.dart';
import 'package:edtech_mobile/features/contributor/screens/contributor_mind_map_screen.dart';
import 'package:edtech_mobile/features/contributor/screens/create_lesson_screen.dart';
import 'package:edtech_mobile/features/contributor/screens/my_pending_contributions_screen.dart';
import 'package:edtech_mobile/features/lessons/screens/lesson_type_picker_screen.dart';
import 'package:edtech_mobile/features/lessons/screens/image_quiz_lesson_screen.dart';
import 'package:edtech_mobile/features/lessons/screens/image_gallery_lesson_screen.dart';
import 'package:edtech_mobile/features/lessons/screens/video_lesson_screen.dart';
import 'package:edtech_mobile/features/lessons/screens/text_lesson_screen.dart';
import 'package:edtech_mobile/features/lessons/screens/end_quiz_screen.dart';
import 'package:edtech_mobile/features/lessons/screens/lesson_types_overview_screen.dart';
import 'package:edtech_mobile/features/subjects/screens/unlock_subject_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingChatScreen(),
    ),
    GoRoute(
      path: '/placement-test',
      builder: (context, state) => const PlacementTestScreen(),
    ),
    GoRoute(
      path: '/placement-test/analysis/:testId',
      builder: (context, state) {
        final testId = state.pathParameters['testId']!;
        return AnalysisCompleteScreen(testId: testId);
      },
    ),
    GoRoute(
      path: '/subjects/:id/intro',
      builder: (context, state) {
        final subjectId = state.pathParameters['id']!;
        return SubjectIntroScreen(subjectId: subjectId);
      },
    ),
    GoRoute(
      path: '/subjects/:id/unlock',
      builder: (context, state) {
        final subjectId = state.pathParameters['id']!;
        return UnlockSubjectScreen(subjectId: subjectId);
      },
    ),
    GoRoute(
      path: '/subjects/:id/learning-goals',
      builder: (context, state) {
        final subjectId = state.pathParameters['id']!;
        return SubjectLearningGoalsScreen(subjectId: subjectId);
      },
    ),
    GoRoute(
      path: '/subjects/:id/personal-mind-map',
      builder: (context, state) {
        final subjectId = state.pathParameters['id']!;
        return PersonalMindMapScreen(subjectId: subjectId);
      },
    ),
    GoRoute(
      path: '/subjects/:id/learning-path-choice',
      builder: (context, state) {
        final subjectId = state.pathParameters['id']!;
        final subjectName = state.uri.queryParameters['name'];
        final forceChoice = state.uri.queryParameters['force'] == 'true';
        return LearningPathChoiceScreen(
          subjectId: subjectId,
          subjectName: subjectName,
          forceShowChoice: forceChoice,
        );
      },
    ),
    GoRoute(
      path: '/subjects/:id/adaptive-test',
      builder: (context, state) {
        final subjectId = state.pathParameters['id']!;
        final subjectName = state.uri.queryParameters['name'];
        return AdaptivePlacementTestScreen(
          subjectId: subjectId,
          subjectName: subjectName,
        );
      },
    ),
    GoRoute(
      path: '/subjects/:id/domains',
      builder: (context, state) {
        final subjectId = state.pathParameters['id']!;
        final subjectName = state.uri.queryParameters['name'];
        return DomainsListScreen(
          subjectId: subjectId,
          subjectName: subjectName,
        );
      },
    ),
    GoRoute(
      path: '/subjects/:id/all-lessons',
      builder: (context, state) {
        final subjectId = state.pathParameters['id']!;
        return AllLessonsScreen(subjectId: subjectId);
      },
    ),
    GoRoute(
      path: '/domains/:id',
      builder: (context, state) {
        final domainId = state.pathParameters['id']!;
        return DomainDetailScreen(domainId: domainId);
      },
    ),
    GoRoute(
      path: '/nodes/:id',
      builder: (context, state) {
        final nodeId = state.pathParameters['id']!;
        final difficulty = state.uri.queryParameters['difficulty'];
        return NodeDetailScreen(nodeId: nodeId, difficulty: difficulty);
      },
    ),
    GoRoute(
      path: '/contribute/:contentId',
      builder: (context, state) {
        final contentId = state.pathParameters['contentId']!;
        final format = state.uri.queryParameters['format'] ?? 'image';
        final extra = state.extra as Map<String, dynamic>?;
        return ContributionUploadScreen(
          contentId: contentId,
          format: format,
          title: extra?['title'] as String?,
          contributionGuide: extra?['contributionGuide'] as Map<String, dynamic>?,
          nodeId: extra?['nodeId'] as String?,
          isNewContribution: extra?['isNewContribution'] as bool? ?? false,
        );
      },
    ),
    GoRoute(
      path: '/quests',
      builder: (context, state) => const DailyQuestsScreen(),
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) {
        final subjectId = state.uri.queryParameters['subjectId'];
        return LeaderboardScreen(subjectId: subjectId);
      },
    ),
    GoRoute(
      path: '/currency',
      builder: (context, state) => const CurrencyScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
      routes: [
        GoRoute(
          path: 'journey',
          builder: (context, state) => const JourneyLogScreen(),
        ),
        GoRoute(
          path: 'contributions',
          builder: (context, state) => const MyContributionsScreen(),
        ),
      ],
    ),
    // Also add as standalone route for easier access
    GoRoute(
      path: '/my-contributions',
      builder: (context, state) => const MyContributionsScreen(),
    ),
    GoRoute(
      path: '/admin/panel',
      builder: (context, state) => const AdminPanelScreen(),
    ),
    GoRoute(
      path: '/payment',
      builder: (context, state) => const PaymentScreen(),
    ),
    // Contributor routes
    GoRoute(
      path: '/contributor/mind-map',
      builder: (context, state) {
        final subjectId = state.uri.queryParameters['subjectId'] ?? '';
        final subjectName = state.uri.queryParameters['subjectName'];
        return ContributorMindMapScreen(
          subjectId: subjectId,
          subjectName: subjectName,
        );
      },
    ),
    GoRoute(
      path: '/contributor/create-subject',
      builder: (context, state) => const CreateSubjectScreen(),
    ),
    GoRoute(
      path: '/contributor/create-domain',
      builder: (context, state) {
        final subjectId = state.uri.queryParameters['subjectId'] ?? '';
        final subjectName = state.uri.queryParameters['subjectName'];
        return CreateDomainScreen(
          subjectId: subjectId,
          subjectName: subjectName,
        );
      },
    ),
    GoRoute(
      path: '/contributor/create-topic',
      builder: (context, state) {
        final subjectId = state.uri.queryParameters['subjectId'] ?? '';
        final domainId = state.uri.queryParameters['domainId'] ?? '';
        final domainName = state.uri.queryParameters['domainName'];
        return CreateTopicScreen(
          subjectId: subjectId,
          domainId: domainId,
          domainName: domainName,
        );
      },
    ),
    GoRoute(
      path: '/contributor/create-lesson',
      builder: (context, state) {
        final subjectId = state.uri.queryParameters['subjectId'] ?? '';
        final domainId = state.uri.queryParameters['domainId'] ?? '';
        final topicId = state.uri.queryParameters['topicId'] ?? '';
        final topicName = state.uri.queryParameters['topicName'];
        return CreateLessonScreen(
          subjectId: subjectId,
          domainId: domainId,
          topicId: topicId,
          topicName: topicName,
        );
      },
    ),
    GoRoute(
      path: '/contributor/my-contributions',
      builder: (context, state) => const MyPendingContributionsScreen(),
    ),
    // Lesson Type Picker / Direct editor (for contributors adding lesson type content)
    GoRoute(
      path: '/lessons/create',
      builder: (context, state) {
        final subjectId = state.uri.queryParameters['subjectId'] ?? '';
        final domainId = state.uri.queryParameters['domainId'] ?? '';
        final topicName = state.uri.queryParameters['topicName'];
        final topicId = state.uri.queryParameters['topicId'];
        final lessonType = state.uri.queryParameters['lessonType'];
        final nodeId = state.uri.queryParameters['nodeId'];
        final existingLessonNodeId = state.uri.queryParameters['existingLessonNodeId'];
        final existingLessonType = state.uri.queryParameters['existingLessonType'];
        return LessonTypePickerScreen(
          subjectId: subjectId,
          domainId: domainId,
          topicName: topicName,
          topicId: topicId,
          preselectedType: lessonType,
          nodeId: nodeId,
          existingLessonNodeId: existingLessonNodeId,
          existingLessonType: existingLessonType,
        );
      },
    ),
    // Lesson Edit (for contributors) - loads node data and opens viewer/editor
    GoRoute(
      path: '/lessons/edit/:nodeId',
      builder: (context, state) {
        final nodeId = state.pathParameters['nodeId']!;
        return _LessonEditLoader(nodeId: nodeId);
      },
    ),
    // Lesson Types Overview (shows all available types for a lesson)
    GoRoute(
      path: '/lessons/:nodeId/types',
      builder: (context, state) {
        final nodeId = state.pathParameters['nodeId']!;
        final extra = state.extra as Map<String, dynamic>?;
        final title = extra?['title'] as String? ?? 'Bài học';
        return LessonTypesOverviewScreen(nodeId: nodeId, title: title);
      },
    ),
    // Lesson Viewers (for learners)
    GoRoute(
      path: '/lessons/:nodeId/view',
      builder: (context, state) {
        final nodeId = state.pathParameters['nodeId']!;
        final extra = state.extra as Map<String, dynamic>?;
        final lessonType = extra?['lessonType'] as String? ?? 'text';
        final lessonData = extra?['lessonData'] as Map<String, dynamic>? ?? {};
        final title = extra?['title'] as String? ?? 'Bài học';
        final endQuiz = extra?['endQuiz'] as Map<String, dynamic>?;
        
        switch (lessonType) {
          case 'image_quiz':
            return ImageQuizLessonScreen(nodeId: nodeId, lessonData: lessonData, title: title, endQuiz: endQuiz, lessonType: lessonType);
          case 'image_gallery':
            return ImageGalleryLessonScreen(nodeId: nodeId, lessonData: lessonData, title: title, endQuiz: endQuiz, lessonType: lessonType);
          case 'video':
            return VideoLessonScreen(nodeId: nodeId, lessonData: lessonData, title: title, endQuiz: endQuiz, lessonType: lessonType);
          case 'text':
          default:
            return TextLessonScreen(nodeId: nodeId, lessonData: lessonData, title: title, endQuiz: endQuiz, lessonType: lessonType);
        }
      },
    ),
    // End Quiz
    GoRoute(
      path: '/lessons/:nodeId/end-quiz',
      builder: (context, state) {
        final nodeId = state.pathParameters['nodeId']!;
        final extra = state.extra as Map<String, dynamic>?;
        final title = extra?['title'] as String? ?? 'Bài test';
        final questions = extra?['questions'] as List<dynamic>?;
        final lessonType = extra?['lessonType'] as String?;
        return EndQuizScreen(nodeId: nodeId, title: title, lessonType: lessonType, questions: questions);
      },
    ),
  ],
);

/// Helper widget that loads lesson node data and opens the appropriate viewer
class _LessonEditLoader extends StatefulWidget {
  final String nodeId;
  const _LessonEditLoader({required this.nodeId});

  @override
  State<_LessonEditLoader> createState() => _LessonEditLoaderState();
}

class _LessonEditLoaderState extends State<_LessonEditLoader> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAndNavigate();
  }

  Future<void> _loadAndNavigate() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final node = await apiService.getNodeDetail(widget.nodeId);
      if (!mounted) return;

      final lessonType = node['lessonType'] as String? ?? 'text';
      final lessonData = node['lessonData'] as Map<String, dynamic>? ?? {};
      final title = node['title'] as String? ?? 'Bài học';
      final endQuiz = node['endQuiz'] as Map<String, dynamic>?;

      // Navigate to the viewer for this lesson type
      context.pushReplacement(
        '/lessons/${widget.nodeId}/view',
        extra: {
          'lessonType': lessonType,
          'lessonData': lessonData,
          'title': title,
          'endQuiz': endQuiz,
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: _error != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: $_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => context.pop(), child: const Text('Quay lại')),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
