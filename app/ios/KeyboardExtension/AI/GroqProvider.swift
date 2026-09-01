import Foundation

class GroqProvider: AiProvider {
    let providerType = "groq"

    func transform(
        text: String,
        prompt: String,
        model: String,
        apiKey: String,
        baseURL: String?
    ) async throws -> String {
        let endpoint = (baseURL?.isEmpty == false) ? baseURL! : "https://api.groq.com/openai/v1/chat/completions"
        guard let url = URL(string: endpoint) else { throw AiFailure.network }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15.0

        let systemInstruction = "You are a text transformation engine. Transform the text according to instructions. Return ONLY the transformed text. Do not explain, add notes, or use surrounding quotes."

        let body: [String: Any] = [
            "model": model,
            "temperature": 0.0,
            "messages": [
                ["role": "system", "content": systemInstruction],
                ["role": "user", "content": "\(prompt)\n\nText:\n\(text)"]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw AiFailure.network }

        switch httpResponse.statusCode {
        case 200:
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw AiFailure.invalidResponse
            }
            let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { throw AiFailure.emptyResponse }
            return trimmed
        case 401: throw AiFailure.invalidApiKey
        case 403: throw AiFailure.forbidden
        case 404: throw AiFailure.modelNotFound
        case 429: throw AiFailure.rateLimited
        case 500...599: throw AiFailure.server
        default: throw AiFailure.unknown("HTTP \(httpResponse.statusCode)")
        }
    }
}

