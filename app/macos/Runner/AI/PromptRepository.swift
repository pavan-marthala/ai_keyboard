import Foundation

public struct CommandDefinition: Equatable {
    public let id: String
    public let command: String
    public let label: String
    public let actionLabel: String
    public let order: Int
    public let requiresInput: Bool
    public let inputType: String?
    public let system: String

    public init(
        id: String,
        command: String,
        label: String,
        actionLabel: String,
        order: Int,
        requiresInput: Bool,
        inputType: String?,
        system: String
    ) {
        self.id = id
        self.command = command
        self.label = label
        self.actionLabel = actionLabel
        self.order = order
        self.requiresInput = requiresInput
        self.inputType = inputType
        self.system = system
    }
}

/// Repository responsible for loading and resolving canonical AI commands and prompts
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
    private var commandDefinitions: [CommandDefinition] = []
    private var commandsById: [String: CommandDefinition] = [:]
    private var commandsByTrigger: [String: CommandDefinition] = [:]

    public init(bundle: Bundle = Bundle.main) {
        let resolvedUrl = bundle.url(forResource: "ai_prompts", withExtension: "json")
            ?? Bundle.main.url(forResource: "ai_prompts", withExtension: "json")
            ?? Bundle(for: PromptRepository.self).url(forResource: "ai_prompts", withExtension: "json")

        if let url = resolvedUrl {
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

        if let commandsDict = root["commands"] as? [String: [String: Any]] {
            var parsedList: [CommandDefinition] = []
            var seenIds = Set<String>()
            var seenTriggers = Set<String>()

            for (rawKey, val) in commandsDict {
                let key = rawKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if key.isEmpty {
                    throw PromptError.invalidFormat("Command key cannot be empty")
                }
                if key == "pro" || key == "@pro" {
                    throw PromptError.invalidFormat("@pro is deprecated and not supported")
                }

                guard let rawCmd = val["command"] as? String else {
                    throw PromptError.invalidFormat("Missing command string for id '\(key)'")
                }
                let command = rawCmd.trimmingCharacters(in: .whitespacesAndNewlines)
                if !command.hasPrefix("@") {
                    throw PromptError.invalidFormat("Command syntax must start with '@': '\(command)'")
                }
                if command.lowercased() == "@pro" {
                    throw PromptError.invalidFormat("@pro is deprecated and not supported")
                }

                guard let label = val["label"] as? String, !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw PromptError.invalidFormat("Missing or empty label for id '\(key)'")
                }
                guard let actionLabel = val["actionLabel"] as? String, !actionLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw PromptError.invalidFormat("Missing or empty actionLabel for id '\(key)'")
                }
                guard let order = val["order"] as? Int, order > 0 else {
                    throw PromptError.invalidFormat("Order must be a positive integer for id '\(key)'")
                }

                let requiresInput = val["requiresInput"] as? Bool ?? false
                let inputType = val["inputType"] as? String
                if requiresInput && (inputType == nil || inputType!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                    throw PromptError.invalidFormat("Command '\(key)' requires input but inputType is empty")
                }

                guard let system = val["system"] as? String, !system.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw PromptError.invalidFormat("System prompt cannot be empty for id '\(key)'")
                }

                if !seenIds.insert(key).inserted {
                    throw PromptError.invalidFormat("Duplicate command id '\(key)'")
                }
                if !seenTriggers.insert(command.lowercased()).inserted {
                    throw PromptError.invalidFormat("Duplicate command trigger '\(command)'")
                }

                let def = CommandDefinition(
                    id: key,
                    command: command,
                    label: label.trimmingCharacters(in: .whitespacesAndNewlines),
                    actionLabel: actionLabel.trimmingCharacters(in: .whitespacesAndNewlines),
                    order: order,
                    requiresInput: requiresInput,
                    inputType: inputType?.trimmingCharacters(in: .whitespacesAndNewlines),
                    system: system
                )
                parsedList.append(def)
            }

            guard seenIds.contains("professional") && seenTriggers.contains("@professional") else {
                throw PromptError.invalidFormat("Canonical command @professional must be present")
            }

            parsedList.sort { $0.order < $1.order }

            commandDefinitions = parsedList
            commandsById.removeAll()
            commandsByTrigger.removeAll()
            prompts.removeAll()

            for def in parsedList {
                commandsById[def.id] = def
                commandsByTrigger[def.command.lowercased()] = def
                prompts[def.id] = def.system
            }
        } else if let promptsDict = root["prompts"] as? [String: [String: Any]] {
            // Legacy schema v1 fallback
            prompts.removeAll()
            commandDefinitions.removeAll()
            commandsById.removeAll()
            commandsByTrigger.removeAll()

            for (key, val) in promptsDict {
                if let system = val["system"] as? String {
                    prompts[key] = system
                }
            }
        } else {
            throw PromptError.invalidFormat("Missing 'commands' or 'prompts' dictionary in JSON")
        }
    }

    public func getCommands() -> [CommandDefinition] {
        return commandDefinitions
    }

    public func command(for triggerOrId: String) -> CommandDefinition? {
        let clean = triggerOrId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let base = clean.contains(":") ? String(clean.split(separator: ":")[0]) : clean
        if base == "@pro" || base == "pro" { return nil }
        return commandsByTrigger[base] ?? commandsById[base]
    }

    public func actionLabel(for triggerOrId: String) -> String {
        return command(for: triggerOrId)?.actionLabel ?? "Transforming..."
    }

    /// Resolves the prompt for [key], interpolating variables like `{{variable}}`.
    ///
    /// - Parameters:
    ///   - key: The prompt key or command trigger (e.g. "fix", "@rewrite", "translate").
    ///   - variables: Key-value pairs to interpolate into placeholders.
    /// - Returns: The resolved system prompt.
    /// - Throws: `PromptError.unknownKey` if key is not found.
    public func getPrompt(_ key: String, variables: [String: String] = [:]) throws -> String {
        let clean = key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let base = clean.contains(":") ? String(clean.split(separator: ":")[0]) : clean
        if base == "@pro" || base == "pro" {
            throw PromptError.unknownKey(key)
        }

        let template: String
        if let direct = prompts[base] {
            template = direct
        } else if let cmd = command(for: base) {
            template = cmd.system
        } else {
            throw PromptError.unknownKey(key)
        }

        var result = template
        for (varName, varVal) in variables {
            result = result.replacingOccurrences(of: "{{\(varName)}}", with: varVal)
        }
        return result
    }

    public func hasPrompt(_ key: String) -> Bool {
        let clean = key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let base = clean.contains(":") ? String(clean.split(separator: ":")[0]) : clean
        if base == "@pro" || base == "pro" { return false }
        return prompts[base] != nil || command(for: base) != nil
    }
}
