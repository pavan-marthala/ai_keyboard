import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class DesktopPlatformChannelDataSource {
  static const MethodChannel _channel = MethodChannel(
    'com.pk.ai_keyboard/desktop',
  );

  Future<bool> isAccessibilityGranted() async {
    if (!Platform.isMacOS) return false;
    try {
      final bool? granted = await _channel.invokeMethod<bool>(
        'isAccessibilityGranted',
      );
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestAccessibility() async {
    if (!Platform.isMacOS) return false;
    try {
      final bool? result = await _channel.invokeMethod<bool>(
        'requestAccessibility',
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    if (!Platform.isMacOS) return;
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }

  Future<bool> isInputMonitoringGranted() async {
    if (!Platform.isMacOS) return false;
    try {
      final bool? granted = await _channel.invokeMethod<bool>(
        'isInputMonitoringGranted',
      );
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openInputMonitoringSettings() async {
    if (!Platform.isMacOS) return;
    try {
      await _channel.invokeMethod('openInputMonitoringSettings');
    } catch (_) {}
  }
}
