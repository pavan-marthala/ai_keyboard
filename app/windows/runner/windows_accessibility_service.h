#ifndef RUNNER_WINDOWS_ACCESSIBILITY_SERVICE_H_
#define RUNNER_WINDOWS_ACCESSIBILITY_SERVICE_H_

#include <windows.h>
#include <string>

struct TargetWindowInfo {
  HWND hwnd = nullptr;
  DWORD pid = 0;
  std::wstring window_title;
  std::wstring process_name;
};

class WindowsAccessibilityService {
 public:
  static WindowsAccessibilityService& GetInstance();

  /// Captures metadata about the currently active foreground window.
  TargetWindowInfo GetForegroundTarget();

  /// Retrieves the selected text in the given target window.
  /// Uses Windows UI Automation with synthetic copy fallback.
  std::wstring GetSelectedText(HWND target_hwnd);

 private:
  WindowsAccessibilityService();
  ~WindowsAccessibilityService();

  std::wstring GetSelectedTextViaUia(HWND target_hwnd);
  std::wstring GetSelectedTextViaClipboard(HWND target_hwnd);
};

#endif  // RUNNER_WINDOWS_ACCESSIBILITY_SERVICE_H_

