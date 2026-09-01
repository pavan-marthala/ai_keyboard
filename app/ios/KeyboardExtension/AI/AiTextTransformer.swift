import Foundation

class AiTextTransformer {
    static let shared = AiTextTransformer()
    private static let maxChars = 4000

    private init() {}

    func transformText(text: String, prompt: String) async -> Result<String, AiFailure> {
        if text.count > Self.maxChars {
            return .failure(.textTooLong)
        }

        guard let config = KeyboardConfigurationReader.shared.getConfiguration() else {
            return .failure(.missingApiKey)
        }

        guard let apiKey = KeyboardConfigurationReader.shared.getApiKeyForActiveProvider(), !apiKey.isEmpty else {
            return .failure(.missingApiKey)
        }

        guard let provider = AiProviderFactory.createProvider(for: config.activeProvider) else {
            return .failure(.unknown("Unsupported provider: \(config.activeProvider)"))
        }

        do {
            let result = try await provider.transform(
                text: text,
                prompt: prompt,
                model: config.activeModelId,
                apiKey: apiKey,
                baseURL: config.customBaseUrl
            )
            return .success(result)
        } catch let failure as AiFailure {
            return .failure(failure)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }
}

