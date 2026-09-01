import Foundation

protocol AiProvider {
    var providerType: String { get }

    func transform(
        text: String,
        prompt: String,
        model: String,
        apiKey: String,
        baseURL: String?
    ) async throws -> String
}

