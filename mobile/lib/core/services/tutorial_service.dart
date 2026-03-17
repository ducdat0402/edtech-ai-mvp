import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static const _prefix = 'tutorial_seen_';

  static Future<bool> hasSeenTutorial(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$tutorialId') ?? false;
  }

  static Future<void> markTutorialSeen(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$tutorialId', true);
  }

  static Future<void> resetTutorial(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$tutorialId');
  }

  static Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  static const dashboardTutorial = 'dashboard';
  static const subjectIntroTutorial = 'subject_intro';
  static const personalMindMapTutorial = 'personal_mind_map';
  static const profileTutorial = 'profile';
}
