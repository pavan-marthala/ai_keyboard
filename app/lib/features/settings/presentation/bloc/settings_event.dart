import 'package:atfix/features/settings/domain/entities/ai_provider_type.dart';
import 'package:atfix/features/settings/domain/entities/user_settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_event.freezed.dart';

@freezed
class SettingsEvent with _$SettingsEvent {
  const factory SettingsEvent.loadSettings() = _LoadSettings;
  const factory SettingsEvent.updateSettings(UserSettings settings) =
      _UpdateSettings;
  const factory SettingsEvent.saveApiKey({
    required AiProviderType provider,
    required String apiKey,
  }) = _SaveApiKey;
  const factory SettingsEvent.deleteApiKey({required AiProviderType provider}) =
      _DeleteApiKey;

  const factory SettingsEvent.selectProvider(AiProviderType provider) =
      _SelectProvider;
  const factory SettingsEvent.fetchModels({
    required AiProviderType provider,
    @Default(false) bool forceRefresh,
  }) = _FetchModels;
  const factory SettingsEvent.selectModel(String modelId) = _SelectModel;
}
