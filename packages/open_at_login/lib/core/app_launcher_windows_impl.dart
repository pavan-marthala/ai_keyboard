import 'package:open_at_login/core/app_launcher.dart';

/// Windows implementation slot for [AppLauncher].
///
/// Native Windows launch-at-login will be implemented in the upcoming Windows phase.
/// Currently behaves safely as a non-crashing slot.
class WindowsAppLauncher extends AppLauncher {
  /// Creates a [WindowsAppLauncher] instance.
  const WindowsAppLauncher({
    required super.appName,
    required super.appPath,
    super.args = const [],
  });

  @override
  Future<bool> isEnabled() async {
    // Windows launch-at-login native implementation is pending for the Windows platform phase.
    return false;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    // Windows launch-at-login native implementation is pending for the Windows platform phase.
  }
}

/// Backwards compatibility alias for [WindowsAppLauncher].
typedef AppLauncherWindowsImpl = WindowsAppLauncher;
