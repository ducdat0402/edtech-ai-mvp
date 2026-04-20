import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/api/api_client.dart';
import 'package:edtech_mobile/core/auth/auth_session_controller.dart';
import 'package:edtech_mobile/core/onboarding/onboarding_resume_controller.dart';
import 'package:edtech_mobile/core/services/auth_service.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/services/dm_socket_service.dart';
import 'package:edtech_mobile/core/services/theme_mode_service.dart';
import 'package:edtech_mobile/features/dashboard/screens/dashboard_screen.dart';
import 'package:edtech_mobile/app/routes.dart';
import 'package:edtech_mobile/theme/theme.dart';

class EdTechApp extends StatefulWidget {
  final ApiClient apiClient;
  final AuthSessionController authSession;
  final OnboardingResumeController onboardingResume;

  const EdTechApp({
    super.key,
    required this.apiClient,
    required this.authSession,
    required this.onboardingResume,
  });

  @override
  State<EdTechApp> createState() => _EdTechAppState();
}

class _EdTechAppState extends State<EdTechApp> {
  late final GoRouter _router;
  final ThemeModeService _themeModeService = ThemeModeService();

  @override
  void initState() {
    super.initState();
    widget.apiClient.onSessionInvalidated = () {
      DashboardScreen.clearMemoryCache();
      Future.microtask(() async {
        await widget.onboardingResume.clearOnboardingFlow();
        widget.authSession.setLoggedIn(false);
      });
    };
    _router = createAppRouter(widget.authSession, widget.onboardingResume);
    _themeModeService.load();
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService(widget.apiClient, widget.authSession);
    final apiService = ApiService(widget.apiClient);
    final dmSocketService = DmSocketService();

    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: widget.apiClient),
        Provider<AuthService>.value(value: authService),
        Provider<ApiService>.value(value: apiService),
        Provider<DmSocketService>.value(value: dmSocketService),
        ChangeNotifierProvider<OnboardingResumeController>.value(
          value: widget.onboardingResume,
        ),
        ChangeNotifierProvider<ThemeModeService>.value(
            value: _themeModeService),
      ],
      child: Consumer<ThemeModeService>(
        builder: (context, themeService, _) => MaterialApp.router(
          title: 'Gamistu',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          routerConfig: _router,
        ),
      ),
    );
  }
}
