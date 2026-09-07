import 'package:flutter/services.dart';
import 'package:open_at_login/core/app_launcher.dart';

/// Windows implementation of [AppLauncher] communicating with native Windows C++ plugin
/// via Flutter [MethodChannel].
///
/// Under the hood, native Windows code connects to the Windows Registry:
/// `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run`.
class WindowsAppLauncher extends AppLauncher {
  /// Creates a [WindowsAppLauncher] instance.
  const WindowsAppLauncher({
    required super.appName,
    required super.appPath,
    super.args = const [],
  });

  /// MethodChannel identifier for `open_at_login`.
  static const MethodChannel _channel = MethodChannel('open_at_login');

  @override
  Future<bool> isEnabled() async {
    final result = await _channel.invokeMethod<bool>('isOpenAtLoginEnabled', {
      'appName': appName,
      'appPath': appPath,
    });

    return result ?? false;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      if (appName.trim().isEmpty) {
        throw ArgumentError.value(
          appName,
          'appName',
          'appName cannot be empty when enabling launch at login on Windows',
        );
      }
      if (appPath.trim().isEmpty) {
        throw ArgumentError.value(
          appPath,
          'appPath',
          'appPath cannot be empty when enabling launch at login on Windows',
        );
      }
    }

    await _channel.invokeMethod<void>('setOpenAtLoginEnabled', {
      'enabled': enabled,
      'appName': appName,
      'appPath': appPath,
      'args': args,
    });
  }
}

/// Backwards compatibility alias for [WindowsAppLauncher].
typedef AppLauncherWindowsImpl = WindowsAppLauncher;
