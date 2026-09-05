import 'package:atfix/features/playground/data/services/keyboard_status_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KeyboardStatusService Height MethodChannel Tests', () {
    const channel = MethodChannel('com.pk.atfix/keyboard');
    late KeyboardStatusService service;
    int currentHeight = 216;

    setUp(() {
      service = KeyboardStatusService();
      currentHeight = 216;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            switch (methodCall.method) {
              case 'getKeyboardHeight':
                return currentHeight;
              case 'setKeyboardHeight':
                final Map<dynamic, dynamic> args =
                    methodCall.arguments as Map<dynamic, dynamic>;
                final int h = args['height'] as int;
                currentHeight = h.clamp(150, 350);
                return currentHeight;
              case 'resetKeyboardHeight':
                currentHeight = 216;
                return 216;
              default:
                return null;
            }
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('getKeyboardHeight returns initial default height', () async {
      final height = await service.getKeyboardHeight();
      expect(height, equals(216));
    });

    test('setKeyboardHeight updates and returns sanitized height', () async {
      final updated = await service.setKeyboardHeight(280);
      expect(updated, equals(280));

      final fetched = await service.getKeyboardHeight();
      expect(fetched, equals(280));
    });

    test('setKeyboardHeight clamps height below minimum', () async {
      final clamped = await service.setKeyboardHeight(100);
      expect(clamped, equals(150));
    });

    test('setKeyboardHeight clamps height above maximum', () async {
      final clamped = await service.setKeyboardHeight(400);
      expect(clamped, equals(350));
    });

    test('resetKeyboardHeight restores default height', () async {
      await service.setKeyboardHeight(300);
      expect(await service.getKeyboardHeight(), equals(300));

      final reset = await service.resetKeyboardHeight();
      expect(reset, equals(216));
      expect(await service.getKeyboardHeight(), equals(216));
    });

    test(
      'getUseNumbers returns false by default and setUseNumbers updates state',
      () async {
        bool useNumbers = false;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
              switch (methodCall.method) {
                case 'getUseNumbers':
                  return useNumbers;
                case 'setUseNumbers':
                  final args = methodCall.arguments as Map<dynamic, dynamic>;
                  useNumbers = args['useNumbers'] as bool;
                  return useNumbers;
                default:
                  return null;
              }
            });

        expect(await service.getUseNumbers(), equals(false));
        expect(await service.setUseNumbers(true), equals(true));
        expect(await service.getUseNumbers(), equals(true));
      },
    );
  });
}
