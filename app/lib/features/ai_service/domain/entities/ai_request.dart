import 'package:freezed_annotation/freezed_annotation.dart';

import 'ai_provider_config.dart';

part 'ai_request.freezed.dart';

@freezed
abstract class AiRequest with _$AiRequest {
  const factory AiRequest({
    required String inputText,
    required String prompt,
    required AiProviderConfig config,
    @Default(0.7) double temperature,
    @Default(1000) int maxTokens,
  }) = _AiRequest;
}
