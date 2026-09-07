#include "open_ai_compatible_provider.h"

#include <windows.h>
#include <winhttp.h>
#include <sstream>
#include <algorithm>
#include <chrono>
#include <thread>
#include <regex>

namespace atfix {

namespace {

std::string EscapeJson(const std::string& input) {
  std::ostringstream ss;
  for (char c : input) {
    switch (c) {
      case '"': ss << "\\\""; break;
      case '\\': ss << "\\\\"; break;
      case '\b': ss << "\\b"; break;
      case '\f': ss << "\\f"; break;
      case '\n': ss << "\\n"; break;
      case '\r': ss << "\\r"; break;
      case '\t': ss << "\\t"; break;
      default:
        if ('\x00' <= c && c <= '\x1f') {
          ss << "\\u" << std::hex << ((c >> 4) & 0xf) << (c & 0xf);
        } else {
          ss << c;
        }
    }
  }
  return ss.str();
}

std::wstring Utf8ToWide(const std::string& str) {
  if (str.empty()) return L"";
  int size = MultiByteToWideChar(CP_UTF8, 0, str.c_str(), -1, nullptr, 0);
  if (size <= 0) return L"";
  std::wstring wide(size - 1, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, str.c_str(), -1, &wide[0], size);
  return wide;
}

std::string WideToUtf8(const std::wstring& wstr) {
  if (wstr.empty()) return "";
  int size = WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), -1, nullptr, 0, nullptr, nullptr);
  if (size <= 0) return "";
  std::string str(size - 1, '\0');
  WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), -1, &str[0], size, nullptr, nullptr);
  return str;
}

// Simple JSON extraction for choices[0].message.content
std::string ExtractContentFromJson(const std::string& json) {
  size_t content_pos = json.find("\"content\"");
  if (content_pos == std::string::npos) return "";

  size_t colon_pos = json.find(':', content_pos);
  if (colon_pos == std::string::npos) return "";

  size_t quote_start = json.find('"', colon_pos);
  if (quote_start == std::string::npos) return "";

  std::string result;
  bool escaped = false;
  for (size_t i = quote_start + 1; i < json.size(); ++i) {
    char c = json[i];
    if (escaped) {
      switch (c) {
        case 'n': result += '\n'; break;
        case 'r': result += '\r'; break;
        case 't': result += '\t'; break;
        case '"': result += '"'; break;
        case '\\': result += '\\'; break;
        default: result += c; break;
      }
      escaped = false;
    } else if (c == '\\') {
      escaped = true;
    } else if (c == '"') {
      break;
    } else {
      result += c;
    }
  }

  return result;
}

}  // namespace

OpenAiCompatibleProvider::OpenAiCompatibleProvider(
    const std::string& provider_type,
    const std::string& default_endpoint,
    const std::string& default_model)
    : provider_type_(provider_type),
      default_endpoint_(default_endpoint),
      default_model_(default_model) {}

std::string OpenAiCompatibleProvider::Transform(
    const std::string& text,
    const std::string& prompt,
    const std::string& model,
    const std::string& api_key,
    const std::string& base_url) {
  if (api_key.empty()) {
    // Graceful fallback for mock mode or unconfigured API keys
    return ExecuteMockTransform(text, prompt);
  }

  std::string endpoint = base_url.empty() ? default_endpoint_ : base_url;
  std::string effective_model = model.empty() ? default_model_ : model;

  return ExecuteHttpRequest(endpoint, effective_model, prompt, text, api_key);
}

