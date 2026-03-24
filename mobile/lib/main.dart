import 'package:flutter/material.dart';
import 'package:edtech_mobile/app/app.dart';
import 'package:edtech_mobile/core/api/api_client.dart';
import 'package:edtech_mobile/core/auth/auth_session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();
  final authSession = AuthSessionController();
  apiClient.onSessionInvalidated = () => authSession.setLoggedIn(false);
  await authSession.restoreFromStorage(apiClient);

  runApp(EdTechApp(apiClient: apiClient, authSession: authSession));
}
