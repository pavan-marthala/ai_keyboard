import 'dart:io' show Platform;

import 'package:atfix/core/utils/check_platforms.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/desktop_capability.dart';

@lazySingleton
class DesktopPlatformChannelDataSource {
  static const MethodChannel _channel = MethodChannel('com.pk.atfix/desktop');

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

  Future<DesktopCapabilityStatus> getInputMonitoringStatus() async {
    if (!Platform.isMacOS) return DesktopCapabilityStatus.notConfigured;
    try {
      final String? status = await _channel.invokeMethod<String>(
        'getInputMonitoringStatus',
      );
      switch (status) {
        case 'granted':
          return DesktopCapabilityStatus.enabled;
        case 'denied':
          return DesktopCapabilityStatus.required;
        case 'unknown':
        default:
          return DesktopCapabilityStatus.unknown;
      }
    } catch (_) {
      return DesktopCapabilityStatus.unknown;
    }
  }

  Future<bool> isInputMonitoringGranted() async {
    final status = await getInputMonitoringStatus();
    return status == DesktopCapabilityStatus.enabled;
  }

  Future<void> openInputMonitoringSettings() async {
    if (!Platform.isMacOS) return;
    try {
      await _channel.invokeMethod('openInputMonitoringSettings');
    } catch (_) {}
  }

  Future<bool> registerHotkey(Map<String, dynamic> shortcutJson) async {
    if (!PlatformChecker.isMacOS() && !PlatformChecker.isWindows()) return false;
    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'registerHotkey',
        shortcutJson,
      );
      return success ?? false;
    } on MissingPluginException {
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getRegisteredHotkey() async {
    if (!PlatformChecker.isMacOS() && !PlatformChecker.isWindows()) return null;
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getHotkey',
      );
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<void> quitAtFixCompletely() async {
    if (!PlatformChecker.isMacOS() && !PlatformChecker.isWindows()) return;
    try {
      await _channel.invokeMethod('quitAtFixCompletely');
    } catch (_) {}
  }
}

