import 'package:flutter/foundation.dart';
import 'package:open_at_login/core/app_launcher.dart';
import 'package:open_at_login/core/app_launcher_macos_impl.dart';
import 'package:open_at_login/core/app_launcher_windows_impl.dart';
import 'package:open_at_login/core/no_op_app_launcher.dart';

export 'package:open_at_login/core/app_launcher.dart';

/// Main interface for querying and controlling launch-at-login behavior.
///
/// Use [OpenAtLogin.instance] to access the singleton instance.
class OpenAtLogin {
  OpenAtLogin._();

  /// The singleton instance of [OpenAtLogin].
  static final OpenAtLogin instance = OpenAtLogin._();

  AppLauncher _appLauncher = const NoOpAppLauncher();
  bool _isInitialized = false;

  /// The active [AppLauncher] instance. Defaults to [NoOpAppLauncher] before
  /// [initialize] is called.
  AppLauncher get launcher => _appLauncher;

  /// Whether [initialize] has been called.
  bool get isInitialized => _isInitialized;

  /// Initializes the launch-at-login service for the current platform.
  ///
  /// - [appName]: The display or executable name of the application.
  /// - [appPath]: The absolute path to the application bundle or binary.
  /// - [args]: Optional arguments passed when launching the app at login.
  ///
  /// Supported platforms:
  /// - macOS: Uses `LaunchAtLogin-Modern` (`SMAppService.mainApp`).
  /// - Windows: Architecture slot prepared for upcoming native implementation.
  /// - All other platforms (Android, iOS, Linux, Web): Handled gracefully as
  ///   safe no-ops without throwing exceptions.
  void initialize({
    required String appName,
    required String appPath,
    List<String> args = const [],
  }) {
    _isInitialized = true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
        _appLauncher = MacOSAppLauncher(
          appName: appName,
          appPath: appPath,
          args: args,
        );
      case TargetPlatform.windows:
        _appLauncher = WindowsAppLauncher(
          appName: appName,
          appPath: appPath,
          args: args,
        );
      default:
        _appLauncher = const NoOpAppLauncher();
    }
  }

  /// Checks whether the application is configured to open automatically at login.
  ///
  /// Returns `false` on unsupported platforms or when called prior to [initialize].
  Future<bool> isEnabled() => _appLauncher.isEnabled();

  /// Enables or disables launching the application automatically at login.
  ///
  /// Safely no-ops on unsupported platforms or when called prior to [initialize].
  Future<void> setEnabled(bool enabled) => _appLauncher.setEnabled(enabled);

  /// Resets the internal launcher state. Intended for testing only.
  @visibleForTesting
  void reset() {
    _appLauncher = const NoOpAppLauncher();
    _isInitialized = false;
  }

  /// Sets a custom [AppLauncher] implementation. Intended for testing only.
  @visibleForTesting
  void setMockLauncher(AppLauncher launcher) {
    _appLauncher = launcher;
    _isInitialized = true;
  }
}
