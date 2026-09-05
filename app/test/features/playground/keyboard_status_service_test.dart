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
      'isAtFIxActive returns false safely on non-Android test environment',
      () async {
        final isActive = await service.isAtFIxActive();
        expect(isActive, isFalse);
      },
    );

    test('getCurrentInputMethod handles platform call gracefully', () async {
      final ime = await service.getCurrentInputMethod();
      expect(ime, isNotNull);
    });
  });
}
