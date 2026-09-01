import Foundation

struct SharedAIConfiguration {
    let activeProvider: String
    let activeModelId: String
    let customBaseUrl: String?
}

class SharedConfigurationStore {

    static let shared = SharedConfigurationStore()

    private let userDefaults: UserDefaults?

    private init() {
        self.userDefaults = UserDefaults(suiteName: SharedConstants.appGroupIdentifier)
    }

    func saveConfig(provider: String, modelId: String, baseUrl: String? = nil) {
        guard let prefs = userDefaults else { return }
        prefs.set(provider.lowercased(), forKey: "active_provider")
        prefs.set(modelId, forKey: "active_model")
        prefs.set(baseUrl, forKey: "custom_base_url")
        prefs.synchronize()
    }

    func getConfig() -> SharedAIConfiguration? {
        guard let prefs = userDefaults else { return nil }
        let provider = prefs.string(forKey: "active_provider") ?? "openai"
        let modelId = prefs.string(forKey: "active_model") ?? "gpt-4o-mini"
        let baseUrl = prefs.string(forKey: "custom_base_url")

        return SharedAIConfiguration(
            activeProvider: provider,
            activeModelId: modelId,
            customBaseUrl: baseUrl
        )
    }

    func saveDisabledCommands(_ disabled: Set<String>) {
        guard let prefs = userDefaults else { return }
        let array = Array(disabled.map { $0.lowercased() })
        prefs.set(array, forKey: "disabled_commands")
        prefs.synchronize()
    }

    func isCommandEnabled(_ trigger: String) -> Bool {
        guard let prefs = userDefaults else { return true }
        let disabled = prefs.stringArray(forKey: "disabled_commands") ?? []
        return !disabled.contains(trigger.lowercased())
    }
}

