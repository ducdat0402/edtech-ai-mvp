import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ghi nhớ user đang làm onboarding (slide + pending) để sau khi thoát/tải lại app
/// vẫn mở `/onboarding` thay vì về dashboard.
class OnboardingResumeController extends ChangeNotifier {
  OnboardingResumeController._();

  static const prefsKeyPending = 'onboarding_flow_pending';
  static const prefsKeySlide = 'onboarding_slide_index';

  bool _pending = false;
  int _savedSlideIndex = 0;

  bool get isPending => _pending;

  /// Slide đã lưu (0-based), dùng làm `initialPage` cho PageView.
  int get savedSlideIndex => _savedSlideIndex;

  static Future<OnboardingResumeController> load() async {
    final p = await SharedPreferences.getInstance();
    final c = OnboardingResumeController._();
    c._pending = p.getBool(prefsKeyPending) ?? false;
    c._savedSlideIndex = p.getInt(prefsKeySlide) ?? 0;
    return c;
  }

  Future<void> setPending(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKeyPending, value);
    if (_pending != value) {
      _pending = value;
      notifyListeners();
    }
  }

  Future<void> persistSlideIndex(int page) async {
    _savedSlideIndex = page;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefsKeySlide, page);
  }

  /// Gọi khi user hoàn thành / thoát onboarding (về dashboard, vào bài học, hoặc hủy về login).
  Future<void> clearOnboardingFlow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKeyPending, false);
    await prefs.remove(prefsKeySlide);
    _pending = false;
    _savedSlideIndex = 0;
    notifyListeners();
  }
}

/// Sau đăng nhập: vào onboarding nếu trước đó đang làm dở, không thì dashboard.
void goHomeAfterAuth(BuildContext context) {
  final pending =
      context.read<OnboardingResumeController>().isPending;
  context.go(pending ? '/onboarding' : '/dashboard');
}
