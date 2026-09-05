import 'package:atfix/features/settings/domain/entities/ai_provider_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_settings.freezed.dart';
part 'user_settings.g.dart';

@freezed
abstract class UserSettings with _$UserSettings {
  const factory UserSettings({
    @Default(AiProviderType.openAi) AiProviderType activeProvider,
    @Default('gpt-4o-mini') String activeModelId,
    String? customBaseUrl,
    @Default(true) bool hapticFeedbackEnabled,
    @Default(true) bool soundEffectsEnabled,
    @Default(false) bool useNumbersEnabled,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}
