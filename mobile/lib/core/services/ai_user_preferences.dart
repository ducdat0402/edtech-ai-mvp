import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase 5: learner controls for AI features (privacy, cost).
class AiUserPreferences extends ChangeNotifier {
  AiUserPreferences._();
  static final AiUserPreferences instance = AiUserPreferences._();

  static const _kBehaviorTracking = 'ai_behavior_tracking_enabled';
  static const _kCloudAi = 'ai_cloud_features_enabled';

  bool _behaviorTrackingEnabled = true;
  bool _cloudAiEnabled = true;

  bool get behaviorTrackingEnabled => _behaviorTrackingEnabled;
  bool get cloudAiEnabled => _cloudAiEnabled;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _behaviorTrackingEnabled = p.getBool(_kBehaviorTracking) ?? true;
    _cloudAiEnabled = p.getBool(_kCloudAi) ?? true;
    notifyListeners();
  }

  Future<void> setBehaviorTrackingEnabled(bool value) async {
    _behaviorTrackingEnabled = value;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kBehaviorTracking, value);
    notifyListeners();
  }

  Future<void> setCloudAiEnabled(bool value) async {
    _cloudAiEnabled = value;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kCloudAi, value);
    notifyListeners();
  }
}
