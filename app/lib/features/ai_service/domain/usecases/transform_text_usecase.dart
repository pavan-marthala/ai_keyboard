import 'package:ai_keyboard/core/errors/failures.dart';
import 'package:ai_keyboard/core/errors/result.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_provider_config.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_request.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_response.dart';
import 'package:ai_keyboard/features/ai_service/domain/repositories/ai_repository.dart';
import 'package:ai_keyboard/features/settings/domain/repositories/credentials_repository.dart';
import 'package:ai_keyboard/features/settings/domain/repositories/settings_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class TransformTextUseCase {
  final AiRepository _aiRepository;
  final SettingsRepository _settingsRepository;
  final CredentialsRepository _credentialsRepository;

  TransformTextUseCase(
    this._aiRepository,
    this._settingsRepository,
    this._credentialsRepository,
  );

  Future<Result<AiResponse, Failure>> call({
    required String inputText,
    required String prompt,
  }) async {
    final settingsResult = await _settingsRepository.getSettings();

    return settingsResult.when(
      success: (settings) async {
        final keyResult =
            await _credentialsRepository.getApiKey(settings.activeProvider);
        return keyResult.when(
          success: (apiKey) async {
            if (apiKey == null || apiKey.isEmpty) {
              return FailureResult(
                Failure.missingApiKey(
                  providerName: settings.activeProvider.name,
                ),
              );
            }
            final request = AiRequest(
              inputText: inputText,
              prompt: prompt,
              config: AiProviderConfig(
                provider: settings.activeProvider,
                modelId: settings.activeModelId,
                baseUrl: settings.customBaseUrl,
              ),
            );
            return _aiRepository.transformText(
              request: request,
              apiKey: apiKey,
            );
          },
          failure: (failure) => FailureResult(failure),
        );
      },
      failure: (failure) => FailureResult(failure),
    );
  }
}
