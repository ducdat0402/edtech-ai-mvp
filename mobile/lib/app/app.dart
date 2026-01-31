import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/api/api_client.dart';
import 'package:edtech_mobile/core/services/auth_service.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/app/routes.dart';
import 'package:edtech_mobile/theme/theme.dart';

class EdTechApp extends StatelessWidget {
  const EdTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services
    final apiClient = ApiClient();
    final authService = AuthService(apiClient);
    final apiService = ApiService(apiClient);

    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthService>.value(value: authService),
        Provider<ApiService>.value(value: apiService),
      ],
      child: MaterialApp.router(
        title: 'EdTech AI MVP',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme, // Cyberpunk Dark Theme
        routerConfig: appRouter,
      ),
    );
  }
}

