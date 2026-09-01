// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AiModel _$AiModelFromJson(Map<String, dynamic> json) => _AiModel(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  provider: $enumDecode(_$AiProviderTypeEnumMap, json['provider']),
  description: json['description'] as String?,
  capabilities:
      (json['capabilities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$AiModelToJson(_AiModel instance) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'provider': _$AiProviderTypeEnumMap[instance.provider]!,
  'description': instance.description,
  'capabilities': instance.capabilities,
};

const _$AiProviderTypeEnumMap = {
  AiProviderType.openAi: 'openAi',
  AiProviderType.gemini: 'gemini',
  AiProviderType.openRouter: 'openRouter',
  AiProviderType.groq: 'groq',
};
