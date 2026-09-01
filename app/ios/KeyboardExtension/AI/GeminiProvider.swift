import Foundation

class GeminiProvider: AiProvider {
    let providerType = "gemini"

    func transform(
        text: String,
        prompt: String,
        model: String,
        apiKey: String,
        baseURL: String?
    ) async throws -> String {
        let cleanModel = model.hasPrefix("models/") ? String(model.dropFirst(7)) : model
        let endpoint: String
        if let base = baseURL, !base.isEmpty {
            endpoint = "\(base)/models/\(cleanModel):generateContent?key=\(apiKey)"
        } else {
            endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(cleanModel):generateContent?key=\(apiKey)"
        }

        guard let url = URL(string: endpoint) else { throw AiFailure.network }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15.0

        let fullPrompt = "\(prompt)\n\nText:\n\(text)"
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": fullPrompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.0
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw AiFailure.network }

        switch httpResponse.statusCode {
        case 200:
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let textResult = firstPart["text"] as? String else {
                throw AiFailure.invalidResponse
            }
            let trimmed = textResult.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { throw AiFailure.emptyResponse }
            return trimmed
        case 400, 401: throw AiFailure.invalidApiKey
        case 403: throw AiFailure.forbidden
        case 404: throw AiFailure.modelNotFound
        case 429: throw AiFailure.rateLimited
        case 500...599: throw AiFailure.server
        default: throw AiFailure.unknown("HTTP \(httpResponse.statusCode)")
        }
    }
}

