import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'ai_user_preferences.dart';
import 'api_service.dart';

/// Fire-and-forget calls to [ApiService.trackAiBehavior] so UI never blocks.
class AiBehaviorTracker {
  AiBehaviorTracker._();

  static void fireAndForget(
    ApiService api, {
    required String nodeId,
    required String action,
    Map<String, dynamic>? metrics,
    Map<String, dynamic>? context,
    String? contentItemId,
  }) {
    if (!AiUserPreferences.instance.behaviorTrackingEnabled) {
      return;
    }
    Future<void>(() async {
      try {
        await api.trackAiBehavior(
          nodeId: nodeId,
          action: action,
          metrics: metrics,
          context: context,
          contentItemId: contentItemId,
        );
      } catch (e, st) {
        debugPrint('[AiBehaviorTracker] ignored: $e\n$st');
      }
    });
  }

  /// After first frame when [context] can read [Provider<ApiService>].
  static void trackLessonScreenOpened(
    BuildContext context, {
    required String nodeId,
    required String screenName,
    String? lessonType,
  }) {
    if (!AiUserPreferences.instance.behaviorTrackingEnabled) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final api = Provider.of<ApiService>(context, listen: false);
      fireAndForget(
        api,
        nodeId: nodeId,
        action: 'view',
        context: {
          'screen': screenName,
          if (lessonType != null && lessonType.isNotEmpty)
            'lessonType': lessonType,
        },
      );
    });
  }
}
