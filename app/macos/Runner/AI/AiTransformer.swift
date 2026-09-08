import Foundation

/// Orchestrator for transforming text using the active AI provider.
class AiTransformer {

    static let shared = AiTransformer()

    private static let maxChars = 4000

    private init() {}

    /// Transforms `text` using the real AI provider configured for `command`.
    ///
    /// - Parameters:
    ///   - command: The command trigger (e.g. "@fix").
    ///   - text: The selected text to transform.
    /// - Returns: The transformed text from the AI provider.
    /// - Throws: `AiFailure` on any failure. NEVER falls back to mock transformations.
    func transform(command: String, text: String) async throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return text
        }

        if text.count > Self.maxChars {
            throw AiFailure.textTooLong
        }

        // 1. Verify command is enabled in settings
        guard ConfigurationStore.shared.isCommandEnabled(command) else {
            NSLog("[AiTransformer] Command '\(command)' is disabled in settings")
            throw AiFailure.disabledCommand(command)
        }

        // 2. Read active configuration
        guard let config = ConfigurationStore.shared.getConfig() else {
            NSLog("[AiTransformer] No active configuration found")
            throw AiFailure.missingApiKey
        }

        // 3. Read API key from Keychain
        guard let apiKey = KeychainCredentialStore.shared.readApiKey(provider: config.provider),
              !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            NSLog("[AiTransformer] Missing API key in Keychain for provider: '\(config.provider)'")
            throw AiFailure.missingApiKey
        }

        // 4. Resolve provider via factory
        let provider = try AiProviderFactory.createProvider(for: config.provider)

        // 5. Build command prompt
        let prompt = try promptForCommand(command)

        NSLog("[AiTransformer] Executing AI transform: command=\(command), provider=\(config.provider), model=\(config.modelId)")

        // 6. Execute transformation request
        let result = try await provider.transform(
            text: text,
            prompt: prompt,
            model: config.modelId,
            apiKey: apiKey,
            baseURL: config.baseUrl
        )

        NSLog("[AiTransformer] AI transform succeeded for command '\(command)'")
        return result
    }

    static func resolvePromptKey(for command: String) -> (key: String, variables: [String: String]) {
        let normalized = command.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        var variables: [String: String] = [:]

        if normalized == "@pro" || normalized == "pro" {
            // Strictly reject deprecated @pro
            return ("pro", [:])
        }

        if normalized.hasPrefix("@translate") {
            let key = "translate"
            if normalized.contains(":") {
                let parts = normalized.split(separator: ":", maxSplits: 1).map(String.init)
                let langCode = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespacesAndNewlines) : ""
                let langName = PromptRepository.supportedLanguages[langCode] ?? langCode
                variables["language"] = langName
            }
            return (key, variables)
        }

        if let def = PromptRepository.shared.command(for: normalized) {
            return (def.id, variables)
        }

        let key = normalized.hasPrefix("@") ? String(normalized.dropFirst()) : normalized
        return (key, variables)
    }

    private func promptForCommand(_ command: String) throws -> String {
        let resolved = Self.resolvePromptKey(for: command)
        return try PromptRepository.shared.getPrompt(resolved.key, variables: resolved.variables)
    }
}
