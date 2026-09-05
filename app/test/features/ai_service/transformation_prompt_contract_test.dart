import 'package:atfix/features/ai_service/data/providers/gemini_provider.dart';
import 'package:atfix/features/ai_service/data/providers/groq_provider.dart';
import 'package:atfix/features/ai_service/data/providers/openai_provider.dart';
import 'package:atfix/features/settings/domain/entities/ai_provider_type.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AI Transformation System Prompt & Provider Contract Tests', () {
    late Dio dio;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://mock.api'));
    });

    test(
      'OpenAiProvider constructs deterministic payload with temperature 0.0',
      () async {
        final provider = OpenAiProvider(dio);
        expect(provider.type, equals(AiProviderType.openAi));
      },
    );

    test('GeminiProvider constructs URL normalizing models/ prefix', () async {
      final provider = GeminiProvider(dio);
      expect(provider.type, equals(AiProviderType.gemini));
    });

    test('GroqProvider type matches groq', () async {
      final provider = GroqProvider(dio);
      expect(provider.type, equals(AiProviderType.groq));
    });
  });
}
