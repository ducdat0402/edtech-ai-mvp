import 'package:shared_preferences/shared_preferences.dart';

/// Local-only role preview for admins.
///
/// Purpose: allow "View as Learner" UX without changing backend role.
/// Implementation: override `role` in the returned user profile map
/// when actual role is `admin` and preview is enabled.
class RolePreviewService {
  static const _adminPreviewLearnerKey = 'admin_preview_learner_v1';

  static bool _loaded = false;
  static bool _adminPreviewLearner = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _adminPreviewLearner = prefs.getBool(_adminPreviewLearnerKey) ?? false;
    _loaded = true;
  }

  static bool get adminPreviewLearnerEnabled => _adminPreviewLearner;

  static Future<void> setAdminPreviewLearnerEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adminPreviewLearnerKey, enabled);
    _adminPreviewLearner = enabled;
    _loaded = true;
  }

  static Map<String, dynamic> applyToProfile(Map<String, dynamic> profile) {
    final role = profile['role'];
    if (role == 'admin' && _adminPreviewLearner) {
      return {
        ...profile,
        'actualRole': 'admin',
        'role': 'user',
        'rolePreview': 'learner',
      };
    }
    return profile;
  }
}
