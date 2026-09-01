// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CommandEntity _$CommandEntityFromJson(Map<String, dynamic> json) =>
    _CommandEntity(
      trigger: json['trigger'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      prompt: json['prompt'] as String,
      enabled: json['enabled'] as bool? ?? true,
    );

Map<String, dynamic> _$CommandEntityToJson(_CommandEntity instance) =>
    <String, dynamic>{
      'trigger': instance.trigger,
      'name': instance.name,
      'description': instance.description,
      'prompt': instance.prompt,
      'enabled': instance.enabled,
    };
