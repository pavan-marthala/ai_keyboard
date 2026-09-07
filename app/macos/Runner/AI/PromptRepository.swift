import Foundation

/// Repository responsible for loading and resolving canonical AI prompts
/// from the bundled `ai_prompts.json`.
public final class PromptRepository {

    public static let shared = PromptRepository()

    public static let supportedLanguages: [String: String] = [
        "en": "English",
        "es": "Spanish",
        "fr": "French",
        "de": "German",
        "it": "Italian",
        "pt": "Portuguese",
        "hi": "Hindi",
        "te": "Telugu",
        "kn": "Kannada",
        "ta": "Tamil"
    ]

    public enum PromptError: LocalizedError {
        case fileNotFound
        case invalidFormat(String)
        case unknownKey(String)

        public var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "ai_prompts.json could not be found in the bundle."
            case .invalidFormat(let reason):
                return "ai_prompts.json is malformed: \(reason)"
            case .unknownKey(let key):
                return "Unknown prompt key: '\(key)'"
            }
        }
    }

    private var prompts: [String: String] = [:]

    public init(bundle: Bundle = Bundle.main) {
        if let url = bundle.url(forResource: "ai_prompts", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                try parse(data: data)
            } catch {
                NSLog("[PromptRepository] Error loading ai_prompts.json: \(error.localizedDescription)")
            }
        } else {
            NSLog("[PromptRepository] Warning: ai_prompts.json not found in bundle \(bundle)")
        }
    }

    public init(jsonString: String) throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw PromptError.invalidFormat("Cannot decode JSON string as UTF-8")
        }
        try parse(data: data)
    }

    public init(data: Data) throws {
        try parse(data: data)
    }

    private func parse(data: Data) throws {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PromptError.invalidFormat("Root must be a JSON object")
        }
        guard let promptsDict = root["prompts"] as? [String: [String: Any]] else {
            throw PromptError.invalidFormat("Missing 'prompts' dictionary in JSON")
        }

        for (key, val) in promptsDict {
            if let system = val["system"] as? String {
                prompts[key] = system
            }
        }
    }

    /// Resolves the prompt for [key], interpolating variables like `{{variable}}`.
    ///
    /// - Parameters:
    ///   - key: The prompt key (e.g. "fix", "rewrite", "translate").
    ///   - variables: Key-value pairs to interpolate into placeholders.
    /// - Returns: The resolved system prompt.
    /// - Throws: `PromptError.unknownKey` if key is not found.
    public func getPrompt(_ key: String, variables: [String: String] = [:]) throws -> String {
        guard let template = prompts[key] else {
            throw PromptError.unknownKey(key)
        }

        var result = template
        for (varName, varVal) in variables {
            result = result.replacingOccurrences(of: "{{\(varName)}}", with: varVal)
        }
        return result
    }

    public func hasPrompt(_ key: String) -> Bool {
        return prompts[key] != nil
    }
}
