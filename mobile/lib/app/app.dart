import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/api/api_client.dart';
import 'package:edtech_mobile/core/auth/auth_session_controller.dart';
import 'package:edtech_mobile/core/services/auth_service.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/services/dm_socket_service.dart';
import 'package:edtech_mobile/app/routes.dart';
import 'package:edtech_mobile/theme/theme.dart';

class EdTechApp extends StatefulWidget {
  final ApiClient apiClient;
  final AuthSessionController authSession;

  const EdTechApp({
    super.key,
    required this.apiClient,
    required this.authSession,
  });

  @override
  State<EdTechApp> createState() => _EdTechAppState();
}

class _EdTechAppState extends State<EdTechApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(widget.authSession);
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
      ],
      child: MaterialApp.router(
        title: 'EdTech AI MVP',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: _router,
      ),
    );
  }
}
