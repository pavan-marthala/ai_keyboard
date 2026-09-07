#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>

#include "win32_window.h"

// A window that hosts a Flutter view and bridges desktop method channels.
// Strictly mirrors macOS AppDelegate.swift channels (desktop, credentials).
class FlutterWindow : public Win32Window {
 public:
  explicit FlutterWindow(const flutter::DartProject& project, bool is_background = false);
  virtual ~FlutterWindow();

  void SetIsBackground(bool is_background) { is_background_ = is_background; }

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  void SetupMethodChannels();

  flutter::DartProject project_;
  bool is_background_ = false;

  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> desktop_channel_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> credentials_channel_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
