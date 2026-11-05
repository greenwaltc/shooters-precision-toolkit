import 'package:web/web.dart' as web;

/// FlutterFire 6.3.0 restores this marker only on localhost, yet skips connecting
/// whenever it already exists. Hot restart on 127.0.0.1 leaves a fresh JS Auth
/// instance disconnected. Clear only the connection hint so it must reconnect.
/// This does not remove accounts, auth credentials, or other browser storage.
void clearAuthEmulatorHint(String appName) {
  web.window.sessionStorage.removeItem('$appName-firebaseEmulatorOrigin');
}
