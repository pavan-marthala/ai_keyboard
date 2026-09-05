import Foundation

enum AiFailure: Error {
    case missingApiKey
    case invalidApiKey
    case unauthorized
    case forbidden
    case modelNotFound
    case rateLimited
    case timeout
    case network
    case server
    case invalidResponse
    case emptyResponse
    case cancelled
    case contextChanged
    case textTooLong
    case unknown(String)

    var userMessage: String {
        switch self {
        case .missingApiKey: return "⚠️ API key missing"
        case .invalidApiKey, .unauthorized: return "⚠️ Invalid API Key"
        case .forbidden: return "⚠️ Access Denied"
        case .modelNotFound: return "⚠️ Model Not Found"
        case .rateLimited: return "⚠️ Rate Limited"
        case .timeout: return "⚠️ Request Timed Out"
        case .network: return "⚠️ Network Error"
        case .server: return "⚠️ Provider Error"
        case .invalidResponse, .emptyResponse: return "⚠️ Empty AI Response"
        case .cancelled, .contextChanged: return "✨ AtFix"
        case .textTooLong: return "⚠️ Text Too Long"
        case .unknown(let msg): return "⚠️ Error: \(msg)"
        }
    }
}