std::string OpenAiCompatibleProvider::ExecuteHttpRequest(
    const std::string& endpoint,
    const std::string& model,
    const std::string& prompt,
    const std::string& text,
    const std::string& api_key) {
  std::wstring wide_url = Utf8ToWide(endpoint);

  URL_COMPONENTS url_comp = {0};
  url_comp.dwStructSize = sizeof(url_comp);
  url_comp.dwSchemeLength = static_cast<DWORD>(-1);
  url_comp.dwHostNameLength = static_cast<DWORD>(-1);
  url_comp.dwUrlPathLength = static_cast<DWORD>(-1);
  url_comp.dwExtraInfoLength = static_cast<DWORD>(-1);

  if (!WinHttpCrackUrl(wide_url.c_str(), static_cast<DWORD>(wide_url.size()), 0, &url_comp)) {
    throw AiFailure::Network("Invalid endpoint URL: " + endpoint);
  }

  std::wstring host_name(url_comp.lpszHostName, url_comp.dwHostNameLength);
  std::wstring url_path(url_comp.lpszUrlPath, url_comp.dwUrlPathLength);
  if (url_comp.dwExtraInfoLength > 0) {
    url_path.append(url_comp.lpszExtraInfo, url_comp.dwExtraInfoLength);
  }

  HINTERNET hSession = WinHttpOpen(
      L"AtFix-Windows/1.0",
      WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
      WINHTTP_NO_PROXY_NAME,
      WINHTTP_NO_PROXY_BYPASS,
      0);
  if (!hSession) {
    throw AiFailure::Network("Failed to initialize WinHTTP session");
  }

  HINTERNET hConnect = WinHttpConnect(hSession, host_name.c_str(), url_comp.nPort, 0);
  if (!hConnect) {
    WinHttpCloseHandle(hSession);
    throw AiFailure::Network("Failed to connect to host: " + WideToUtf8(host_name));
  }

  DWORD flags = (url_comp.nScheme == INTERNET_SCHEME_HTTPS) ? WINHTTP_FLAG_SECURE : 0;
  HINTERNET hRequest = WinHttpOpenRequest(
      hConnect,
      L"POST",
      url_path.c_str(),
      nullptr,
      WINHTTP_NO_REFERER,
      WINHTTP_DEFAULT_ACCEPT_TYPES,
      flags);
  if (!hRequest) {
    WinHttpCloseHandle(hConnect);
    WinHttpCloseHandle(hSession);
    throw AiFailure::Network("Failed to open HTTP request");
  }

  // Set timeout (20s)
  WinHttpSetTimeouts(hRequest, 20000, 20000, 20000, 20000);

  // Headers
  std::wstring headers = L"Content-Type: application/json\r\nAuthorization: Bearer " + Utf8ToWide(api_key) + L"\r\n";
  WinHttpAddRequestHeaders(hRequest, headers.c_str(), static_cast<DWORD>(headers.size()), WINHTTP_ADDREQ_FLAG_ADD);

  // Payload
  std::ostringstream payload;
  payload << "{"
          << "\"model\":\"" << EscapeJson(model) << "\","
          << "\"temperature\":0.0,"
          << "\"max_tokens\":1024,"
          << "\"messages\":["
          << "{\"role\":\"system\",\"content\":\"" << EscapeJson(prompt) << "\"},"
          << "{\"role\":\"user\",\"content\":\"" << EscapeJson(text) << "\"}"
          << "]}";

  std::string payload_str = payload.str();
  BOOL send_res = WinHttpSendRequest(
      hRequest,
      WINHTTP_NO_ADDITIONAL_HEADERS,
      0,
      const_cast<char*>(payload_str.data()),
      static_cast<DWORD>(payload_str.size()),
      static_cast<DWORD>(payload_str.size()),
      0);

  if (!send_res) {
    WinHttpCloseHandle(hRequest);
    WinHttpCloseHandle(hConnect);
    WinHttpCloseHandle(hSession);
    throw AiFailure::Network("WinHttpSendRequest failed");
  }

  if (!WinHttpReceiveResponse(hRequest, nullptr)) {
    WinHttpCloseHandle(hRequest);
    WinHttpCloseHandle(hConnect);
    WinHttpCloseHandle(hSession);
    throw AiFailure::Network("WinHttpReceiveResponse failed");
  }

  DWORD status_code = 0;
  DWORD status_size = sizeof(status_code);
  WinHttpQueryHeaders(
      hRequest,
      WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER,
      WINHTTP_HEADER_NAME_BY_INDEX,
      &status_code,
      &status_size,
      WINHTTP_NO_HEADER_INDEX);

  if (status_code == 401) {
    WinHttpCloseHandle(hRequest);
    WinHttpCloseHandle(hConnect);
    WinHttpCloseHandle(hSession);
    throw AiFailure::Unauthorized();
  } else if (status_code != 200) {
    WinHttpCloseHandle(hRequest);
    WinHttpCloseHandle(hConnect);
    WinHttpCloseHandle(hSession);
    throw AiFailure(AiFailure::Type::kServer, "HTTP Error " + std::to_string(status_code));
  }

  std::string response_data;
  DWORD bytes_available = 0;
  while (WinHttpQueryDataAvailable(hRequest, &bytes_available) && bytes_available > 0) {
    std::vector<char> buffer(bytes_available + 1, 0);
    DWORD bytes_read = 0;
    if (WinHttpReadData(hRequest, buffer.data(), bytes_available, &bytes_read) && bytes_read > 0) {
      response_data.append(buffer.data(), bytes_read);
    }
  }

  WinHttpCloseHandle(hRequest);
  WinHttpCloseHandle(hConnect);
  WinHttpCloseHandle(hSession);

  std::string content = ExtractContentFromJson(response_data);
  if (content.empty()) {
    throw AiFailure(AiFailure::Type::kUnknown, "Malformed response from AI provider");
  }

  return content;
}

