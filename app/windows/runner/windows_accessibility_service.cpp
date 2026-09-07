#include "windows_accessibility_service.h"

#include <uiautomation.h>
#include <psapi.h>
#include <iostream>

#pragma comment(lib, "uiautomationcore.lib")
#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "oleaut32.lib")

WindowsAccessibilityService& WindowsAccessibilityService::GetInstance() {
  static WindowsAccessibilityService instance;
  return instance;
}

WindowsAccessibilityService::WindowsAccessibilityService() {}

WindowsAccessibilityService::~WindowsAccessibilityService() {}

TargetWindowInfo WindowsAccessibilityService::GetForegroundTarget() {
  TargetWindowInfo info;
  info.hwnd = ::GetForegroundWindow();
  if (!info.hwnd) {
    return info;
  }

  ::GetWindowThreadProcessId(info.hwnd, &info.pid);

  // Window title
  int title_len = ::GetWindowTextLengthW(info.hwnd);
  if (title_len > 0) {
    std::wstring title(title_len + 1, L'\0');
    ::GetWindowTextW(info.hwnd, &title[0], title_len + 1);
    title.resize(title_len);
    info.window_title = title;
  }

  // Process name
  HANDLE process_handle = ::OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, info.pid);
  if (process_handle) {
    wchar_t process_path[MAX_PATH];
    DWORD path_len = MAX_PATH;
    if (::QueryFullProcessImageNameW(process_handle, 0, process_path, &path_len)) {
      std::wstring full_path(process_path, path_len);
      size_t last_slash = full_path.find_last_of(L"\\/");
      if (last_slash != std::wstring::npos) {
        info.process_name = full_path.substr(last_slash + 1);
      } else {
        info.process_name = full_path;
      }
    }
    ::CloseHandle(process_handle);
  }

  return info;
}

std::wstring WindowsAccessibilityService::GetSelectedText(HWND target_hwnd) {
  if (!target_hwnd) return L"";

  // 1. Try UI Automation
  std::wstring selected = GetSelectedTextViaUia(target_hwnd);
  if (!selected.empty()) {
    return selected;
  }

  // 2. Fallback to synthetic clipboard copy
  return GetSelectedTextViaClipboard(target_hwnd);
}

std::wstring WindowsAccessibilityService::GetSelectedTextViaUia(HWND target_hwnd) {
  IUIAutomation* automation = nullptr;
  HRESULT hr = ::CoCreateInstance(
      CLSID_CUIAutomation, nullptr, CLSCTX_INPROC_SERVER,
      IID_IUIAutomation, reinterpret_cast<void**>(&automation));

  if (FAILED(hr) || !automation) {
    return L"";
  }

  std::wstring result;
  IUIAutomationElement* focused_element = nullptr;
  hr = automation->GetFocusedElement(&focused_element);

  if (SUCCEEDED(hr) && focused_element) {
    IUIAutomationTextPattern* text_pattern = nullptr;
    hr = focused_element->GetCurrentPatternAs(
        UIA_TextPatternId, IID_IUIAutomationTextPattern,
        reinterpret_cast<void**>(&text_pattern));

    if (SUCCEEDED(hr) && text_pattern) {
      IUIAutomationTextRangeArray* selection_ranges = nullptr;
      hr = text_pattern->GetSelection(&selection_ranges);

      if (SUCCEEDED(hr) && selection_ranges) {
        int length = 0;
        selection_ranges->get_Length(&length);
        if (length > 0) {
          IUIAutomationTextRange* range = nullptr;
          hr = selection_ranges->GetElement(0, &range);
          if (SUCCEEDED(hr) && range) {
            BSTR bstr_text = nullptr;
            hr = range->GetText(-1, &bstr_text);
            if (SUCCEEDED(hr) && bstr_text) {
              result = bstr_text;
              ::SysFreeString(bstr_text);
            }
            range->Release();
          }
        }
        selection_ranges->Release();
      }
      text_pattern->Release();
    }
    focused_element->Release();
  }

  automation->Release();
  return result;
}

std::wstring WindowsAccessibilityService::GetSelectedTextViaClipboard(HWND target_hwnd) {
  // Backup existing clipboard text
  std::wstring old_clipboard_text;
  if (::OpenClipboard(nullptr)) {
    HANDLE h_data = ::GetClipboardData(CF_UNICODETEXT);
    if (h_data) {
      wchar_t* p_text = static_cast<wchar_t*>(::GlobalLock(h_data));
      if (p_text) {
        old_clipboard_text = p_text;
        ::GlobalUnlock(h_data);
      }
    }
    ::CloseClipboard();
  }

  DWORD initial_seq = ::GetClipboardSequenceNumber();

  // Send Ctrl + C
  INPUT inputs[4] = {};
  inputs[0].type = INPUT_KEYBOARD;
  inputs[0].ki.wVk = VK_CONTROL;

  inputs[1].type = INPUT_KEYBOARD;
  inputs[1].ki.wVk = 'C';

  inputs[2].type = INPUT_KEYBOARD;
  inputs[2].ki.wVk = 'C';
  inputs[2].ki.dwFlags = KEYEVENTF_KEYUP;

  inputs[3].type = INPUT_KEYBOARD;
  inputs[3].ki.wVk = VK_CONTROL;
  inputs[3].ki.dwFlags = KEYEVENTF_KEYUP;

  ::SendInput(4, inputs, sizeof(INPUT));

  // Wait for clipboard update up to 100ms
  std::wstring new_text;
  for (int i = 0; i < 10; ++i) {
    ::Sleep(10);
    if (::GetClipboardSequenceNumber() != initial_seq) {
      break;
    }
  }

  if (::OpenClipboard(nullptr)) {
    HANDLE h_data = ::GetClipboardData(CF_UNICODETEXT);
    if (h_data) {
      wchar_t* p_text = static_cast<wchar_t*>(::GlobalLock(h_data));
      if (p_text) {
        new_text = p_text;
        ::GlobalUnlock(h_data);
      }
    }
    ::CloseClipboard();
  }

  return new_text;
}

