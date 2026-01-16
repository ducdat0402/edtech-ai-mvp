import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/features/auth/screens/login_screen.dart';
import 'package:edtech_mobile/features/auth/screens/register_screen.dart';
import 'package:edtech_mobile/features/dashboard/screens/dashboard_screen.dart';
import 'package:edtech_mobile/features/onboarding/screens/onboarding_chat_screen.dart';
import 'package:edtech_mobile/features/placement_test/screens/placement_test_screen.dart';
import 'package:edtech_mobile/features/placement_test/screens/analysis_complete_screen.dart';
import 'package:edtech_mobile/features/subjects/screens/subject_intro_screen.dart';
import 'package:edtech_mobile/features/subjects/screens/subject_learning_goals_screen.dart';
import 'package:edtech_mobile/features/subjects/screens/personal_mind_map_screen.dart';
import 'package:edtech_mobile/features/domains/screens/domains_list_screen.dart';
import 'package:edtech_mobile/features/domains/screens/domain_detail_screen.dart';
import 'package:edtech_mobile/features/learning_nodes/screens/learning_node_map_screen.dart';
import 'package:edtech_mobile/features/learning_nodes/screens/node_detail_screen.dart';
import 'package:edtech_mobile/features/content/screens/content_viewer_screen.dart';
import 'package:edtech_mobile/features/content/screens/edit_lesson_screen.dart';
import 'package:edtech_mobile/features/content/screens/content_version_history_screen.dart';
import 'package:edtech_mobile/features/skill_tree/screens/skill_tree_screen.dart';
import 'package:edtech_mobile/features/quests/screens/daily_quests_screen.dart';
import 'package:edtech_mobile/features/leaderboard/screens/leaderboard_screen.dart';
import 'package:edtech_mobile/features/currency/screens/currency_screen.dart';
import 'package:edtech_mobile/features/profile/screens/profile_screen.dart';
import 'package:edtech_mobile/features/profile/screens/journey_log_screen.dart';
import 'package:edtech_mobile/features/admin/screens/admin_panel_screen.dart';

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
      path: '/subjects/:id/nodes',
      builder: (context, state) {
        final subjectId = state.pathParameters['id']!;
        return LearningNodeMapScreen(subjectId: subjectId);
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
      path: '/content/:id',
      builder: (context, state) {
        final contentId = state.pathParameters['id']!;
        // Use key to force widget rebuild when contentId changes
        return ContentViewerScreen(
          key: ValueKey(contentId),
          contentId: contentId,
        );
      },
    ),
    GoRoute(
      path: '/content/:id/edit',
      builder: (context, state) {
        final contentId = state.pathParameters['id']!;
        final initialData = state.extra as Map<String, dynamic>?;
        return EditLessonScreen(
          contentItemId: contentId,
          initialData: initialData,
        );
      },
    ),
    GoRoute(
      path: '/content/:id/versions',
      builder: (context, state) {
        final contentId = state.pathParameters['id']!;
        final isAdmin = state.uri.queryParameters['admin'] == 'true';
        return ContentVersionHistoryScreen(
          contentItemId: contentId,
          isAdmin: isAdmin,
        );
      },
    ),
    GoRoute(
      path: '/skill-tree',
      builder: (context, state) {
        final subjectId = state.uri.queryParameters['subjectId'];
        return SkillTreeScreen(subjectId: subjectId);
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
      ],
    ),
    GoRoute(
      path: '/admin/panel',
      builder: (context, state) => const AdminPanelScreen(),
    ),
  ],
);
