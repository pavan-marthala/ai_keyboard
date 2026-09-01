import 'package:ai_keyboard/core/errors/failures.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_model.dart';
import 'package:ai_keyboard/features/settings/domain/entities/ai_provider_type.dart';
import 'package:ai_keyboard/features/settings/domain/entities/user_settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_state.freezed.dart';

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default(UserSettings()) UserSettings settings,
    @Default(false) bool isLoading,
    @Default({}) Map<AiProviderType, bool> hasApiKeyMap,
    @Default({}) Map<AiProviderType, List<AiModel>> modelsMap,
    @Default(false) bool isFetchingModels,
    Failure? modelsError,
    Failure? failure,
  }) = _SettingsState;
}
