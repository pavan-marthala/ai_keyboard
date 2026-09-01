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
class OpenRouterProvider implements AiProvider {
  final Dio _dio;

  OpenRouterProvider(this._dio);

  @override
  AiProviderType get type => AiProviderType.openRouter;

  @override
  Future<Result<List<AiModel>, Failure>> getModels(String apiKey) async {
    try {
      final response = await _dio.get(
        'https://openrouter.ai/api/v1/models',
        options: Options(
          headers: apiKey.isNotEmpty
              ? {'Authorization': 'Bearer $apiKey'}
              : null,
        ),
      );

      final List<dynamic> data = response.data['data'] ?? [];
      final List<AiModel> models = [];

      for (final item in data) {
        final id = item['id'] as String? ?? '';
        final name = item['name'] as String? ?? id;
        final architecture = item['architecture'] as Map<String, dynamic>?;
        final modality = architecture?['modality'] as String? ?? '';

        if (modality.isEmpty || modality.contains('text')) {
          models.add(
            AiModel(
              id: id,
              displayName: name,
              provider: type,
              description: item['description'] as String?,
              capabilities: [modality],
            ),
          );
        }
      }

      models.sort((a, b) => a.displayName.compareTo(b.displayName));

      if (models.isEmpty) {
        return const FailureResult(
          Failure.server(
            message: 'No models returned from OpenRouter catalog.',
          ),
        );
      }

      return Success(models);
    } on DioException catch (e) {
      return FailureResult(
        Failure.server(
          message: e.message ?? 'Failed to fetch OpenRouter models',
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
      return const FailureResult(
        Failure.missingApiKey(providerName: 'OpenRouter'),
      );
    }
    try {
      final response = await _dio.post(
        'https://openrouter.ai/api/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': request.config.modelId.ifEmpty('openai/gpt-4o-mini'),
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
        Failure.server(message: 'Empty response from OpenRouter'),
      );
    } on DioException catch (e) {
      return FailureResult(
        Failure.server(
          message: e.message ?? 'OpenRouter API Error',
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      return FailureResult(Failure.unexpected(message: e.toString()));
    }
  }
}
