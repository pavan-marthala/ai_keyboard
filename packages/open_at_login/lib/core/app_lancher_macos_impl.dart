import 'package:flutter/services.dart';
import 'package:open_at_login/core/app_lancher.dart';

class AppLauncherImplMacOS extends AppLauncher {
  AppLauncherImplMacOS({
    required super.appName,
    required super.appPath,
    super.args,
  });

  static const MethodChannel _platform = MethodChannel('open_at_login');

  @override
  Future<bool> isEnabled() async {
    try {
      final result = await _platform.invokeMethod<bool>('isOpenAtLoginEnabled');

      if (result == null) {
        throw StateError(
          'The native macOS implementation returned null '
          'for "isOpenAtLoginEnabled". Expected a boolean value.',
        );
      }

      return result;
    } on PlatformException catch (e) {
      throw Exception(
        'Failed to check whether the app is enabled to open at login. '
        'Code: ${e.code}, Message: ${e.message ?? 'Unknown error'}',
      );
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    try {
      await _platform.invokeMethod<void>('setOpenAtLoginEnabled', {
        'enabled': enabled,
      });
    } on PlatformException catch (e) {
      throw Exception(
        'Failed to ${enabled ? 'enable' : 'disable'} '
        'opening the app at login. '
        'Code: ${e.code}, Message: ${e.message ?? 'Unknown error'}',
      );
    }
  }
}
