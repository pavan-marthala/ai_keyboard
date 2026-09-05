import 'package:atfix/features/settings/domain/entities/ai_provider_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_provider_config.freezed.dart';
part 'ai_provider_config.g.dart';

@freezed
abstract class AiProviderConfig with _$AiProviderConfig {
  const factory AiProviderConfig({
    required AiProviderType provider,
    required String modelId,
    String? baseUrl,
  }) = _AiProviderConfig;

  factory AiProviderConfig.fromJson(Map<String, dynamic> json) =>
      _$AiProviderConfigFromJson(json);
}
