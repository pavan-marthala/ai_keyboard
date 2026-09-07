#include "flutter_window.h"

#include <optional>
#include <string>
#include <vector>
#include <iostream>

#include "flutter/generated_plugin_registrant.h"
#include "command_shortcut_manager.h"
#include "command_dispatcher.h"
#include "credential_store.h"
#include "configuration_store.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project, bool is_background)
    : project_(project), is_background_(is_background) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  SetupMethodChannels();

  // Start global shortcut manager and connect prompt window to dispatcher
  CommandShortcutManager::GetInstance().Start(GetHandle());
  atfix::CommandDispatcher::GetInstance().SetPromptWindow(
      &CommandShortcutManager::GetInstance().GetPromptWindow());

  if (!is_background_) {
    flutter_controller_->engine()->SetNextFrameCallback([&]() {
      this->Show();
    });
    flutter_controller_->ForceRedraw();
  }

  return true;
}

void FlutterWindow::SetupMethodChannels() {
  auto* messenger = flutter_controller_->engine()->messenger();
  auto* codec = &flutter::StandardMethodCodec::GetInstance();

  // Channel 1: com.pk.atfix/desktop and com.pk.ai_keyboard/desktop
  for (const auto& name : {"com.pk.atfix/desktop", "com.pk.ai_keyboard/desktop"}) {
    desktop_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        messenger, name, codec);

    desktop_channel_->SetMethodCallHandler(
        [](const flutter::MethodCall<flutter::EncodableValue>& call,
           std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
          const std::string& method = call.method_name();
          if (method == "isAccessibilityGranted") {
            result->Success(flutter::EncodableValue(true));
          } else if (method == "requestAccessibility") {
            result->Success(flutter::EncodableValue(true));
          } else if (method == "openAccessibilitySettings") {
            result->Success(flutter::EncodableValue(true));
          } else if (method == "getInputMonitoringStatus") {
            result->Success(flutter::EncodableValue(std::string("granted")));
          } else if (method == "isInputMonitoringGranted") {
            result->Success(flutter::EncodableValue(true));
          } else if (method == "requestInputMonitoring") {
            result->Success(flutter::EncodableValue(true));
          } else if (method == "openInputMonitoringSettings") {
            result->Success(flutter::EncodableValue(true));
          } else if (method == "quitAtFixCompletely") {
            ::PostQuitMessage(0);
            result->Success(flutter::EncodableValue(true));
          } else {
            result->NotImplemented();
          }
        });
  }

  // Channel 2: com.pk.atfix/credentials
  credentials_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "com.pk.atfix/credentials", codec);

  credentials_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        const std::string& method = call.method_name();

        if (method == "saveApiKey") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          std::string provider;
          std::string api_key;

          if (args) {
            auto it_p = args->find(flutter::EncodableValue("provider"));
            if (it_p != args->end() && std::holds_alternative<std::string>(it_p->second)) {
              provider = std::get<std::string>(it_p->second);
            }
            auto it_k = args->find(flutter::EncodableValue("apiKey"));
            if (it_k != args->end() && std::holds_alternative<std::string>(it_k->second)) {
              api_key = std::get<std::string>(it_k->second);
            }
          }

          bool success = atfix::CredentialStore::GetInstance().SaveApiKey(provider, api_key);
          result->Success(flutter::EncodableValue(success));

        } else if (method == "getApiKey") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          std::string provider;

          if (args) {
            auto it_p = args->find(flutter::EncodableValue("provider"));
            if (it_p != args->end() && std::holds_alternative<std::string>(it_p->second)) {
              provider = std::get<std::string>(it_p->second);
            }
          }

          std::string api_key = atfix::CredentialStore::GetInstance().ReadApiKey(provider);
          if (api_key.empty()) {
            result->Success(flutter::EncodableValue());
          } else {
            result->Success(flutter::EncodableValue(api_key));
          }

        } else if (method == "deleteApiKey") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          std::string provider;

          if (args) {
            auto it_p = args->find(flutter::EncodableValue("provider"));
            if (it_p != args->end() && std::holds_alternative<std::string>(it_p->second)) {
              provider = std::get<std::string>(it_p->second);
            }
          }

          bool success = atfix::CredentialStore::GetInstance().DeleteApiKey(provider);
          result->Success(flutter::EncodableValue(success));

        } else if (method == "hasApiKey") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          std::string provider;

          if (args) {
            auto it_p = args->find(flutter::EncodableValue("provider"));
            if (it_p != args->end() && std::holds_alternative<std::string>(it_p->second)) {
              provider = std::get<std::string>(it_p->second);
            }
          }

          bool has_key = atfix::CredentialStore::GetInstance().HasApiKey(provider);
          result->Success(flutter::EncodableValue(has_key));

        } else if (method == "saveConfig") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          std::string provider;
          std::string model_id;
          std::string base_url;

          if (args) {
            auto it_p = args->find(flutter::EncodableValue("provider"));
            if (it_p != args->end() && std::holds_alternative<std::string>(it_p->second)) {
              provider = std::get<std::string>(it_p->second);
            }
            auto it_m = args->find(flutter::EncodableValue("modelId"));
            if (it_m != args->end() && std::holds_alternative<std::string>(it_m->second)) {
              model_id = std::get<std::string>(it_m->second);
            }
            auto it_b = args->find(flutter::EncodableValue("baseUrl"));
            if (it_b != args->end() && std::holds_alternative<std::string>(it_b->second)) {
              base_url = std::get<std::string>(it_b->second);
            }
          }

          atfix::ConfigurationStore::GetInstance().SaveConfig(provider, model_id, base_url);
          result->Success(flutter::EncodableValue(true));

        } else if (method == "saveDisabledCommands") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          std::vector<std::string> disabled;

          if (args) {
            auto it_list = args->find(flutter::EncodableValue("disabledTriggers"));
            if (it_list != args->end() && std::holds_alternative<flutter::EncodableList>(it_list->second)) {
              const auto& list = std::get<flutter::EncodableList>(it_list->second);
              for (const auto& item : list) {
                if (std::holds_alternative<std::string>(item)) {
                  disabled.push_back(std::get<std::string>(item));
                }
              }
            }
          }

          atfix::ConfigurationStore::GetInstance().SaveDisabledCommands(disabled);
          result->Success(flutter::EncodableValue(true));

        } else {
          result->NotImplemented();
        }
      });
}

void FlutterWindow::OnDestroy() {
  CommandShortcutManager::GetInstance().Stop();
  desktop_channel_ = nullptr;
  credentials_channel_ = nullptr;

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Prevent Alt + Space from opening the system menu (which triggers interactive window sizing/moving mode)
  if (message == WM_SYSCOMMAND && (wparam & 0xFFF0) == SC_KEYMENU) {
    return 0;
  }
  if (message == WM_SYSKEYDOWN && wparam == VK_SPACE) {
    return 0;
  }

  if (message == WM_HOTKEY) {
    if (CommandShortcutManager::GetInstance().HandleHotKey(wparam, lparam)) {
      return 0;
    }
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
