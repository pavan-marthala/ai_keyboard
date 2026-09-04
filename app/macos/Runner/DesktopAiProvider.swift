import Foundation

/// Native macOS AI Provider Protocol.
protocol DesktopAiProvider {
    var providerType: String { get }

    func transform(
        text: String,
        prompt: String,
        model: String,
        apiKey: String,
        baseURL: String?
    ) async throws -> String
}

/// Typed failures for macOS desktop AI operations.
enum DesktopAiFailure: Error, LocalizedError, Equatable {
    case missingApiKey
    case invalidApiKey
    case unauthorized
    case forbidden
    case modelNotFound
    case rateLimited
    case timeout
    case network
    case server(Int, String)
    case invalidResponse
    case emptyResponse
    case disabledCommand(String)
    case textTooLong
    case unsupportedProvider(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "API key missing. Please configure your API key in Settings."
        case .invalidApiKey:
            return "Invalid API key. Please check your credentials in Settings."
        case .unauthorized:
            return "Unauthorized request. Please verify your API key."
        case .forbidden:
            return "Access forbidden. You may not have access to this model or provider."
        case .modelNotFound:
            return "Model not found. Please verify the configured model name."
        case .rateLimited:
            return "Rate limit exceeded. Please wait a moment and try again."
        case .timeout:
            return "Request timed out. Please check your network connection."
        case .network:
            return "Network connection error. Please verify your internet connection."
        case .server(let code, let msg):
            return "AI provider server error (HTTP \(code)): \(msg)"
        case .invalidResponse:
            return "Received an invalid or malformed response from the AI provider."
        case .emptyResponse:
            return "The AI provider returned an empty response."
        case .disabledCommand(let cmd):
            return "Command '\(cmd)' is currently disabled in Settings."
        case .textTooLong:
            return "The selected text exceeds the maximum character limit (4000 characters)."
        case .unsupportedProvider(let provider):
            return "Provider '\(provider)' is not supported on macOS."
        case .unknown(let msg):
            return "Unexpected error: \(msg)"
        }
    }
}

