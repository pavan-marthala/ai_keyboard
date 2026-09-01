import 'package:ai_keyboard/features/playground/data/services/keyboard_status_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late KeyboardStatusService service;

  setUp(() {
    service = KeyboardStatusService();
  });

  group('KeyboardStatusService Tests', () {
    test(
      'isAiKeyboardActive returns false safely on non-Android test environment',
      () async {
        final isActive = await service.isAiKeyboardActive();
        expect(isActive, isFalse);
      },
    );

    test('getCurrentInputMethod handles platform call gracefully', () async {
      final ime = await service.getCurrentInputMethod();
      expect(ime, isNotNull);
    });
  });
}
