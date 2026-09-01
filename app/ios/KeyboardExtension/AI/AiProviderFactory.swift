import Foundation

class AiProviderFactory {
    static func createProvider(for providerType: String) -> AiProvider? {
        switch providerType.lowercased() {
        case "openai": return OpenAiProvider()
        case "gemini": return GeminiProvider()
        case "groq": return GroqProvider()
        case "openrouter": return OpenRouterProvider()
        default: return nil
        }
    }
}

