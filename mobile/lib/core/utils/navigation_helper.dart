import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Helper class for safe navigation with go_router
class NavigationHelper {
  /// Safely pop the current route
  /// If cannot pop, navigates to dashboard as fallback
  static void safePop(BuildContext context, {String? fallbackRoute}) {
    try {
      if (context.canPop()) {
        context.pop();
      } else {
        // If cannot pop, navigate to fallback route or dashboard
        final route = fallbackRoute ?? '/dashboard';
        context.go(route);
      }
    } catch (e) {
      // If pop fails, navigate to fallback route or dashboard
      print('⚠️ Navigation error: $e');
      final route = fallbackRoute ?? '/dashboard';
      context.go(route);
    }
  }

  /// Pop with result
  static void safePopWithResult<T>(BuildContext context, T result, {String? fallbackRoute}) {
    try {
      if (context.canPop()) {
        context.pop(result);
      } else {
        final route = fallbackRoute ?? '/dashboard';
        context.go(route);
      }
    } catch (e) {
      print('⚠️ Navigation error: $e');
      final route = fallbackRoute ?? '/dashboard';
      context.go(route);
    }
  }
}

