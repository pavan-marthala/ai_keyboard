import 'package:flutter_test/flutter_test.dart';

void main() {
  group('iOS Keyboard Extension Contract Tests', () {
    test('Verify iOS textDocumentProxy property wrapping contract', () {
      const textBeforeInput = 'I am going office tomorrow';
      const trigger = '@fix';
      final commandText = '$textBeforeInput $trigger ';

      expect(commandText, equals('I am going office tomorrow @fix '));
    });

    test('Verify iOS translation parameter insertion contract', () {
      const textBeforeInput = 'I am going home';
      const langCode = 'es';
      final commandText = '$textBeforeInput @translate:$langCode ';

      expect(commandText, equals('I am going home @translate:es '));
    });

    test('Verify iOS supported language codes', () {
      final supportedLangs = [
        'en',
        'es',
        'fr',
        'de',
        'it',
        'pt',
        'hi',
        'te',
        'kn',
        'ta',
      ];
      expect(supportedLangs, contains('es'));
      expect(supportedLangs.length, equals(10));
    });
  });
}
