import Foundation

/// OpenAI-compatible Chat Completions Provider for macOS.
/// Supports OpenAI, OpenRouter, and Groq REST APIs.
class OpenAiCompatibleProvider: AiProvider {
    let providerType: String
    let defaultEndpoint: String
    let defaultModel: String

    init(
        providerType: String = "openai",
        defaultEndpoint: String = "https://api.openai.com/v1/chat/completions",
        defaultModel: String = "gpt-4o-mini"
    ) {
        self.providerType = providerType
        self.defaultEndpoint = defaultEndpoint
        self.defaultModel = defaultModel
    }

    func transform(
        text: String,
        prompt: String,
        model: String,
        apiKey: String,
        baseURL: String?
    ) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AiFailure.missingApiKey
        }

        // Endpoint selection: custom base URL takes priority if non-empty
        let rawEndpoint: String
        if let base = baseURL?.trimmingCharacters(in: .whitespacesAndNewlines), !base.isEmpty {
            rawEndpoint = base
        } else {
            rawEndpoint = defaultEndpoint
        }

        guard let url = URL(string: rawEndpoint) else {
            throw AiFailure.network
        }

        // Effective model ID selection
        let effectiveModel = model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? defaultModel : model

        // Build URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 20.0

        let systemInstruction = """
You are a text transformation engine inside a keyboard.
Return only the transformed text.
Do not add explanations, notes, quotes, or markdown.
Preserve the user's intended meaning.
"""

        let userContent = prompt.isEmpty ? text : "\(prompt)\n\nText:\n\(text)"

        // Build Payload
        let payload: [String: Any] = [
            "model": effectiveModel,
            "temperature": 0.0,
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "system",
                    "content": systemInstruction
                ],
                [
                    "role": "user",
                    "content": userContent
                ]
            ]
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            throw AiFailure.invalidResponse
        }
        request.httpBody = httpBody

        // Execute network request
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .timedOut:
                throw AiFailure.timeout
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
                throw AiFailure.network
            default:
                throw AiFailure.network
            }
        } catch {
            throw AiFailure.unknown(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AiFailure.network
        }

        // Handle HTTP Status Codes
        switch httpResponse.statusCode {
        case 200:
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw AiFailure.invalidResponse
            }

            var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)

            // Remove surrounding quotes if the model wrapped the result in quotes
            if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") && cleaned.count >= 2 {
                cleaned.removeFirst()
                cleaned.removeLast()
                cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            if cleaned.isEmpty {
                throw AiFailure.emptyResponse
            }

            return cleaned

        case 401:
            throw AiFailure.invalidApiKey
        case 403:
            throw AiFailure.forbidden
        case 404:
            throw AiFailure.modelNotFound
        case 429:
            throw AiFailure.rateLimited
        case 500...599:
            let serverMsg = String(data: data, encoding: .utf8) ?? "Server Error"
            throw AiFailure.server(httpResponse.statusCode, serverMsg)
        default:
            throw AiFailure.unknown("HTTP \(httpResponse.statusCode)")
        }
    }
}

