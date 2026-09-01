import 'dart:io';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class KeyboardStatusService {
  static const _channel = MethodChannel('com.pk.ai_keyboard/keyboard');

  Future<bool> isAiKeyboardActive() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool isActive = await _channel.invokeMethod('isAiKeyboardActive');
      return isActive;
    } catch (_) {
      return false;
    }
  }

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
}
