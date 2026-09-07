#include "credential_store.h"

#include <windows.h>
#include <wincred.h>
#include <algorithm>

namespace atfix {

CredentialStore& CredentialStore::GetInstance() {
  static CredentialStore instance;
  return instance;
}

std::wstring CredentialStore::BuildTargetName(const std::string& provider) {
  std::string lower_provider = provider;
  std::transform(lower_provider.begin(), lower_provider.end(), lower_provider.begin(),
                 [](unsigned char c) { return static_cast<char>(::tolower(c)); });
  
  // Trim spaces
  size_t start = lower_provider.find_first_not_of(" \t\r\n");
  size_t end = lower_provider.find_last_not_of(" \t\r\n");
  if (start != std::string::npos && end != std::string::npos) {
    lower_provider = lower_provider.substr(start, end - start + 1);
  }

  std::wstring target = L"AtFix/" + std::wstring(lower_provider.begin(), lower_provider.end());
  return target;
}

bool CredentialStore::SaveApiKey(const std::string& provider, const std::string& api_key) {
  if (provider.empty() || api_key.empty()) return false;

  std::wstring target = BuildTargetName(provider);
  std::wstring user_name(provider.begin(), provider.end());

  CREDENTIALW cred = {0};
  cred.Flags = 0;
  cred.Type = CRED_TYPE_GENERIC;
  cred.TargetName = const_cast<LPWSTR>(target.c_str());
  cred.CredentialBlobSize = static_cast<DWORD>(api_key.size());
  cred.CredentialBlob = reinterpret_cast<LPBYTE>(const_cast<char*>(api_key.data()));
  cred.Persist = CRED_PERSIST_LOCAL_MACHINE;
  cred.UserName = const_cast<LPWSTR>(user_name.c_str());

  BOOL result = CredWriteW(&cred, 0);
  return result == TRUE;
}

std::string CredentialStore::ReadApiKey(const std::string& provider) {
  if (provider.empty()) return "";

  std::wstring target = BuildTargetName(provider);
  PCREDENTIALW pCred = nullptr;

  if (CredReadW(target.c_str(), CRED_TYPE_GENERIC, 0, &pCred)) {
    std::string api_key;
    if (pCred->CredentialBlob && pCred->CredentialBlobSize > 0) {
      api_key.assign(reinterpret_cast<const char*>(pCred->CredentialBlob), pCred->CredentialBlobSize);
    }
    CredFree(pCred);
    return api_key;
  }

  return "";
}

bool CredentialStore::DeleteApiKey(const std::string& provider) {
  if (provider.empty()) return false;

  std::wstring target = BuildTargetName(provider);
  return CredDeleteW(target.c_str(), CRED_TYPE_GENERIC, 0) == TRUE;
}

bool CredentialStore::HasApiKey(const std::string& provider) {
  std::string key = ReadApiKey(provider);
  return !key.empty();
}

}  // namespace atfix
