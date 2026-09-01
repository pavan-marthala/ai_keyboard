import 'package:ai_keyboard/core/errors/failures.dart';
import 'package:ai_keyboard/core/errors/result.dart';
import 'package:ai_keyboard/features/ai_service/data/providers/ai_provider_interface.dart';
import 'package:ai_keyboard/features/ai_service/data/providers/gemini_provider.dart';
import 'package:ai_keyboard/features/ai_service/data/providers/groq_provider.dart';
import 'package:ai_keyboard/features/ai_service/data/providers/openai_provider.dart';
import 'package:ai_keyboard/features/ai_service/data/providers/openrouter_provider.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_model.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_request.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_response.dart';
import 'package:ai_keyboard/features/ai_service/domain/repositories/ai_repository.dart';
import 'package:ai_keyboard/features/settings/domain/entities/ai_provider_type.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AiRepository)
class AiRepositoryImpl implements AiRepository {
  final OpenAiProvider _openAiProvider;
  final GeminiProvider _geminiProvider;
  final OpenRouterProvider _openRouterProvider;
  final GroqProvider _groqProvider;

  final Map<AiProviderType, List<AiModel>> _modelCache = {};

  AiRepositoryImpl(
    this._openAiProvider,
    this._geminiProvider,
    this._openRouterProvider,
    this._groqProvider,
  );

  AiProvider _getProvider(AiProviderType type) {
    switch (type) {
      case AiProviderType.openAi:
        return _openAiProvider;
      case AiProviderType.gemini:
        return _geminiProvider;
      case AiProviderType.openRouter:
        return _openRouterProvider;
      case AiProviderType.groq:
        return _groqProvider;
    }
  }

  @override
  Future<Result<List<AiModel>, Failure>> getModels({
    required AiProviderType provider,
    required String apiKey,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _modelCache.containsKey(provider)) {
      return Success(_modelCache[provider]!);
    }

    final providerImpl = _getProvider(provider);
    final result = await providerImpl.getModels(apiKey);

    if (result is Success<List<AiModel>, Failure>) {
      _modelCache[provider] = result.data;
    }

    return result;
  }

  @override
  Future<Result<AiResponse, Failure>> transformText({
    required AiRequest request,
    required String apiKey,
  }) async {
    final providerImpl = _getProvider(request.config.provider);
    return providerImpl.transform(request: request, apiKey: apiKey);
  }
}
