typedef GoogleCredentialCallback = void Function(String idToken);

void startGoogleJsSignIn(
  String clientId,
  GoogleCredentialCallback onCredential,
  void Function(String message) onError,
) {
  onError('Google JS sign-in is not supported on this platform.');
}

