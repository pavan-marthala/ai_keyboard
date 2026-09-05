import 'dart:io';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class KeyboardStatusService {
  static const _channel = MethodChannel('com.pk.atfix/keyboard');

  Future<bool> isAtFixActive() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool isActive = await _channel.invokeMethod('isAtFixActive');
      return isActive;
    } catch (_) {
      try {
        final bool fallback = await _channel.invokeMethod('isAtFixActive');
        return fallback;
      } catch (_) {
        return false;
      }
    }
  }

  @Deprecated('Use isAtFixActive instead')
  Future<bool> isAtFIxActive() => isAtFixActive();

  Future<String> getCurrentInputMethod() async {
    if (!Platform.isAndroid) return 'Unsupported Platform';
    try {
      final String ime = await _channel.invokeMethod('getCurrentInputMethod');
      return ime;
    } catch (_) {
      return '';
    }
  }

  Future<void> openKeyboardSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openKeyboardSettings');
    } catch (_) {}
  }

  Future<int> getKeyboardHeight() async {
    try {
      final int? height = await _channel.invokeMethod<int>('getKeyboardHeight');
      return height ?? 216;
    } catch (_) {
      return 216;
    }
  }

  Future<int> setKeyboardHeight(int height) async {
    try {
      final int? appliedHeight = await _channel.invokeMethod<int>(
        'setKeyboardHeight',
        {'height': height},
      );
      return appliedHeight ?? height;
    } catch (_) {
      return height;
    }
  }

  Future<int> resetKeyboardHeight() async {
    try {
      final int? defaultHeight = await _channel.invokeMethod<int>(
        'resetKeyboardHeight',
      );
      return defaultHeight ?? 216;
    } catch (_) {
      return 216;
    }
  }

  Future<bool> getUseNumbers() async {
    try {
      final bool? enabled = await _channel.invokeMethod<bool>('getUseNumbers');
      return enabled ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setUseNumbers(bool enabled) async {
    try {
      final bool? applied = await _channel.invokeMethod<bool>('setUseNumbers', {
        'useNumbers': enabled,
      });
      return applied ?? enabled;
    } catch (_) {
      return enabled;
    }
  }
}
