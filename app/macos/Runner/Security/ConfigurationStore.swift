import Foundation

/// Active AI configuration representation on native macOS.
struct AiConfiguration: Equatable {
    let provider: String
    let modelId: String
    let baseUrl: String?
}

/// Native configuration storage for macOS AI commands.
///
/// Stores active provider, model, custom base URL, and disabled commands in
/// `UserDefaults.standard`, with fallback support for reading Flutter's
/// `"flutter.user_settings"`.
final class ConfigurationStore {

    static let shared = ConfigurationStore()

    private let userDefaults: UserDefaults

    private let keyActiveProvider = "active_provider"
    private let keyActiveModel = "active_model"
    private let keyCustomBaseUrl = "custom_base_url"
    private let keyDisabledCommands = "disabled_commands"
    private let keyFlutterUserSettings = "flutter.user_settings"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// Saves provider, model, and optional custom base URL configuration.
    func saveConfig(provider: String, modelId: String, baseUrl: String? = nil) {
        let p = provider.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let m = modelId.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = baseUrl?.trimmingCharacters(in: .whitespacesAndNewlines)

        userDefaults.set(p, forKey: keyActiveProvider)
        userDefaults.set(m.isEmpty ? "gpt-4o-mini" : m, forKey: keyActiveModel)
        if let b = b, !b.isEmpty {
            userDefaults.set(b, forKey: keyCustomBaseUrl)
        } else {
            userDefaults.removeObject(forKey: keyCustomBaseUrl)
        }
        userDefaults.synchronize()
    }

    /// Retrieves the current AI configuration.
    ///
    /// Checks native keys first, then falls back to parsing Flutter's
    /// `"flutter.user_settings"` JSON, and finally defaults to OpenAI/gpt-4o-mini.
    func getConfig() -> AiConfiguration? {
        if let p = userDefaults.string(forKey: keyActiveProvider), !p.isEmpty {
            let model = userDefaults.string(forKey: keyActiveModel) ?? "gpt-4o-mini"
            let baseUrl = userDefaults.string(forKey: keyCustomBaseUrl)
            return AiConfiguration(provider: p, modelId: model, baseUrl: baseUrl)
        }

        // Fallback: parse flutter.user_settings if native config has not been explicitly saved yet
        if let jsonString = userDefaults.string(forKey: keyFlutterUserSettings),
           let data = jsonString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let rawProvider = (json["activeProvider"] as? String)?.lowercased() ?? "openai"
            let model = (json["activeModelId"] as? String) ?? "gpt-4o-mini"
            let baseUrl = json["customBaseUrl"] as? String
            return AiConfiguration(provider: rawProvider, modelId: model, baseUrl: baseUrl)
        }

        return AiConfiguration(provider: "openai", modelId: "gpt-4o-mini", baseUrl: nil)
    }

    /// Persists the list of disabled command triggers.
    func saveDisabledCommands(_ disabled: Set<String>) {
        let normalized = Array(disabled.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) })
        userDefaults.set(normalized, forKey: keyDisabledCommands)
        userDefaults.synchronize()
    }

    /// Returns the set of disabled command triggers.
    func getDisabledCommands() -> Set<String> {
        let list = userDefaults.stringArray(forKey: keyDisabledCommands) ?? []
        return Set(list.map { $0.lowercased() })
    }

    /// Checks whether a command trigger is currently enabled.
    func isCommandEnabled(_ trigger: String) -> Bool {
        let t = trigger.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return !getDisabledCommands().contains(t)
    }
}

