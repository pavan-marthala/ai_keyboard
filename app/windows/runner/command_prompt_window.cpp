#include "command_prompt_window.h"

#include <gdiplus.h>
#include <dwmapi.h>
#include <cmath>
#include <algorithm>
#include <memory>
#include "prompt_repository.h"
#include "utils.h"

#pragma comment(lib, "gdiplus.lib")
#pragma comment(lib, "dwmapi.lib")

using namespace Gdiplus;
using atfix::PromptRepository;
using atfix::CommandDefinition;

namespace {

UINT GetWindowDpi(HWND hwnd) {
  if (hwnd) {
    typedef UINT(WINAPI * GetDpiForWindowFn)(HWND);
    static GetDpiForWindowFn get_dpi_for_window = []() {
      HMODULE user32 = ::GetModuleHandleW(L"user32.dll");
      return user32 ? reinterpret_cast<GetDpiForWindowFn>(
                          ::GetProcAddress(user32, "GetDpiForWindow"))
                    : nullptr;
    }();
    if (get_dpi_for_window) {
      UINT dpi = get_dpi_for_window(hwnd);
      if (dpi > 0) return dpi;
    }
  }
  return 0;
}

UINT GetMonitorDpi(HMONITOR monitor) {
  if (monitor) {
    typedef HRESULT(WINAPI * GetDpiForMonitorFn)(HMONITOR, int, UINT*, UINT*);
    static GetDpiForMonitorFn get_dpi_for_monitor = []() {
      HMODULE shcore = ::LoadLibraryW(L"shcore.dll");
      return shcore ? reinterpret_cast<GetDpiForMonitorFn>(
                          ::GetProcAddress(shcore, "GetDpiForMonitor"))
                    : nullptr;
    }();
    if (get_dpi_for_monitor) {
      UINT dpi_x = 0, dpi_y = 0;
      if (SUCCEEDED(get_dpi_for_monitor(monitor, 0 /* MDT_EFFECTIVE_DPI */,
                                        &dpi_x, &dpi_y)) &&
          dpi_x > 0) {
        return dpi_x;
      }
    }
  }
  return 0;
}

UINT GetSystemDpi(HWND hwnd) {
  HDC hdc = ::GetDC(hwnd);
  if (hdc) {
    int dpi = ::GetDeviceCaps(hdc, LOGPIXELSX);
    ::ReleaseDC(hwnd, hdc);
    if (dpi > 0) return static_cast<UINT>(dpi);
  }
  return 96;
}

}  // namespace

bool CommandPromptWindow::gdiplus_initialized_ = false;
ULONG_PTR CommandPromptWindow::gdiplus_token_ = 0;

void CommandPromptWindow::EnsureGdiplus() {
  if (!gdiplus_initialized_) {
    GdiplusStartupInput gdiplus_startup_input;
    GdiplusStartup(&gdiplus_token_, &gdiplus_startup_input, nullptr);
    gdiplus_initialized_ = true;
  }
}

CommandPromptWindow::CommandPromptWindow() {
  EnsureGdiplus();
  RegisterWindowClass();
}

CommandPromptWindow::~CommandPromptWindow() {
  Close();
  if (hwnd_) {
    ::DestroyWindow(hwnd_);
    hwnd_ = nullptr;
  }
}

void CommandPromptWindow::RegisterWindowClass() {
  WNDCLASSEXW wc = {sizeof(WNDCLASSEXW)};
  wc.style = CS_HREDRAW | CS_VREDRAW | CS_DROPSHADOW;
  wc.lpfnWndProc = CommandPromptWindow::WndProc;
  wc.hInstance = ::GetModuleHandle(nullptr);
  wc.hCursor = ::LoadCursor(nullptr, IDC_ARROW);
  wc.hbrBackground = nullptr;
  wc.lpszClassName = L"AtFixCommandPromptWindow";

  ::RegisterClassExW(&wc);
}

void CommandPromptWindow::UpdateDpi(UINT dpi) {
  if (dpi == 0) dpi = 96;
  if (dpi_ != dpi) {
    dpi_ = dpi;
    scale_ = static_cast<float>(dpi_) / 96.0f;
  }
}

