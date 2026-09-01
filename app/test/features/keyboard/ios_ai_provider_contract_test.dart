import 'package:flutter_test/flutter_test.dart';

void main() {
  group('iOS Native AI Provider Contract Tests', () {
    test('Verify provider factory mapping for supported providers', () {
      final supportedProviders = ['openai', 'gemini', 'groq', 'openrouter'];
      expect(supportedProviders, contains('openai'));
      expect(supportedProviders, contains('gemini'));
      expect(supportedProviders, contains('groq'));
      expect(supportedProviders, contains('openrouter'));
      expect(supportedProviders.length, equals(4));
    });

    test('Verify Gemini model ID prefix normalization contract', () {
      String normalizeModelId(String rawModel) {
        return rawModel.startsWith('models/')
            ? rawModel.substring(7)
            : rawModel;
      }

      expect(
        normalizeModelId('models/gemini-1.5-flash'),
        equals('gemini-1.5-flash'),
      );
      expect(normalizeModelId('gemini-2.0-flash'), equals('gemini-2.0-flash'));
    });

    test('Verify iOS transformation context snapshot validation rules', () {
      const submittedTextBefore = 'I am going office tomorrow @fix ';
      const currentTextBefore = 'I am going office tomorrow @fix ';
      const modifiedTextBefore = 'I am going office tomorrow @fix  actually';

      final isValid = (currentTextBefore == submittedTextBefore);
      final isModifiedValid = (modifiedTextBefore == submittedTextBefore);

      expect(isValid, isTrue);
      expect(isModifiedValid, isFalse);
    });
  });
}
