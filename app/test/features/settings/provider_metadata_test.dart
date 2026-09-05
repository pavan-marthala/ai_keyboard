import 'package:atfix/features/settings/domain/entities/ai_provider_metadata.dart';
import 'package:atfix/features/settings/domain/entities/ai_provider_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiProviderMetadata Tests', () {
    test('should contain metadata for all 4 providers', () {
      expect(AiProviderMetadata.allProviders.length, equals(4));

      final types = AiProviderMetadata.allProviders.map((m) => m.type).toList();
      expect(
        types,
        containsAll([
          AiProviderType.openAi,
          AiProviderType.gemini,
          AiProviderType.openRouter,
          AiProviderType.groq,
        ]),
      );
    });

    test(
      'every provider metadata should have valid display name and official URL',
      () {
        for (final metadata in AiProviderMetadata.allProviders) {
          expect(metadata.displayName, isNotEmpty);
          expect(metadata.apiKeyUrl, startsWith('https://'));
          expect(metadata.description, isNotEmpty);
        }
      },
    );

    test('getForType should return exact metadata for requested provider', () {
      final geminiMeta = AiProviderMetadata.getForType(AiProviderType.gemini);
      expect(geminiMeta.displayName, equals('Google Gemini'));
      expect(
        geminiMeta.apiKeyUrl,
        equals('https://aistudio.google.com/app/apikey'),
      );

      final groqMeta = AiProviderMetadata.getForType(AiProviderType.groq);
      expect(groqMeta.displayName, equals('Groq'));
      expect(groqMeta.apiKeyUrl, equals('https://console.groq.com/keys'));
    });
  });
}
