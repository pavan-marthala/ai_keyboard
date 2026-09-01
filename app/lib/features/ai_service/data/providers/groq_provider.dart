import 'package:ai_keyboard/core/errors/failures.dart';
import 'package:ai_keyboard/core/errors/result.dart';
import 'package:ai_keyboard/features/ai_service/data/providers/ai_provider_interface.dart';
import 'package:ai_keyboard/features/ai_service/data/providers/openai_provider.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_model.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_request.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_response.dart';
import 'package:ai_keyboard/features/settings/domain/entities/ai_provider_type.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class GroqProvider implements AiProvider {
  final Dio _dio;

  GroqProvider(this._dio);

  @override
  AiProviderType get type => AiProviderType.groq;

  @override
  Future<Result<List<AiModel>, Failure>> getModels(String apiKey) async {
    if (apiKey.isEmpty) {
      return const FailureResult(Failure.missingApiKey(providerName: 'Groq'));
    }
    try {
      final response = await _dio.get(
        'https://api.groq.com/openai/v1/models',
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );

      final List<dynamic> data = response.data['data'] ?? [];
      final List<AiModel> models = [];

      for (final item in data) {
        final id = item['id'] as String? ?? '';
        if (id.contains('whisper') || id.contains('audio')) {
          continue;
        }

        models.add(
          AiModel(
            id: id,
            displayName: id,
            provider: type,
            capabilities: ['text-generation', 'chat'],
          ),
        );
      }

      models.sort((a, b) => a.displayName.compareTo(b.displayName));

      if (models.isEmpty) {
        return const FailureResult(
          Failure.server(message: 'No text models found for Groq.'),
        );
      }

      return Success(models);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const FailureResult(Failure.missingApiKey(providerName: 'Groq'));
      }
      return FailureResult(
        Failure.server(
          message: e.message ?? 'Failed to fetch Groq models',
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      return FailureResult(Failure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Result<AiResponse, Failure>> transform({
    required AiRequest request,
    required String apiKey,
  }) async {
    if (apiKey.isEmpty) {
      return const FailureResult(Failure.missingApiKey(providerName: 'Groq'));
    }
    try {
      final response = await _dio.post(
        'https://api.groq.com/openai/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': request.config.modelId.ifEmpty('llama-3.3-70b-versatile'),
          'temperature': request.temperature,
          'messages': [
            {'role': 'system', 'content': request.prompt},
            {'role': 'user', 'content': request.inputText},
          ],
        },
      );

      final choices = response.data['choices'] as List<dynamic>?;
      if (choices != null && choices.isNotEmpty) {
        final content = choices.first['message']?['content'] as String? ?? '';
        return Success(AiResponse(transformedText: content.trim()));
      }

      return const FailureResult(
        Failure.server(message: 'Empty response from Groq'),
      );
    } on DioException catch (e) {
      return FailureResult(
        Failure.server(
          message: e.message ?? 'Groq API Error',
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      return FailureResult(Failure.unexpected(message: e.toString()));
    }
  }
}