void CommandPromptWindow::UpdateDpiFromMonitorOrWindow(HMONITOR monitor) {
  // 1. Primary: GetDpiForWindow if window already exists
  if (hwnd_) {
    UINT dpi = GetWindowDpi(hwnd_);
    if (dpi > 0) {
      UpdateDpi(dpi);
      return;
    }
  }
  // 2. Monitor fallback
  if (monitor) {
    UINT dpi = GetMonitorDpi(monitor);
    if (dpi > 0) {
      UpdateDpi(dpi);
      return;
    }
  }
  // 3. DC / System fallback
  UpdateDpi(GetSystemDpi(hwnd_));
}

void CommandPromptWindow::Show(const std::wstring& selected_text, HWND target_hwnd, DWORD target_pid) {
  target_hwnd_ = target_hwnd;
  target_pid_ = target_pid;
  selected_text_ = selected_text;

  // Clean newlines for preview
  std::wstring preview = selected_text;
  std::replace(preview.begin(), preview.end(), L'\n', L' ');
  std::replace(preview.begin(), preview.end(), L'\r', L' ');
  if (preview.length() > 44) {
    truncated_preview_ = L"\"" + preview.substr(0, 41) + L"...\"";
  } else {
    truncated_preview_ = L"\"" + preview + L"\"";
  }

  // Dynamically load non-input commands from PromptRepository
  chips_.clear();
  const auto& commands = atfix::PromptRepository::GetInstance().GetCommands();
  for (const auto& def : commands) {
    if (def.requires_input) continue;
    CommandChip chip;
    chip.command = Utf16FromUtf8(def.command);
    chips_.push_back(chip);
  }
  focused_chip_index_ = 0;
  if (!chips_.empty()) {
    chips_[0].is_focused = true;
  }

  is_expanded_ = false;
  is_loading_ = false;
  is_error_ = false;
  status_text_.clear();

  POINT pt;
  ::GetCursorPos(&pt);
  HMONITOR monitor = ::MonitorFromPoint(pt, MONITOR_DEFAULTTONEAREST);
  UpdateDpiFromMonitorOrWindow(monitor);

  UpdateLayout();

  if (!hwnd_) {
    hwnd_ = ::CreateWindowExW(
        WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE,
        L"AtFixCommandPromptWindow",
        L"AtFix Command Prompt",
        WS_POPUP,
        0, 0, panel_width_, panel_height_,
        nullptr, nullptr, ::GetModuleHandle(nullptr), this);
  }

  // Authoritatively update with primary window DPI if available
  UINT window_dpi = GetWindowDpi(hwnd_);
  if (window_dpi > 0 && window_dpi != dpi_) {
    UpdateDpi(window_dpi);
    UpdateLayout();
  }

  // Windows 11 DWM rounded corners
  DWM_WINDOW_CORNER_PREFERENCE preference = DWMWCP_ROUND;
  ::DwmSetWindowAttribute(hwnd_, DWMWA_WINDOW_CORNER_PREFERENCE, &preference, sizeof(preference));

  RepositionNearCursor(panel_width_, panel_height_);
  UpdateWindowRegion();

  ::ShowWindow(hwnd_, SW_SHOW);
  ::SetForegroundWindow(hwnd_);
  ::SetActiveWindow(hwnd_);
  ::SetFocus(hwnd_);
  ::InvalidateRect(hwnd_, nullptr, TRUE);
}

void CommandPromptWindow::Close() {
  // Ensure we are executing on the window's owning thread
  if (hwnd_ && ::GetCurrentThreadId() != ::GetWindowThreadProcessId(hwnd_, nullptr)) {
    PostClose();
    return;
  }

  if (spinner_timer_id_ && hwnd_) {
    ::KillTimer(hwnd_, spinner_timer_id_);
    spinner_timer_id_ = 0;
  }
  if (hwnd_ && ::IsWindowVisible(hwnd_)) {
    ::ShowWindow(hwnd_, SW_HIDE);
  }
  if (delegate_) {
    delegate_->OnPromptClosed();
  }
}

