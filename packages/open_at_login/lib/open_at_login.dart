import 'package:flutter/foundation.dart';
import 'package:open_at_login/core/app_launcher.dart';
import 'package:open_at_login/core/app_launcher_macos_impl.dart';

export 'package:open_at_login/core/app_launcher.dart';

/// Main interface for querying and controlling launch-at-login behavior.
///
/// Use [OpenAtLogin.instance] to access the singleton instance.
class OpenAtLogin {
  OpenAtLogin._();

  /// The singleton instance of [OpenAtLogin].
  static final OpenAtLogin instance = OpenAtLogin._();

  AppLauncher? _appLauncher;

  /// The active [AppLauncher] instance configured during [initialize], or `null`
  /// if [initialize] has not been called yet.
  AppLauncher? get launcher => _appLauncher;

  /// Whether [initialize] has been called and an [AppLauncher] is active.
  bool get isInitialized => _appLauncher != null;

  /// Initializes the launch-at-login service for the current platform.
  ///
  /// - [appName]: The display or executable name of the application.
  /// - [appPath]: The absolute path to the application bundle or binary.
  /// - [args]: Optional arguments passed when launching the app at login.
  ///
  /// On macOS, [appName], [appPath], and [args] are retained for cross-platform
  /// consistency, while native macOS integration uses `LaunchAtLogin-Modern`
  /// (`SMAppService.mainApp`).
  ///
  /// Throws an [UnsupportedError] if called on an unsupported platform.
  void initialize({
    required String appName,
    required String appPath,
    List<String> args = const [],
  }) {
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      _appLauncher = AppLauncherMacOSImpl(
        appName: appName,
        appPath: appPath,
        args: args,
      );
    } else {
      throw UnsupportedError(
        'The OpenAtLogin package currently supports only macOS. '
        'Windows support is planned for an upcoming release.',
      );
    }
  }

  /// Checks whether the application is configured to open automatically at login.
  ///
  /// Throws a [StateError] if [initialize] has not been called.
  Future<bool> isEnabled() {
    final activeLauncher = _appLauncher;
    if (activeLauncher == null) {
      throw StateError(
        'OpenAtLogin has not been initialized. '
        'Please call OpenAtLogin.instance.initialize(...) before calling isEnabled().',
      );
    }
    return activeLauncher.isEnabled();
  }

  /// Enables or disables launching the application automatically at login.
  ///
  /// - [enabled]: `true` to register the application to launch at login;
  ///   `false` to unregister it.
  ///
  /// Throws a [StateError] if [initialize] has not been called.
  Future<void> setEnabled(bool enabled) {
    final activeLauncher = _appLauncher;
    if (activeLauncher == null) {
      throw StateError(
        'OpenAtLogin has not been initialized. '
        'Please call OpenAtLogin.instance.initialize(...) before calling setEnabled().',
      );
    }
    return activeLauncher.setEnabled(enabled);
  }

  /// Resets the internal launcher state. Intended for testing only.
  @visibleForTesting
  void reset() {
    _appLauncher = null;
  }

  /// Sets a custom [AppLauncher] implementation. Intended for testing only.
  @visibleForTesting
  void setMockLauncher(AppLauncher launcher) {
    _appLauncher = launcher;
  }
}
