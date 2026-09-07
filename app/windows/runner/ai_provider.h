#ifndef RUNNER_AI_PROVIDER_H_
#define RUNNER_AI_PROVIDER_H_

#include <string>
#include <stdexcept>

namespace atfix {

class AiFailure : public std::runtime_error {
 public:
  enum class Type {
    kMissingApiKey,
    kInvalidApiKey,
    kUnauthorized,
    kRateLimited,
    kTimeout,
    kNetwork,
    kServer,
    kDisabledCommand,
    kTextTooLong,
    kUnknown
  };

  AiFailure(Type type, const std::string& message)
      : std::runtime_error(message), type_(type), message_(message) {}

  Type GetType() const { return type_; }
  const std::string& GetUserMessage() const { return message_; }

  static AiFailure MissingApiKey() {
    return AiFailure(Type::kMissingApiKey, "API key missing. Please configure your API key in Settings.");
  }

  static AiFailure DisabledCommand(const std::string& cmd) {
    return AiFailure(Type::kDisabledCommand, "Command '" + cmd + "' is currently disabled in Settings.");
  }

  static AiFailure TextTooLong() {
    return AiFailure(Type::kTextTooLong, "The selected text exceeds the maximum character limit (4000 characters).");
  }

  static AiFailure Network(const std::string& detail = "") {
    return AiFailure(Type::kNetwork, detail.empty() ? "Network connection error. Please verify your internet connection." : detail);
  }

  static AiFailure Timeout() {
    return AiFailure(Type::kTimeout, "Request timed out. Please check your network connection.");
  }

  static AiFailure Unauthorized() {
    return AiFailure(Type::kUnauthorized, "Unauthorized request. Please verify your API key.");
  }

 private:
  Type type_;
  std::string message_;
};

class AiProvider {
 public:
  virtual ~AiProvider() = default;
  virtual std::string GetProviderType() const = 0;
  virtual std::string Transform(
      const std::string& text,
      const std::string& prompt,
      const std::string& model,
      const std::string& api_key,
      const std::string& base_url
  ) = 0;
};

}  // namespace atfix

#endif  // RUNNER_AI_PROVIDER_H_

