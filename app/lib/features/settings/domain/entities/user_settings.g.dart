// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) =>
    _UserSettings(
      activeProvider:
          $enumDecodeNullable(
            _$AiProviderTypeEnumMap,
            json['activeProvider'],
          ) ??
          AiProviderType.openAi,
      activeModelId: json['activeModelId'] as String? ?? 'gpt-4o-mini',
      customBaseUrl: json['customBaseUrl'] as String?,
      hapticFeedbackEnabled: json['hapticFeedbackEnabled'] as bool? ?? true,
      soundEffectsEnabled: json['soundEffectsEnabled'] as bool? ?? true,
    );

Map<String, dynamic> _$UserSettingsToJson(_UserSettings instance) =>
    <String, dynamic>{
      'activeProvider': _$AiProviderTypeEnumMap[instance.activeProvider]!,
      'activeModelId': instance.activeModelId,
      'customBaseUrl': instance.customBaseUrl,
      'hapticFeedbackEnabled': instance.hapticFeedbackEnabled,
      'soundEffectsEnabled': instance.soundEffectsEnabled,
    };

const _$AiProviderTypeEnumMap = {
  AiProviderType.openAi: 'openAi',
  AiProviderType.gemini: 'gemini',
  AiProviderType.anthropic: 'anthropic',
  AiProviderType.custom: 'custom',
};
