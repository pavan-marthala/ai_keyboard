import 'package:open_at_login/core/app_launcher.dart';

/// No-op implementation of [AppLauncher] for unsupported platforms
/// and as the safe default before [OpenAtLogin.initialize] is called.
class NoOpAppLauncher extends AppLauncher {
  /// Creates a [NoOpAppLauncher] instance.
  const NoOpAppLauncher({
    super.appName = '',
    super.appPath = '',
    super.args = const [],
  });

  @override
  Future<bool> isEnabled() async => false;

  @override
  Future<void> setEnabled(bool enabled) async {
    // Graceful no-op on unsupported platforms or when uninitialized.
  }
}
