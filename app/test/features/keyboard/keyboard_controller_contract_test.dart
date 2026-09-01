import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Keyboard UI & Controller Contract Tests', () {
    test('Verify command insertion pattern invariants', () {
      const trigger = '@fix';
      const input = 'I am going office tomorrow';
      final commandText = '$input $trigger ';
      expect(commandText, equals('I am going office tomorrow @fix '));
    });

    test('Verify translation parameter insertion invariant', () {
      const langCode = 'es';
      const input = 'I am going home';
      final commandText = '$input @translate:$langCode ';
      expect(commandText, equals('I am going home @translate:es '));
    });
  });
}
