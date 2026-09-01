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
class GeminiProvider implements AiProvider {
  final Dio _dio;

  GeminiProvider(this._dio);

  @override
  AiProviderType get type => AiProviderType.gemini;

  @override
  Future<Result<List<AiModel>, Failure>> getModels(String apiKey) async {
    if (apiKey.isEmpty) {
      return const FailureResult(
        Failure.missingApiKey(providerName: 'Google Gemini'),
      );
    }
    try {
      final response = await _dio.get(
        'https://generativelanguage.googleapis.com/v1beta/models',
        queryParameters: {'key': apiKey},
      );

      final List<dynamic> rawModels = response.data['models'] ?? [];
      final List<AiModel> models = [];

      for (final item in rawModels) {
        final name = item['name'] as String? ?? '';
        final methods = List<String>.from(
          item['supportedGenerationMethods'] ?? [],
        );

        if (methods.contains('generateContent') &&
            name.startsWith('models/gemini')) {
          final id = name.replaceFirst('models/', '');
          final rawDisplayName = item['displayName'] as String? ?? id;

          models.add(
            AiModel(
              id: id,
              displayName: rawDisplayName,
              provider: type,
              description: item['description'] as String?,
              capabilities: methods,
            ),
          );
        }
      }

      models.sort((a, b) => a.displayName.compareTo(b.displayName));

      if (models.isEmpty) {
        return const FailureResult(
          Failure.server(
            message: 'No compatible text generation models found for Gemini.',
          ),
        );
      }

      return Success(models);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 403) {
        return const FailureResult(
          Failure.missingApiKey(providerName: 'Google Gemini'),
        );
      }
      return FailureResult(
        Failure.server(
          message: e.message ?? 'Failed to fetch Gemini models',
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
        Failure.missingApiKey(providerName: 'Google Gemini'),
      );
    }
    try {
      final modelId = request.config.modelId.ifEmpty('gemini-1.5-flash');
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/$modelId:generateContent?key=$apiKey';

      final response = await _dio.post(
        url,
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text':
                      '${request.prompt}\n\nUser Input:\n${request.inputText}',
                },
              ],
            },
          ],
        },
      );

      final candidates = response.data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final parts = candidates.first['content']?['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          final text = parts.first['text'] as String? ?? '';
          return Success(AiResponse(transformedText: text.trim()));
        }
      }

      return const FailureResult(
        Failure.server(message: 'Empty response from Gemini'),
      );
    } on DioException catch (e) {
      return FailureResult(
        Failure.server(
          message: e.message ?? 'Gemini API Error',
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      return FailureResult(Failure.unexpected(message: e.toString()));
    }
  }
}
