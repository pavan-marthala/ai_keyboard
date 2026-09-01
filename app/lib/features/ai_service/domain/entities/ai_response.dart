import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_response.freezed.dart';

@freezed
abstract class AiResponse with _$AiResponse {
  const factory AiResponse({
    required String transformedText,
    int? promptTokens,
    int? completionTokens,
  }) = _AiResponse;
}
