import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/features/auth/screens/login_screen.dart';
import 'package:edtech_mobile/features/auth/screens/register_screen.dart';
import 'package:edtech_mobile/features/dashboard/screens/dashboard_screen.dart';
import 'package:edtech_mobile/features/onboarding/screens/onboarding_chat_screen.dart';
import 'package:edtech_mobile/features/placement_test/screens/placement_test_screen.dart';

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
  ],
);
