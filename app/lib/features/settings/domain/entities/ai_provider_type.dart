import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum AiProviderType {
  @JsonValue('openAi')
  openAi,
  @JsonValue('gemini')
  gemini,
  @JsonValue('openRouter')
  openRouter,
  @JsonValue('groq')
  groq,
}
