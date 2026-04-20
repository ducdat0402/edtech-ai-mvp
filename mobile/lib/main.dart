import 'package:flutter/material.dart';
import 'package:edtech_mobile/app/app.dart';
import 'package:edtech_mobile/core/api/api_client.dart';
import 'package:edtech_mobile/core/auth/auth_session_controller.dart';
import 'package:edtech_mobile/core/onboarding/onboarding_resume_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();
  final authSession = AuthSessionController();
  final onboardingResume = await OnboardingResumeController.load();
  try {
    await authSession.restoreFromStorage(apiClient);
  } catch (_) {
    authSession.setLoggedIn(false);
  }

  runApp(EdTechApp(
    apiClient: apiClient,
    authSession: authSession,
    onboardingResume: onboardingResume,
  ));
}
