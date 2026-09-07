#ifndef RUNNER_WINDOWS_TEXT_REPLACEMENT_SERVICE_H_
#define RUNNER_WINDOWS_TEXT_REPLACEMENT_SERVICE_H_

#include <windows.h>
#include <string>

class WindowsTextReplacementService {
 public:
  static WindowsTextReplacementService& GetInstance();

  /// Reactivates the target application and replaces the selected text with transformed_text.
  bool ReplaceSelectedText(HWND target_hwnd, DWORD target_pid, const std::wstring& transformed_text);

 private:
  WindowsTextReplacementService();
  ~WindowsTextReplacementService();

  bool ReactivateTarget(HWND target_hwnd, DWORD timeout_ms = 500);
  bool TypeReplacement(const std::wstring& text);
  bool PasteReplacement(const std::wstring& text);
};

#endif  // RUNNER_WINDOWS_TEXT_REPLACEMENT_SERVICE_H_

