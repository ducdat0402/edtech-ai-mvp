import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/features/auth/screens/login_screen.dart';
import 'package:edtech_mobile/features/auth/screens/register_screen.dart';
import 'package:edtech_mobile/features/dashboard/screens/dashboard_screen.dart';
import 'package:edtech_mobile/features/onboarding/screens/onboarding_chat_screen.dart';
import 'package:edtech_mobile/features/placement_test/screens/placement_test_screen.dart';
import 'package:edtech_mobile/features/placement_test/screens/analysis_complete_screen.dart';
import 'package:edtech_mobile/features/subjects/screens/subject_intro_screen.dart';
import 'package:edtech_mobile/features/learning_nodes/screens/learning_node_map_screen.dart';
import 'package:edtech_mobile/features/learning_nodes/screens/node_detail_screen.dart';
import 'package:edtech_mobile/features/content/screens/content_viewer_screen.dart';
import 'package:edtech_mobile/features/roadmap/screens/roadmap_screen.dart';
import 'package:edtech_mobile/features/skill_tree/screens/skill_tree_screen.dart';
import 'package:edtech_mobile/features/quests/screens/daily_quests_screen.dart';
import 'package:edtech_mobile/features/leaderboard/screens/leaderboard_screen.dart';
import 'package:edtech_mobile/features/profile/screens/profile_screen.dart';
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
      path: '/subjects/:id/nodes',
      builder: (context, state) {
        final subjectId = state.pathParameters['id']!;
        return LearningNodeMapScreen(subjectId: subjectId);
      },
    ),
    GoRoute(
      path: '/nodes/:id',
      builder: (context, state) {
        final nodeId = state.pathParameters['id']!;
        return NodeDetailScreen(nodeId: nodeId);
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
      path: '/roadmap',
      builder: (context, state) {
        final subjectId = state.uri.queryParameters['subjectId'];
        return RoadmapScreen(subjectId: subjectId);
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
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/admin/panel',
      builder: (context, state) => const AdminPanelScreen(),
    ),
  ],
);
