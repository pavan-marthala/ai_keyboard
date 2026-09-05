import 'package:atfix/core/errors/failures.dart';
import 'package:atfix/core/errors/result.dart';
import 'package:atfix/features/ai_service/domain/entities/ai_model.dart';
import 'package:atfix/features/ai_service/domain/repositories/ai_repository.dart';
import 'package:atfix/features/settings/domain/entities/ai_provider_type.dart';
import 'package:atfix/features/settings/domain/entities/user_settings.dart';
import 'package:atfix/features/settings/domain/repositories/credentials_repository.dart';
import 'package:atfix/features/settings/domain/repositories/settings_repository.dart';
import 'package:atfix/features/settings/presentation/bloc/settings_event.dart';
import 'package:atfix/features/settings/presentation/bloc/settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;
  final CredentialsRepository _credentialsRepository;
  final AiRepository _aiRepository;

  SettingsBloc(
    this._settingsRepository,
    this._credentialsRepository,
    this._aiRepository,
  ) : super(const SettingsState()) {
    on<SettingsEvent>((event, emit) async {
      await event.when(
        loadSettings: () => _onLoadSettings(emit),
        updateSettings: (settings) => _onUpdateSettings(settings, emit),
        saveApiKey: (provider, apiKey) => _onSaveApiKey(provider, apiKey, emit),
        deleteApiKey: (provider) => _onDeleteApiKey(provider, emit),
        selectProvider: (provider) => _onSelectProvider(provider, emit),
        fetchModels: (provider, forceRefresh) =>
            _onFetchModels(provider, forceRefresh, emit),
        selectModel: (modelId) => _onSelectModel(modelId, emit),
      );
    });
  }

  Future<void> _onLoadSettings(Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true));

    final settingsResult = await _settingsRepository.getSettings();

    UserSettings currentSettings = const UserSettings();
    if (settingsResult is Success<UserSettings, Failure>) {
      currentSettings = settingsResult.data;
    }

    final Map<AiProviderType, bool> hasKeyMap = {};
    for (final provider in AiProviderType.values) {
      final keyResult = await _credentialsRepository.getApiKey(provider);
      hasKeyMap[provider] =
          keyResult is Success<String?, Failure> &&
          keyResult.data != null &&
          keyResult.data!.isNotEmpty;
    }

    emit(
      state.copyWith(
        isLoading: false,
        settings: currentSettings,
        hasApiKeyMap: hasKeyMap,
      ),
    );

    if (hasKeyMap[currentSettings.activeProvider] == true) {
      add(SettingsEvent.fetchModels(provider: currentSettings.activeProvider));
    }
  }

  Future<void> _onUpdateSettings(
    UserSettings settings,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final result = await _settingsRepository.saveSettings(settings);
    if (result is Success<void, Failure>) {
      emit(state.copyWith(isLoading: false, settings: settings));
    } else if (result is FailureResult<void, Failure>) {
      emit(state.copyWith(isLoading: false, failure: result.failure));
    }
  }

  Future<void> _onSelectProvider(
    AiProviderType provider,
    Emitter<SettingsState> emit,
  ) async {
    final newSettings = state.settings.copyWith(activeProvider: provider);
    emit(state.copyWith(settings: newSettings));
    await _settingsRepository.saveSettings(newSettings);

    final hasKey = state.hasApiKeyMap[provider] == true;
    if (hasKey) {
      add(SettingsEvent.fetchModels(provider: provider));
    }
  }

  Future<void> _onSaveApiKey(
    AiProviderType provider,
    String apiKey,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final result = await _credentialsRepository.saveApiKey(provider, apiKey);

    if (result is Success<void, Failure>) {
      final updatedMap = Map<AiProviderType, bool>.from(state.hasApiKeyMap);
      updatedMap[provider] = true;
      emit(state.copyWith(isLoading: false, hasApiKeyMap: updatedMap));

      add(SettingsEvent.fetchModels(provider: provider, forceRefresh: true));
    } else if (result is FailureResult<void, Failure>) {
      emit(state.copyWith(isLoading: false, failure: result.failure));
    }
  }

  Future<void> _onDeleteApiKey(
    AiProviderType provider,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final result = await _credentialsRepository.deleteApiKey(provider);
    if (result is Success<void, Failure>) {
      final updatedMap = Map<AiProviderType, bool>.from(state.hasApiKeyMap);
      updatedMap[provider] = false;

      final updatedModelsMap = Map<AiProviderType, List<AiModel>>.from(
        state.modelsMap,
      );
      updatedModelsMap.remove(provider);

      emit(
        state.copyWith(
          isLoading: false,
          hasApiKeyMap: updatedMap,
          modelsMap: updatedModelsMap,
        ),
      );
    } else if (result is FailureResult<void, Failure>) {
      emit(state.copyWith(isLoading: false, failure: result.failure));
    }
  }

  Future<void> _onFetchModels(
    AiProviderType provider,
    bool forceRefresh,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isFetchingModels: true, modelsError: null));

    final keyResult = await _credentialsRepository.getApiKey(provider);
    String? apiKey;
    if (keyResult is Success<String?, Failure>) {
      apiKey = keyResult.data;
    }

    if (apiKey == null || apiKey.isEmpty) {
      emit(
        state.copyWith(
          isFetchingModels: false,
          modelsError: Failure.missingApiKey(providerName: provider.name),
        ),
      );
      return;
    }

    final result = await _aiRepository.getModels(
      provider: provider,
      apiKey: apiKey,
      forceRefresh: forceRefresh,
    );

    if (result is Success<List<AiModel>, Failure>) {
      final models = result.data;
      final updatedModelsMap = Map<AiProviderType, List<AiModel>>.from(
        state.modelsMap,
      );
      updatedModelsMap[provider] = models;

      UserSettings updatedSettings = state.settings;
      if (models.isNotEmpty) {
        final currentModelId = state.settings.activeModelId;
        final isModelAvailable = models.any((m) => m.id == currentModelId);

        if (!isModelAvailable || currentModelId.isEmpty) {
          updatedSettings = state.settings.copyWith(
            activeModelId: models.first.id,
          );
          await _settingsRepository.saveSettings(updatedSettings);
        }
      }

      emit(
        state.copyWith(
          isFetchingModels: false,
          modelsMap: updatedModelsMap,
          settings: updatedSettings,
        ),
      );
    } else if (result is FailureResult<List<AiModel>, Failure>) {
      emit(
        state.copyWith(isFetchingModels: false, modelsError: result.failure),
      );
    }
  }

  Future<void> _onSelectModel(
    String modelId,
    Emitter<SettingsState> emit,
  ) async {
    final updatedSettings = state.settings.copyWith(activeModelId: modelId);
    emit(state.copyWith(settings: updatedSettings));
    await _settingsRepository.saveSettings(updatedSettings);
  }
}