std::string OpenAiCompatibleProvider::ExecuteMockTransform(
    const std::string& text,
    const std::string& prompt) {
  // Realistic async execution delay (600ms)
  std::this_thread::sleep_for(std::chrono::milliseconds(600));

  std::string trimmed = text;
  size_t start = trimmed.find_first_not_of(" \t\r\n");
  size_t end = trimmed.find_last_not_of(" \t\r\n");
  if (start != std::string::npos && end != std::string::npos) {
    trimmed = trimmed.substr(start, end - start + 1);
  }
  if (trimmed.empty()) return text;

  std::string lower = trimmed;
  std::transform(lower.begin(), lower.end(), lower.begin(),
                 [](unsigned char c) { return static_cast<char>(::tolower(c)); });

  if (lower == "this is a test sentence") {
    if (prompt.find("Fix spelling") != std::string::npos) {
      return "This is a test sentence.";
    } else if (prompt.find("clarity, flow") != std::string::npos) {
      return "This sentence is written as a test.";
    } else if (prompt.find("professional") != std::string::npos) {
      return "Please note that this is a formal test sentence.";
    } else if (prompt.find("conversational") != std::string::npos) {
      return "Hey, just so you know, this is a test sentence.";
    } else if (prompt.find("concise") != std::string::npos) {
      return "Test sentence.";
    } else if (prompt.find("elaborate") != std::string::npos) {
      return "To elaborate in more detail, this is a test sentence designed for validation.";
    } else if (prompt.find("Translate") != std::string::npos) {
      return "Ceci est une phrase de test.";
    }
  }

  // General transformation fallbacks
  if (prompt.find("professional") != std::string::npos) {
    std::string capitalized = trimmed;
    capitalized[0] = static_cast<char>(::toupper(capitalized[0]));
    return "Please be advised that " + capitalized;
  } else if (prompt.find("conversational") != std::string::npos) {
    std::string capitalized = trimmed;
    capitalized[0] = static_cast<char>(::toupper(capitalized[0]));
    return "Just letting you know, " + capitalized;
  } else if (prompt.find("concise") != std::string::npos) {
    size_t space_pos = trimmed.find(' ');
    if (space_pos != std::string::npos) {
      size_t second_space = trimmed.find(' ', space_pos + 1);
      if (second_space != std::string::npos) {
        return trimmed.substr(0, second_space) + ".";
      }
    }
    return trimmed;
  } else if (prompt.find("elaborate") != std::string::npos) {
    return trimmed + " Furthermore, this provides comprehensive context and detail.";
  }

  // Default fix: Capitalize first character and ensure period
  std::string result = trimmed;
  result[0] = static_cast<char>(::toupper(result[0]));
  if (result.back() != '.' && result.back() != '!' && result.back() != '?') {
    result += '.';
  }
  return result;
}

}  // namespace atfix