void CommandPromptWindow::PostClose() {
  if (hwnd_) {
    ::PostMessageW(hwnd_, atfix::WM_ATFIX_PROMPT_CLOSE, 0, 0);
  }
}

bool CommandPromptWindow::IsVisible() const {
  return hwnd_ != nullptr && ::IsWindowVisible(hwnd_);
}

void CommandPromptWindow::UpdateLoadingState(const std::vector<std::wstring>& running_commands) {
  if (!running_commands.empty()) {
    is_loading_ = true;
    is_error_ = false;
    is_expanded_ = true;
    if (running_commands.size() == 1) {
      status_text_ = L"Processing: " + ActionLabelForCommand(running_commands[0]);
    } else {
      std::wstring combined;
      for (size_t i = 0; i < running_commands.size(); ++i) {
        if (i > 0) combined += L", ";
        combined += running_commands[i];
      }
      status_text_ = L"Processing: " + combined;
    }
    if (!spinner_timer_id_ && hwnd_) {
      spinner_timer_id_ = ::SetTimer(hwnd_, 1001, 50, nullptr);
    }
  } else {
    is_loading_ = false;
    is_expanded_ = false;
    status_text_.clear();
    if (spinner_timer_id_ && hwnd_) {
      ::KillTimer(hwnd_, spinner_timer_id_);
      spinner_timer_id_ = 0;
    }
  }

  UpdateLayout();
  if (hwnd_) {
    ::SetWindowPos(hwnd_, nullptr, 0, 0, panel_width_, panel_height_,
                   SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
    UpdateWindowRegion();
    ::InvalidateRect(hwnd_, nullptr, TRUE);
  }
}

void CommandPromptWindow::ShowError(const std::wstring& command, const std::wstring& message) {
  // Ensure we are executing on the window's owning thread
  if (hwnd_ && ::GetCurrentThreadId() != ::GetWindowThreadProcessId(hwnd_, nullptr)) {
    PostError(command, message);
    return;
  }

  is_loading_ = false;
  is_error_ = true;
  is_expanded_ = true;
  status_text_ = L"Failed: " + command + L" - " + message;
  if (spinner_timer_id_ && hwnd_) {
    ::KillTimer(hwnd_, spinner_timer_id_);
    spinner_timer_id_ = 0;
  }

  UpdateLayout();
  if (hwnd_) {
    ::SetWindowPos(hwnd_, nullptr, 0, 0, panel_width_, panel_height_,
                   SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
    UpdateWindowRegion();
    ::InvalidateRect(hwnd_, nullptr, TRUE);
  }
}

void CommandPromptWindow::PostError(const std::wstring& command, const std::wstring& message) {
  if (hwnd_) {
    auto* payload = new atfix::PromptErrorPayload{command, message};
    if (!::PostMessageW(hwnd_, atfix::WM_ATFIX_PROMPT_ERROR, 0, reinterpret_cast<LPARAM>(payload))) {
      delete payload;
    }
  }
}

std::wstring CommandPromptWindow::ActionLabelForCommand(const std::wstring& command) {
  std::string cmd_utf8 = Utf8FromUtf16(command);
  std::string label = atfix::PromptRepository::GetInstance().GetActionLabel(cmd_utf8);
  return Utf16FromUtf8(label);
}


void CommandPromptWindow::UpdateLayout() {
  title_y_ = Scale(kVerticalPadding);
  preview_y_ = title_y_ + Scale(kHeaderHeight) + Scale(kGapAfterHeader);

  if (is_expanded_) {
    status_y_ = preview_y_ + Scale(kPreviewHeight) + Scale(kGapAfterPreviewExpanded);
    chip_y_ = status_y_ + Scale(kStatusAreaHeight) + Scale(kGapAfterStatusExpanded);
  } else {
    status_y_ = 0;
    chip_y_ = preview_y_ + Scale(kPreviewHeight) + Scale(kGapPreviewToChipsCompact);
  }

  panel_height_ = chip_y_ + Scale(kChipHeight) + Scale(kVerticalPadding);

  // Compute chips layout with scaled metrics
  int current_x = Scale(kHorizontalPadding);
  int chip_h = Scale(kChipHeight);
  int chip_spacing = Scale(kChipSpacing);
  int chip_h_padding = Scale(kChipHorizontalPadding);
  int min_chip_w = Scale(64);

  for (size_t i = 0; i < chips_.size(); ++i) {
    int text_width = static_cast<int>(chips_[i].command.length() * Scale(9));
    int width = std::max(min_chip_w, text_width + chip_h_padding * 2);

    chips_[i].rect.left = current_x;
    chips_[i].rect.top = chip_y_;
    chips_[i].rect.right = current_x + width;
    chips_[i].rect.bottom = chip_y_ + chip_h;

    current_x += width + chip_spacing;
  }

  int chips_row_width = current_x - chip_spacing + Scale(kHorizontalPadding);
  panel_width_ = std::max(Scale(kMinPanelWidth), chips_row_width);

  // Close button top right
  int close_size = Scale(kCloseButtonSize);
  close_button_rect_.right = panel_width_ - Scale(kHorizontalPadding) + Scale(6);
  close_button_rect_.left = close_button_rect_.right - close_size;
  close_button_rect_.top = Scale(kVerticalPadding) - Scale(4);
  close_button_rect_.bottom = close_button_rect_.top + close_size;
}

void CommandPromptWindow::RepositionNearCursor(int width, int height) {
  POINT pt;
  ::GetCursorPos(&pt);

  HMONITOR monitor = ::MonitorFromPoint(pt, MONITOR_DEFAULTTONEAREST);
  MONITORINFO mi = {sizeof(MONITORINFO)};
  ::GetMonitorInfo(monitor, &mi);

  int offset_x = Scale(16);
  int offset_y = Scale(16);
  int margin = Scale(8);
  int origin_x = pt.x + offset_x;
  int origin_y = pt.y + offset_y;

  if (origin_x + width > mi.rcWork.right) {
    origin_x = mi.rcWork.right - width - margin;
  }
  if (origin_x < mi.rcWork.left) {
    origin_x = mi.rcWork.left + margin;
  }

  if (origin_y + height > mi.rcWork.bottom) {
    origin_y = pt.y - height - offset_y;
  }
  if (origin_y < mi.rcWork.top) {
    origin_y = mi.rcWork.top + margin;
  }

  if (hwnd_) {
    ::SetWindowPos(hwnd_, HWND_TOPMOST, origin_x, origin_y, width, height,
                   SWP_SHOWWINDOW | SWP_NOACTIVATE);
  }
}

LRESULT CALLBACK CommandPromptWindow::WndProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) {
  CommandPromptWindow* self = nullptr;
  if (msg == WM_NCCREATE) {
    CREATESTRUCT* cs = reinterpret_cast<CREATESTRUCT*>(lparam);
    self = reinterpret_cast<CommandPromptWindow*>(cs->lpCreateParams);
    ::SetWindowLongPtr(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(self));
    self->hwnd_ = hwnd;
  } else {
    self = reinterpret_cast<CommandPromptWindow*>(::GetWindowLongPtr(hwnd, GWLP_USERDATA));
  }

  if (self) {
    return self->HandleMessage(msg, wparam, lparam);
  }
  return ::DefWindowProcW(hwnd, msg, wparam, lparam);
}

LRESULT CommandPromptWindow::HandleMessage(UINT msg, WPARAM wparam, LPARAM lparam) {
  switch (msg) {
    case atfix::WM_ATFIX_PROMPT_CLOSE:
      Close();
      return 0;

    case atfix::WM_ATFIX_PROMPT_ERROR: {
      std::unique_ptr<atfix::PromptErrorPayload> payload(
          reinterpret_cast<atfix::PromptErrorPayload*>(lparam));
      if (payload) {
        ShowError(payload->command, payload->message);
      }
      return 0;
    }

    case WM_DPICHANGED: {
      UINT new_dpi = LOWORD(wparam);
      UpdateDpi(new_dpi);
      UpdateLayout();

      RECT* prcNewWindow = reinterpret_cast<RECT*>(lparam);
      if (prcNewWindow && hwnd_) {
        ::SetWindowPos(hwnd_, nullptr,
                       prcNewWindow->left, prcNewWindow->top,
                       panel_width_, panel_height_,
                       SWP_NOZORDER | SWP_NOACTIVATE);
      }
      UpdateWindowRegion();
      ::InvalidateRect(hwnd_, nullptr, TRUE);
      return 0;
    }

    case WM_PAINT:
      OnPaint();
      return 0;

    case WM_ERASEBKGND:
      return 1; // Prevent flicker

    case WM_MOUSEMOVE:
      OnMouseMove(LOWORD(lparam), HIWORD(lparam));
      return 0;

    case WM_LBUTTONDOWN:
      OnLButtonDown(LOWORD(lparam), HIWORD(lparam));
      return 0;

    case WM_KEYDOWN:
      OnKeyDown(wparam);
      return 0;

    case WM_ACTIVATE:
      if (LOWORD(wparam) == WA_INACTIVE) {
        // Dismiss if user clicks away
        Close();
      }
      return 0;

    case WM_TIMER:
      if (wparam == 1001) {
        AnimateSpinner();
      }
      return 0;

    case WM_DESTROY:
      if (spinner_timer_id_) {
        ::KillTimer(hwnd_, spinner_timer_id_);
        spinner_timer_id_ = 0;
      }
      return 0;
  }
  return ::DefWindowProcW(hwnd_, msg, wparam, lparam);
}

void CommandPromptWindow::AnimateSpinner() {
  spinner_angle_ = (spinner_angle_ + 30) % 360;
  ::InvalidateRect(hwnd_, nullptr, FALSE);
}

void CommandPromptWindow::OnMouseMove(int x, int y) {
  bool needs_repaint = false;
  POINT pt = {x, y};

  bool close_hover = ::PtInRect(&close_button_rect_, pt) != 0;
  if (close_hover != is_close_hovered_) {
    is_close_hovered_ = close_hover;
    needs_repaint = true;
  }

  for (size_t i = 0; i < chips_.size(); ++i) {
    bool hover = ::PtInRect(&chips_[i].rect, pt) != 0;
    if (hover != chips_[i].is_hovered) {
      chips_[i].is_hovered = hover;
      needs_repaint = true;
    }
  }

  if (needs_repaint) {
    ::InvalidateRect(hwnd_, nullptr, FALSE);
  }
}

void CommandPromptWindow::OnLButtonDown(int x, int y) {
  POINT pt = {x, y};

  if (::PtInRect(&close_button_rect_, pt)) {
    if (delegate_) delegate_->OnPromptCancelled();
    Close();
    return;
  }

  for (size_t i = 0; i < chips_.size(); ++i) {
    if (::PtInRect(&chips_[i].rect, pt)) {
      focused_chip_index_ = static_cast<int>(i);
      TriggerSelectedCommand();
      return;
    }
  }
}

void CommandPromptWindow::OnKeyDown(WPARAM key) {
  switch (key) {
    case VK_ESCAPE:
      if (delegate_) delegate_->OnPromptCancelled();
      Close();
      break;

    case VK_LEFT:
      if (!chips_.empty()) {
        chips_[focused_chip_index_].is_focused = false;
        focused_chip_index_ = (focused_chip_index_ - 1 + static_cast<int>(chips_.size())) % static_cast<int>(chips_.size());
        chips_[focused_chip_index_].is_focused = true;
        ::InvalidateRect(hwnd_, nullptr, FALSE);
      }
      break;

    case VK_RIGHT:
    case VK_TAB:
      if (!chips_.empty()) {
        chips_[focused_chip_index_].is_focused = false;
        focused_chip_index_ = (focused_chip_index_ + 1) % static_cast<int>(chips_.size());
        chips_[focused_chip_index_].is_focused = true;
        ::InvalidateRect(hwnd_, nullptr, FALSE);
      }
      break;

    case VK_RETURN:
      TriggerSelectedCommand();
      break;
  }
}

void CommandPromptWindow::TriggerSelectedCommand() {
  if (focused_chip_index_ >= 0 && focused_chip_index_ < static_cast<int>(chips_.size())) {
    std::wstring cmd = chips_[focused_chip_index_].command;
    if (delegate_) {
      delegate_->OnCommandSelected(cmd);
    }
  }
}

void CommandPromptWindow::UpdateWindowRegion() {
  if (hwnd_) {
    int radius = Scale(kCornerRadius);
    HRGN rgn = ::CreateRoundRectRgn(0, 0, panel_width_ + 1, panel_height_ + 1, radius * 2, radius * 2);
    ::SetWindowRgn(hwnd_, rgn, TRUE);
  }
}

static GraphicsPath* CreateRoundRectPath(REAL x, REAL y, REAL width, REAL height, REAL radius) {
  GraphicsPath* path = new GraphicsPath();
  REAL d = radius * 2.0f;
  path->AddArc(x, y, d, d, 180.0f, 90.0f);
  path->AddArc(x + width - d, y, d, d, 270.0f, 90.0f);
  path->AddArc(x + width - d, y + height - d, d, d, 0.0f, 90.0f);
  path->AddArc(x, y + height - d, d, d, 90.0f, 90.0f);
  path->CloseFigure();
  return path;
}

void CommandPromptWindow::OnPaint() {
  PAINTSTRUCT ps;
  HDC hdc = ::BeginPaint(hwnd_, &ps);

  RECT client_rect;
  ::GetClientRect(hwnd_, &client_rect);
  int w = client_rect.right - client_rect.left;
  int h = client_rect.bottom - client_rect.top;
  if (w <= 0 || h <= 0) {
    ::EndPaint(hwnd_, &ps);
    return;
  }

  // Double buffering with GDI+ Bitmap at physical client dimensions
  Bitmap buffer(w, h);
  Graphics g(&buffer);
  g.SetSmoothingMode(SmoothingModeAntiAlias);
  g.SetTextRenderingHint(TextRenderingHintClearTypeGridFit);

  // Background Surface Color (#131318)
  Color surface_color(255, 19, 19, 24);
  g.Clear(surface_color);

  // Crisp, defined border (#55556A)
  // Inset by 0.5f so 1.0f pen stroke sits exactly on pixel coordinates [0, 1] without clipping
  float border_radius = static_cast<float>(Scale(kCornerRadius));
  GraphicsPath* border_path = CreateRoundRectPath(
      0.5f, 0.5f,
      static_cast<REAL>(w - 1), static_cast<REAL>(h - 1),
      border_radius - 0.5f);
  Pen border_pen(Color(255, 85, 85, 106), 1.0f);
  g.DrawPath(&border_pen, border_path);
  delete border_path;

  // Scaled Fonts
  FontFamily font_family(L"Segoe UI");
  Gdiplus::Font title_font(&font_family, ScaleFont(kTitleFontSize), FontStyleBold, UnitPoint);
  Gdiplus::Font preview_font(&font_family, ScaleFont(kPreviewFontSize), FontStyleRegular, UnitPoint);
  Gdiplus::Font chip_font(&font_family, ScaleFont(kChipFontSize), FontStyleBold, UnitPoint);
  Gdiplus::Font status_font(&font_family, ScaleFont(kStatusFontSize), FontStyleRegular, UnitPoint);

  // Colors
  SolidBrush text_primary_brush(Color(255, 245, 245, 247));
  SolidBrush text_secondary_brush(Color(255, 152, 152, 159));
  SolidBrush error_brush(Color(255, 240, 87, 107));
  Color primary_color(255, 139, 92, 246);       // #8B5CF6
  Color primary_hover_color(255, 124, 58, 237); // #7C3AED

  // 1. Title: "What do you want to do?"
  PointF title_pos(static_cast<REAL>(Scale(kHorizontalPadding)), static_cast<REAL>(title_y_));
  g.DrawString(L"What do you want to do?", -1, &title_font, title_pos, &text_primary_brush);

  // 2. Close button
  int close_size = Scale(kCloseButtonSize);
  if (is_close_hovered_) {
    SolidBrush close_bg_brush(Color(255, 36, 36, 45));
    g.FillEllipse(&close_bg_brush, close_button_rect_.left, close_button_rect_.top,
                  close_size, close_size);
  }
  // Draw crisp vector '×' close icon (geometry scaled proportionally)
  float cx = static_cast<float>(close_button_rect_.left) + static_cast<float>(close_size) / 2.0f;
  float cy = static_cast<float>(close_button_rect_.top) + static_cast<float>(close_size) / 2.0f;
  float arm = Scale(3.5f);

  Color cross_color = is_close_hovered_ ? Color(255, 245, 245, 247) : Color(255, 152, 152, 159);
  Pen cross_pen(cross_color, Scale(1.5f));
  cross_pen.SetStartCap(LineCapRound);
  cross_pen.SetEndCap(LineCapRound);
  g.DrawLine(&cross_pen, cx - arm, cy - arm, cx + arm, cy + arm);
  g.DrawLine(&cross_pen, cx + arm, cy - arm, cx - arm, cy + arm);

  // 3. Selected Text Preview
  PointF preview_pos(static_cast<REAL>(Scale(kHorizontalPadding)), static_cast<REAL>(preview_y_));
  g.DrawString(truncated_preview_.c_str(), -1, &preview_font, preview_pos, &text_secondary_brush);

  // 4. Status Row (Loading / Error)
  if (is_expanded_) {
    REAL status_y = static_cast<REAL>(status_y_);

    if (is_loading_) {
      // Draw spinning indicator
      REAL cx_spin = static_cast<REAL>(Scale(kHorizontalPadding) + Scale(7));
      REAL cy_spin = status_y + Scale(8);
      REAL radius = Scale(6.0f);
      Pen spinner_pen(primary_color, Scale(2.0f));
      g.DrawArc(&spinner_pen, cx_spin - radius, cy_spin - radius, radius * 2, radius * 2,
                static_cast<REAL>(spinner_angle_), 270.0f);

      PointF status_pos(static_cast<REAL>(Scale(kHorizontalPadding) + Scale(20)), status_y);
      g.DrawString(status_text_.c_str(), -1, &status_font, status_pos, &text_primary_brush);
    } else if (is_error_) {
      PointF status_pos(static_cast<REAL>(Scale(kHorizontalPadding)), status_y);
      g.DrawString(status_text_.c_str(), -1, &status_font, status_pos, &error_brush);
    }
  }

  // 5. Command Chips (Bottom row)
  StringFormat center_format;
  center_format.SetAlignment(StringAlignmentCenter);
  center_format.SetLineAlignment(StringAlignmentCenter);

  for (size_t i = 0; i < chips_.size(); ++i) {
    const auto& chip = chips_[i];
    int chip_w = chip.rect.right - chip.rect.left;
    int chip_h = chip.rect.bottom - chip.rect.top;

    GraphicsPath* chip_path = CreateRoundRectPath(
        static_cast<REAL>(chip.rect.left),
        static_cast<REAL>(chip.rect.top),
        static_cast<REAL>(chip_w),
        static_cast<REAL>(chip_h),
        static_cast<REAL>(chip_h) / 2.0f);

    Color bg = (chip.is_hovered || chip.is_focused) ? primary_hover_color : primary_color;
    SolidBrush chip_bg_brush(bg);
    g.FillPath(&chip_bg_brush, chip_path);

    // If focused by keyboard, draw highlight ring
    if (chip.is_focused) {
      Pen focus_pen(Color(255, 255, 255, 255), Scale(1.5f));
      g.DrawPath(&focus_pen, chip_path);
    }

    RectF chip_rect_f(static_cast<REAL>(chip.rect.left),
                      static_cast<REAL>(chip.rect.top),
                      static_cast<REAL>(chip_w),
                      static_cast<REAL>(chip_h));
    g.DrawString(chip.command.c_str(), -1, &chip_font, chip_rect_f, &center_format, &text_primary_brush);

    delete chip_path;
  }

  // Blit buffer to screen 1:1
  Graphics screen(hdc);
  screen.DrawImage(&buffer, 0, 0, w, h);

  ::EndPaint(hwnd_, &ps);
}

