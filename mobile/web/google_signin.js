window.addEventListener('message', function (event) {
  var data = event.data;
  if (!data || data.type !== 'start_google') return;

  var clientId = data.clientId;
  if (!clientId) {
    window.postMessage(
      { type: 'google_error', message: 'Thiếu clientId cho Google Sign-In' },
      '*'
    );
    return;
  }

  if (!window.google || !google.accounts || !google.accounts.id) {
    window.postMessage(
      { type: 'google_error', message: 'Google Identity script chưa load' },
      '*'
    );
    return;
  }

  try {
    google.accounts.id.initialize({
      client_id: clientId,
      callback: function (response) {
        if (response && response.credential) {
          window.postMessage(
            { type: 'google_credential', credential: response.credential },
            '*'
          );
        } else {
          window.postMessage(
            { type: 'google_error', message: 'Không nhận được credential' },
            '*'
          );
        }
      },
    });

    google.accounts.id.prompt(function (notification) {
      if (notification.isNotDisplayed() || notification.isSkippedMoment()) {
        // User closed or it was not displayed; no-op.
        // We don't treat this as an error so that user can try again.
      }
    });
  } catch (e) {
    window.postMessage(
      { type: 'google_error', message: 'Lỗi khởi tạo Google: ' + e },
      '*'
    );
  }
});

