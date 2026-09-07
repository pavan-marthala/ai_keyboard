#ifndef RUNNER_CREDENTIAL_STORE_H_
#define RUNNER_CREDENTIAL_STORE_H_

#include <string>

namespace atfix {

/// Windows Credential Manager storage for AI provider API credentials.
///
/// Uses Windows Credential Manager API (wincred.h: CredWriteW, CredReadW, CredDeleteW)
/// to securely persist and retrieve API keys under target "AtFix/<provider>".
/// Strictly mirrors macOS KeychainCredentialStore.swift.
class CredentialStore {
 public:
  static CredentialStore& GetInstance();

  CredentialStore(const CredentialStore&) = delete;
  CredentialStore& operator=(const CredentialStore&) = delete;

  /// Saves or updates the API key for `provider`.
  bool SaveApiKey(const std::string& provider, const std::string& api_key);

  /// Reads the API key for `provider` from Windows Credential Manager.
  std::string ReadApiKey(const std::string& provider);

  /// Deletes the API key for `provider`.
  bool DeleteApiKey(const std::string& provider);

  /// Checks if a non-empty API key exists for `provider`.
  bool HasApiKey(const std::string& provider);

 private:
  CredentialStore() = default;
  ~CredentialStore() = default;

  std::wstring BuildTargetName(const std::string& provider);
};

}  // namespace atfix

#endif  // RUNNER_CREDENTIAL_STORE_H_

