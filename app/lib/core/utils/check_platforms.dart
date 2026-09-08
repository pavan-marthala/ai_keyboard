import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class PlatformChecker {
  static bool isIOS() {
    if (kIsWeb) {
      return false;
    }
    if (debugDefaultTargetPlatformOverride != null) {
      return debugDefaultTargetPlatformOverride == TargetPlatform.iOS;
    }
    return Platform.isIOS;
  }

  static bool isAndroid() {
    if (kIsWeb) {
      return false;
    }
    if (debugDefaultTargetPlatformOverride != null) {
      return debugDefaultTargetPlatformOverride == TargetPlatform.android;
    }
    return Platform.isAndroid;
  }

  static bool isWeb() {
    return kIsWeb;
  }

  static bool isLinux() {
    if (kIsWeb) {
      return false;
    }
    if (debugDefaultTargetPlatformOverride != null) {
      return debugDefaultTargetPlatformOverride == TargetPlatform.linux;
    }
    return Platform.isLinux;
  }

  static bool isMacOS() {
    if (kIsWeb) {
      return false;
    }
    if (debugDefaultTargetPlatformOverride != null) {
      return debugDefaultTargetPlatformOverride == TargetPlatform.macOS;
    }
    return Platform.isMacOS;
  }

  static bool isWindows() {
    if (kIsWeb) {
      return false;
    }
    if (debugDefaultTargetPlatformOverride != null) {
      return debugDefaultTargetPlatformOverride == TargetPlatform.windows;
    }
    return Platform.isWindows;
  }

  static bool isDesktop() {
    if (kIsWeb) {
      return false;
    }
    if (debugDefaultTargetPlatformOverride != null) {
      return debugDefaultTargetPlatformOverride == TargetPlatform.macOS ||
          debugDefaultTargetPlatformOverride == TargetPlatform.windows ||
          debugDefaultTargetPlatformOverride == TargetPlatform.linux;
    }
    if (Platform.isAndroid || Platform.isIOS) {
      return false;
    }
    return true;
  }
}
