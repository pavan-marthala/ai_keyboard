import 'package:ai_keyboard/features/ai_service/domain/entities/ai_model.dart';
import 'package:ai_keyboard/features/settings/domain/entities/ai_provider_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiModel Unit Tests', () {
    test('should construct AiModel correctly with defaults', () {
      const model = AiModel(
        id: 'gemini-1.5-flash',
        displayName: 'Gemini 1.5 Flash',
        provider: AiProviderType.gemini,
      );

      expect(model.id, equals('gemini-1.5-flash'));
      expect(model.displayName, equals('Gemini 1.5 Flash'));
      expect(model.provider, equals(AiProviderType.gemini));
      expect(model.capabilities, isEmpty);
    });

    test('should serialize and deserialize AiModel JSON correctly', () {
      const model = AiModel(
        id: 'llama-3.3-70b-versatile',
        displayName: 'Llama 3.3 70B Versatile',
        provider: AiProviderType.groq,
        description: 'Fast open source model',
        capabilities: ['text-generation', 'chat'],
      );

      final json = model.toJson();
      final deserialized = AiModel.fromJson(json);

      expect(deserialized.id, equals(model.id));
      expect(deserialized.displayName, equals(model.displayName));
      expect(deserialized.provider, equals(model.provider));
      expect(deserialized.capabilities, contains('chat'));
    });
  });
}
