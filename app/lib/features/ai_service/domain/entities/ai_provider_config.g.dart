// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_provider_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AiProviderConfig _$AiProviderConfigFromJson(Map<String, dynamic> json) =>
    _AiProviderConfig(
      provider: $enumDecode(_$AiProviderTypeEnumMap, json['provider']),
      modelId: json['modelId'] as String,
      baseUrl: json['baseUrl'] as String?,
    );

Map<String, dynamic> _$AiProviderConfigToJson(_AiProviderConfig instance) =>
    <String, dynamic>{
      'provider': _$AiProviderTypeEnumMap[instance.provider]!,
      'modelId': instance.modelId,
      'baseUrl': instance.baseUrl,
    };

const _$AiProviderTypeEnumMap = {
  AiProviderType.openAi: 'openAi',
  AiProviderType.gemini: 'gemini',
  AiProviderType.anthropic: 'anthropic',
  AiProviderType.custom: 'custom',
};
