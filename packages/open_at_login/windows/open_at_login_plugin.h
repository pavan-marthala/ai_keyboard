#ifndef FLUTTER_PLUGIN_OPEN_AT_LOGIN_PLUGIN_H_
#define FLUTTER_PLUGIN_OPEN_AT_LOGIN_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <windows.h>

#include <memory>
#include <string>
#include <vector>

namespace open_at_login {

class OpenAtLoginPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  OpenAtLoginPlugin();
  virtual ~OpenAtLoginPlugin();

  OpenAtLoginPlugin(const OpenAtLoginPlugin&) = delete;
  OpenAtLoginPlugin& operator=(const OpenAtLoginPlugin&) = delete;

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Command line and quoting utilities following Windows CommandLineToArgvW rules.
  static std::wstring QuoteArgument(const std::wstring& argument);
  static std::wstring BuildCommandLine(
      const std::wstring& app_path,
      const std::vector<std::wstring>& args);

  static std::wstring Utf8ToWide(const std::string& utf8_str);
  static std::string WideToUtf8(const std::wstring& wide_str);
  static std::string GetErrorMessage(DWORD error_code);

 private:
  void IsOpenAtLoginEnabled(
      const flutter::EncodableMap* arguments,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void SetOpenAtLoginEnabled(
      const flutter::EncodableMap* arguments,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace open_at_login

#endif  // FLUTTER_PLUGIN_OPEN_AT_LOGIN_PLUGIN_H_

