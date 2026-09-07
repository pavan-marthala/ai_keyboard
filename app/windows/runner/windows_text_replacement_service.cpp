#include "windows_text_replacement_service.h"

#include <vector>

WindowsTextReplacementService& WindowsTextReplacementService::GetInstance() {
  static WindowsTextReplacementService instance;
  return instance;
}

WindowsTextReplacementService::WindowsTextReplacementService() {}

WindowsTextReplacementService::~WindowsTextReplacementService() {}

bool WindowsTextReplacementService::ReplaceSelectedText(HWND target_hwnd, DWORD target_pid, const std::wstring& transformed_text) {
  if (!target_hwnd) {
    return false;
  }

  // 1. Reactivate the target application and ensure it has focus
  if (!ReactivateTarget(target_hwnd)) {
    return false;
  }

  ::Sleep(50); // Synchronization pause

  // 2. Inject replacement text
  if (transformed_text.empty()) {
    // Delete selection by sending Backspace
    INPUT inputs[2] = {};
    inputs[0].type = INPUT_KEYBOARD;
    inputs[0].ki.wVk = VK_BACK;

    inputs[1].type = INPUT_KEYBOARD;
    inputs[1].ki.wVk = VK_BACK;
    inputs[1].ki.dwFlags = KEYEVENTF_KEYUP;

    ::SendInput(2, inputs, sizeof(INPUT));
    return true;
  }

  // If text is large (> 120 chars), use clipboard paste for performance and reliability
  if (transformed_text.length() > 120) {
    return PasteReplacement(transformed_text);
  }

  // Otherwise, type Unicode keystrokes directly (mirroring macOS CGEvent injection)
  return TypeReplacement(transformed_text);
}

bool WindowsTextReplacementService::ReactivateTarget(HWND target_hwnd, DWORD timeout_ms) {
  if (::GetForegroundWindow() == target_hwnd) {
    return true;
  }

  // Attach thread input if needed for reliable activation
  DWORD current_thread_id = ::GetCurrentThreadId();
  DWORD target_thread_id = ::GetWindowThreadProcessId(target_hwnd, nullptr);

  if (current_thread_id != target_thread_id) {
    ::AttachThreadInput(current_thread_id, target_thread_id, TRUE);
  }

  if (::IsIconic(target_hwnd)) {
    ::ShowWindow(target_hwnd, SW_RESTORE);
  }
  ::SetForegroundWindow(target_hwnd);
  ::BringWindowToTop(target_hwnd);
  ::SetFocus(target_hwnd);

  if (current_thread_id != target_thread_id) {
    ::AttachThreadInput(current_thread_id, target_thread_id, FALSE);
  }

  DWORD start_time = ::GetTickCount();
  while (::GetTickCount() - start_time < timeout_ms) {
    if (::GetForegroundWindow() == target_hwnd) {
      return true;
    }
    ::Sleep(15);
  }

  return ::GetForegroundWindow() == target_hwnd;
}

bool WindowsTextReplacementService::TypeReplacement(const std::wstring& text) {
  std::vector<INPUT> inputs;
  inputs.reserve(text.length() * 2);

  for (wchar_t ch : text) {
    INPUT down = {};
    down.type = INPUT_KEYBOARD;
    down.ki.wScan = ch;
    down.ki.dwFlags = KEYEVENTF_UNICODE;
    inputs.push_back(down);

    INPUT up = {};
    up.type = INPUT_KEYBOARD;
    up.ki.wScan = ch;
    up.ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
    inputs.push_back(up);
  }

  if (!inputs.empty()) {
    UINT sent = ::SendInput(static_cast<UINT>(inputs.size()), inputs.data(), sizeof(INPUT));
    return sent == inputs.size();
  }
  return true;
}

bool WindowsTextReplacementService::PasteReplacement(const std::wstring& text) {
  if (!::OpenClipboard(nullptr)) {
    return false;
  }

  ::EmptyClipboard();
  size_t bytes = (text.length() + 1) * sizeof(wchar_t);
  HGLOBAL h_mem = ::GlobalAlloc(GMEM_MOVEABLE, bytes);
  if (!h_mem) {
    ::CloseClipboard();
    return false;
  }

  wchar_t* p_mem = static_cast<wchar_t*>(::GlobalLock(h_mem));
  if (p_mem) {
    memcpy(p_mem, text.c_str(), bytes);
    ::GlobalUnlock(h_mem);
  }
  ::SetClipboardData(CF_UNICODETEXT, h_mem);
  ::CloseClipboard();

  // Send Ctrl + V
  INPUT inputs[4] = {};
  inputs[0].type = INPUT_KEYBOARD;
  inputs[0].ki.wVk = VK_CONTROL;

  inputs[1].type = INPUT_KEYBOARD;
  inputs[1].ki.wVk = 'V';

  inputs[2].type = INPUT_KEYBOARD;
  inputs[2].ki.wVk = 'V';
  inputs[2].ki.dwFlags = KEYEVENTF_KEYUP;

  inputs[3].type = INPUT_KEYBOARD;
  inputs[3].ki.wVk = VK_CONTROL;
  inputs[3].ki.dwFlags = KEYEVENTF_KEYUP;

  UINT sent = ::SendInput(4, inputs, sizeof(INPUT));
  return sent == 4;
}

