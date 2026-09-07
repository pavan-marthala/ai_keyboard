import 'dart:io';

import 'package:open_at_login/core/app_lancher.dart';
import 'package:open_at_login/core/app_lancher_macos_impl.dart';

class OpenAtLogin {
  OpenAtLogin._();

  static final OpenAtLogin instance = OpenAtLogin._();

  late AppLauncher _appLauncher;

  void initialize({
    required String appName,
    required String appPath,
    List<String> args = const [],
  }) {
    if (Platform.isMacOS) {
      _appLauncher = AppLauncherImplMacOS(
        appName: appName,
        appPath: appPath,
        args: args,
      );
    } else {
      throw UnsupportedError(
        'The OpenAtLogin package currently supports only macOS. '
        'Please check the documentation for updates on other platforms.',
      );
    }
  }

  Future<bool> isEnabled() => _appLauncher.isEnabled();

  Future<void> setEnabled(bool enabled) => _appLauncher.setEnabled(enabled);
}
