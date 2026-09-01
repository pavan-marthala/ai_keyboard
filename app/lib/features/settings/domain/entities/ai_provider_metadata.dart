import 'ai_provider_type.dart';

class AiProviderMetadata {
  final AiProviderType type;
  final String displayName;
  final String description;
  final String apiKeyUrl;

  const AiProviderMetadata({
    required this.type,
    required this.displayName,
    required this.description,
    required this.apiKeyUrl,
  });

  static const List<AiProviderMetadata> allProviders = [
    AiProviderMetadata(
      type: AiProviderType.openAi,
      displayName: 'OpenAI',
      description: 'GPT-4o, GPT-4o-mini, and OpenAI models catalog',
      apiKeyUrl: 'https://platform.openai.com/api-keys',
    ),
    AiProviderMetadata(
      type: AiProviderType.gemini,
      displayName: 'Google Gemini',
      description:
          'Gemini 1.5 Flash, Gemini 1.5 Pro, and Google AI Studio models',
      apiKeyUrl: 'https://aistudio.google.com/app/apikey',
    ),
    AiProviderMetadata(
      type: AiProviderType.openRouter,
      displayName: 'OpenRouter',
      description: 'Unified API for top open source and proprietary AI models',
      apiKeyUrl: 'https://openrouter.ai/keys',
    ),
    AiProviderMetadata(
      type: AiProviderType.groq,
      displayName: 'Groq',
      description: 'Ultra-fast Llama 3, Mixtral, Qwen, and Gemma inference',
      apiKeyUrl: 'https://console.groq.com/keys',
    ),
  ];

  static AiProviderMetadata getForType(AiProviderType type) {
    return allProviders.firstWhere(
      (p) => p.type == type,
      orElse: () => allProviders.first,
    );
  }
}
