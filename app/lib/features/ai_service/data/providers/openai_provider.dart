import 'package:ai_keyboard/core/errors/failures.dart';
import 'package:ai_keyboard/core/errors/result.dart';
import 'package:ai_keyboard/features/ai_service/data/providers/ai_provider_interface.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_model.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_request.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_response.dart';
import 'package:ai_keyboard/features/settings/domain/entities/ai_provider_type.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class OpenAiProvider implements AiProvider {
  final Dio _dio;

  OpenAiProvider(this._dio);

  @override
  AiProviderType get type => AiProviderType.openAi;

  @override
  Future<Result<List<AiModel>, Failure>> getModels(String apiKey) async {
    if (apiKey.isEmpty) {
      return const FailureResult(Failure.missingApiKey(providerName: 'OpenAI'));
    }
    try {
      final response = await _dio.get(
        'https://api.openai.com/v1/models',
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );

      final List<dynamic> data = response.data['data'] ?? [];
      final List<AiModel> models = [];

      for (final item in data) {
        final id = item['id'] as String? ?? '';
        if (id.contains('embedding') ||
            id.contains('whisper') ||
            id.contains('dall-e') ||
            id.contains('tts') ||
            id.contains('babbage') ||
            id.contains('davinci')) {
          continue;
        }

        final displayName = id
            .replaceAll('gpt-', 'GPT-')
            .replaceAll('-mini', ' Mini')
            .replaceAll('-turbo', ' Turbo');

        models.add(
          AiModel(
            id: id,
            displayName: displayName,
            provider: type,
            capabilities: ['text-generation', 'chat'],
          ),
        );
      }

      models.sort((a, b) => a.displayName.compareTo(b.displayName));

      if (models.isEmpty) {
        return const FailureResult(
          Failure.server(message: 'No text models found for OpenAI.'),
        );
      }

      return Success(models);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const FailureResult(
          Failure.missingApiKey(providerName: 'OpenAI'),
        );
      }
      return FailureResult(
        Failure.server(
          message: e.message ?? 'Failed to fetch OpenAI models',
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
      return const FailureResult(Failure.missingApiKey(providerName: 'OpenAI'));
    }
    try {
      final url = request.config.baseUrl?.isNotEmpty == true
          ? request.config.baseUrl!
          : 'https://api.openai.com/v1/chat/completions';

      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': request.config.modelId.ifEmpty('gpt-4o-mini'),
          'temperature': 0.0,
          'max_tokens': 1024,
          'messages': [
            {'role': 'system', 'content': request.prompt},
            {'role': 'user', 'content': request.inputText},
          ],
        },
      );

      final choices = response.data['choices'] as List<dynamic>?;
      if (choices != null && choices.isNotEmpty) {
        final content = choices.first['message']?['content'] as String? ?? '';
        final usage = response.data['usage'] as Map<String, dynamic>?;

        return Success(
          AiResponse(
            transformedText: content.trim(),
            promptTokens: usage?['prompt_tokens'] as int?,
            completionTokens: usage?['completion_tokens'] as int?,
          ),
        );
      }

      return const FailureResult(
        Failure.server(message: 'Empty response from OpenAI'),
      );
    } on DioException catch (e) {
      return FailureResult(
        Failure.server(
          message: e.message ?? 'OpenAI API Error',
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      return FailureResult(Failure.unexpected(message: e.toString()));
    }
  }
}

extension StringExt on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
