import 'package:flutter/services.dart';
import 'package:open_at_login/core/app_launcher.dart';

/// macOS implementation of [AppLauncher] communicating with native Swift code
/// via Flutter [MethodChannel].
///
/// Under the hood, native macOS code connects to `LaunchAtLogin-Modern`
/// (`SMAppService.mainApp`).
class AppLauncherMacOSImpl extends AppLauncher {
  /// Creates an [AppLauncherMacOSImpl] instance.
  ///
  /// Note: [appName], [appPath], and [args] are retained for architectural
  /// consistency across platforms, though macOS `LaunchAtLogin-Modern` operates
  /// directly on the application's bundle identifier.
  const AppLauncherMacOSImpl({
    required super.appName,
    required super.appPath,
    super.args = const [],
  });

  /// MethodChannel identifier for `open_at_login`.
  static const MethodChannel _channel = MethodChannel('open_at_login');

  @override
  Future<bool> isEnabled() async {
    final result = await _channel.invokeMethod<bool>('isOpenAtLoginEnabled');

    if (result == null) {
      throw StateError(
        'The native macOS implementation returned null for "isOpenAtLoginEnabled". '
        'Expected a non-null boolean value.',
      );
    }

    return result;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    await _channel.invokeMethod<void>('setOpenAtLoginEnabled', {
      'enabled': enabled,
    });
  }
}
