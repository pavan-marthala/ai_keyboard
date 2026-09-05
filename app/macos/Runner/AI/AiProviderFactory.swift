import Foundation

/// Factory for resolving native macOS AI providers.
class AiProviderFactory {

    /// Creates and returns an AiProvider instance for the given provider type name.
    ///
    /// - Parameter providerType: Case-insensitive provider identifier ("openai", "openrouter", "groq").
    /// - Throws: `AiFailure.unsupportedProvider` if provider is unrecognized.
    ///   DOES NOT silently fall back to OpenAI.
    static func createProvider(for providerType: String) throws -> AiProvider {
        let normalized = providerType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        switch normalized {
        case "openai":
            return OpenAiCompatibleProvider(
                providerType: "openai",
                defaultEndpoint: "https://api.openai.com/v1/chat/completions",
                defaultModel: "gpt-4o-mini"
            )

        case "openrouter":
            return OpenAiCompatibleProvider(
                providerType: "openrouter",
                defaultEndpoint: "https://openrouter.ai/api/v1/chat/completions",
                defaultModel: "openai/gpt-4o-mini"
            )

        case "groq":
            return OpenAiCompatibleProvider(
                providerType: "groq",
                defaultEndpoint: "https://api.groq.com/openai/v1/chat/completions",
                defaultModel: "llama-3.3-70b-versatile"
            )

        default:
            NSLog("[AiProviderFactory] Unsupported AI provider: '\(providerType)'")
            throw AiFailure.unsupportedProvider(providerType)
        }
    }
}

