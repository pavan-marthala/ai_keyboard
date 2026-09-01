import 'package:ai_keyboard/features/settings/domain/entities/ai_provider_type.dart';
import 'package:ai_keyboard/features/settings/domain/entities/user_settings.dart';
import 'package:ai_keyboard/features/settings/domain/repositories/credentials_repository.dart';
import 'package:ai_keyboard/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'settings_event.dart';
import 'settings_state.dart';

@injectable
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;
  final CredentialsRepository _credentialsRepository;

  SettingsBloc(
    this._settingsRepository,
    this._credentialsRepository,
  ) : super(const SettingsState()) {
    on<SettingsEvent>((event, emit) async {
      await event.map(
        loadSettings: (_) async => _onLoadSettings(emit),
        updateSettings: (e) async => _onUpdateSettings(e.settings, emit),
        saveApiKey: (e) async => _onSaveApiKey(e.provider, e.apiKey, emit),
        deleteApiKey: (e) async => _onDeleteApiKey(e.provider, emit),
      );
    });
  }

  Future<void> _onLoadSettings(Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true, failure: null));
    final settingsResult = await _settingsRepository.getSettings();

    await settingsResult.when(
      success: (settings) async {
        final Map<AiProviderType, bool> hasKeyMap = {};
        for (final provider in AiProviderType.values) {
          final keyResult = await _credentialsRepository.getApiKey(provider);
          keyResult.when(
            success: (key) =>
                hasKeyMap[provider] = key != null && key.isNotEmpty,
            failure: (_) => hasKeyMap[provider] = false,
          );
        }
        emit(state.copyWith(
          settings: settings,
          hasApiKeyMap: hasKeyMap,
          isLoading: false,
        ));
      },
      failure: (failure) async {
        emit(state.copyWith(isLoading: false, failure: failure));
      },
    );
  }

  Future<void> _onUpdateSettings(
    UserSettings settings,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, failure: null));
    final result = await _settingsRepository.saveSettings(settings);
    result.when(
      success: (_) {
        emit(state.copyWith(
          settings: settings,
          isLoading: false,
        ));
      },
      failure: (failure) {
        emit(state.copyWith(isLoading: false, failure: failure));
      },
    );
  }

  Future<void> _onSaveApiKey(
    AiProviderType provider,
    String apiKey,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, failure: null));
    final result = await _credentialsRepository.saveApiKey(
      provider,
      apiKey,
    );
    result.when(
      success: (_) {
        final updatedMap = Map<AiProviderType, bool>.from(state.hasApiKeyMap);
        updatedMap[provider] = true;
        emit(state.copyWith(
          hasApiKeyMap: updatedMap,
          isLoading: false,
        ));
      },
      failure: (failure) {
        emit(state.copyWith(isLoading: false, failure: failure));
      },
    );
  }

  Future<void> _onDeleteApiKey(
    AiProviderType provider,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, failure: null));
    final result = await _credentialsRepository.deleteApiKey(provider);
    result.when(
      success: (_) {
        final updatedMap = Map<AiProviderType, bool>.from(state.hasApiKeyMap);
        updatedMap[provider] = false;
        emit(state.copyWith(
          hasApiKeyMap: updatedMap,
          isLoading: false,
        ));
      },
      failure: (failure) {
        emit(state.copyWith(isLoading: false, failure: failure));
      },
    );
  }
}
