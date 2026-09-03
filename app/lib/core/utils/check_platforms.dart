import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class PlatformChecker {
  static bool isIOS() {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  static bool isAndroid() {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android;
  }

  static bool isWeb() {
    return kIsWeb;
  }

  static bool isLinux() {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.linux;
  }

  static bool isMacOS() {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.macOS;
  }

  static bool isWindows() {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.windows;
  }

  static bool isDesktop() {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      return false;
    }
    return true;
  }
}