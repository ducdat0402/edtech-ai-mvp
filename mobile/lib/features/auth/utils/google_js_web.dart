// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;

typedef GoogleCredentialCallback = void Function(String idToken);

void startGoogleJsSignIn(
  String clientId,
  GoogleCredentialCallback onCredential,
  void Function(String message) onError,
) {
  // Listen for credential or error from JS
  late StreamSubscription<html.MessageEvent> sub;
  sub = html.window.onMessage.listen((event) {
    final data = event.data;
    if (data is Map) {
      final type = data['type'];
      if (type == 'google_credential') {
        sub.cancel();
        final cred = data['credential'] as String?;
        if (cred != null && cred.isNotEmpty) {
          onCredential(cred);
        } else {
          onError('Không nhận được credential từ Google');
        }
      } else if (type == 'google_error') {
        sub.cancel();
        onError((data['message'] ?? 'Đăng nhập Google thất bại').toString());
      }
    }
  });

  html.window.postMessage(
    <String, Object?>{
      'type': 'start_google',
      'clientId': clientId,
    },
    '*',
  );
}

