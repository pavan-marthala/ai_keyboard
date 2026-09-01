import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum AiProviderType {
  @JsonValue('openAi')
  openAi,
  @JsonValue('gemini')
  gemini,
  @JsonValue('anthropic')
  anthropic,
  @JsonValue('custom')
  custom,
}
