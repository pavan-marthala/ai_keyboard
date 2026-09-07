#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Single instance check via named Mutex
  HANDLE h_mutex = ::CreateMutexW(nullptr, TRUE, L"AtFix_SingleInstance_Mutex_PK");
  if (::GetLastError() == ERROR_ALREADY_EXISTS) {
    // Another instance is already running. Wake up and restore its window.
    HWND existing_hwnd = ::FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"AtFix");
    if (existing_hwnd) {
      UINT wm_show = ::RegisterWindowMessageW(L"WM_SHOW_ATFIX_SINGLE_INSTANCE");
      ::PostMessageW(existing_hwnd, wm_show, 0, 0);
      ::ShowWindow(existing_hwnd, SW_SHOW);
      ::ShowWindow(existing_hwnd, SW_RESTORE);
      ::SetForegroundWindow(existing_hwnd);
    }
    if (h_mutex) ::CloseHandle(h_mutex);
    return EXIT_SUCCESS;
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  bool is_background = false;
  for (const auto& arg : command_line_arguments) {
    if (arg == "--background") {
      is_background = true;
      break;
    }
  }

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project, is_background);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"AtFix", origin, size)) {
    if (h_mutex) {
      ::ReleaseMutex(h_mutex);
      ::CloseHandle(h_mutex);
    }
    ::CoUninitialize();
    return EXIT_FAILURE;
  }
  // Mirror macOS: do NOT quit on window close; hide and continue running in background.
  window.SetQuitOnClose(false);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  if (h_mutex) {
    ::ReleaseMutex(h_mutex);
    ::CloseHandle(h_mutex);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
