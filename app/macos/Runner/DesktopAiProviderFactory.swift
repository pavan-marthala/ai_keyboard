import Foundation

/// Factory for resolving native macOS desktop AI providers.
class DesktopAiProviderFactory {

    /// Creates and returns a DesktopAiProvider instance for the given provider type name.
    ///
    /// - Parameter providerType: Case-insensitive provider identifier ("openai", "openrouter", "groq").
    /// - Throws: `DesktopAiFailure.unsupportedProvider` if provider is unrecognized.
    ///   DOES NOT silently fall back to OpenAI.
    static func createProvider(for providerType: String) throws -> DesktopAiProvider {
        let normalized = providerType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        switch normalized {
        case "openai":
            return OpenAiDesktopProvider(
                providerType: "openai",
                defaultEndpoint: "https://api.openai.com/v1/chat/completions",
                defaultModel: "gpt-4o-mini"
            )

        case "openrouter":
            return OpenAiDesktopProvider(
                providerType: "openrouter",
                defaultEndpoint: "https://openrouter.ai/api/v1/chat/completions",
                defaultModel: "openai/gpt-4o-mini"
            )

        case "groq":
            return OpenAiDesktopProvider(
                providerType: "groq",
                defaultEndpoint: "https://api.groq.com/openai/v1/chat/completions",
                defaultModel: "llama-3.3-70b-versatile"
            )

        default:
            NSLog("[DesktopAiProviderFactory] Unsupported AI provider: '\(providerType)'")
            throw DesktopAiFailure.unsupportedProvider(providerType)
        }
    }
}

