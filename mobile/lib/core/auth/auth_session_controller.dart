import 'package:flutter/foundation.dart';
import 'package:edtech_mobile/core/api/api_client.dart';

/// Đồng bộ trạng thái đăng nhập với GoRouter (refreshListenable).
class AuthSessionController extends ChangeNotifier {
  AuthSessionController();

  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  /// Khôi phục từ secure storage (gọi ở main trước runApp).
  Future<void> restoreFromStorage(ApiClient api) async {
    _isLoggedIn = await api.hasValidStoredSession();
    notifyListeners();
  }

  void setLoggedIn(bool value) {
    if (_isLoggedIn == value) return;
    _isLoggedIn = value;
    notifyListeners();
  }
}
