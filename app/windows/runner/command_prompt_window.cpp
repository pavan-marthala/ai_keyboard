#include "command_prompt_window.h"

#include <gdiplus.h>
#include <dwmapi.h>
#include <cmath>
#include <algorithm>

#pragma comment(lib, "gdiplus.lib")
#pragma comment(lib, "dwmapi.lib")

using namespace Gdiplus;

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

  // Built-in commands matching specifications
  chips_.clear();
  std::vector<std::wstring> cmd_names = {L"@fix", L"@rewrite", L"@pro", L"@casual", L"@short", L"@expand"};
  for (const auto& name : cmd_names) {
    CommandChip chip;
    chip.command = name;
    chips_.push_back(chip);
  }
  focused_chip_index_ = 0;
  chips_[0].is_focused = true;

  is_expanded_ = false;
  is_loading_ = false;
  is_error_ = false;
  status_text_.clear();

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

  // Windows 11 DWM rounded corners
  DWM_WINDOW_CORNER_PREFERENCE preference = DWMWCP_ROUND;
  ::DwmSetWindowAttribute(hwnd_, DWMWA_WINDOW_CORNER_PREFERENCE, &preference, sizeof(preference));

  RepositionNearCursor(panel_width_, panel_height_);

  ::ShowWindow(hwnd_, SW_SHOW);
  ::SetForegroundWindow(hwnd_);
  ::SetActiveWindow(hwnd_);
  ::SetFocus(hwnd_);
  ::InvalidateRect(hwnd_, nullptr, TRUE);
}

void CommandPromptWindow::Close() {
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
    ::InvalidateRect(hwnd_, nullptr, TRUE);
  }
}

void CommandPromptWindow::ShowError(const std::wstring& command, const std::wstring& message) {
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
    ::InvalidateRect(hwnd_, nullptr, TRUE);
  }
}

std::wstring CommandPromptWindow::ActionLabelForCommand(const std::wstring& command) {
  if (command == L"@fix") return L"Fixing grammar & spelling...";
  if (command == L"@rewrite") return L"Rewriting text...";
  if (command == L"@pro") return L"Making professional...";
  if (command == L"@casual") return L"Making casual...";
  if (command == L"@short") return L"Shortening text...";
  if (command == L"@expand") return L"Expanding text...";
  return L"Transforming with " + command + L"...";
}

void CommandPromptWindow::UpdateLayout() {
  panel_height_ = is_expanded_ ? expanded_panel_height_ : compact_panel_height_;

  // Compute chips layout
  int current_x = kHorizontalPadding;
  int chip_y = panel_height_ - kVerticalPadding - kChipHeight;

  // Approximate chip width based on command text length
  for (size_t i = 0; i < chips_.size(); ++i) {
    int text_width = static_cast<int>(chips_[i].command.length() * 9);
    int width = std::max(64, text_width + kChipHorizontalPadding * 2);

    chips_[i].rect.left = current_x;
    chips_[i].rect.top = chip_y;
    chips_[i].rect.right = current_x + width;
    chips_[i].rect.bottom = chip_y + kChipHeight;

    current_x += width + kChipSpacing;
  }

  int chips_row_width = current_x - kChipSpacing + kHorizontalPadding;
  panel_width_ = std::max(kMinPanelWidth, chips_row_width);

  // Close button top right
  close_button_rect_.right = panel_width_ - kHorizontalPadding + 6;
  close_button_rect_.left = close_button_rect_.right - kCloseButtonSize;
  close_button_rect_.top = kVerticalPadding - 4;
  close_button_rect_.bottom = close_button_rect_.top + kCloseButtonSize;
}

void CommandPromptWindow::RepositionNearCursor(int width, int height) {
  POINT pt;
  ::GetCursorPos(&pt);

  HMONITOR monitor = ::MonitorFromPoint(pt, MONITOR_DEFAULTTONEAREST);
  MONITORINFO mi = {sizeof(MONITORINFO)};
  ::GetMonitorInfo(monitor, &mi);

  int offset_x = 16;
  int offset_y = 16;
  int origin_x = pt.x + offset_x;
  int origin_y = pt.y + offset_y;

  if (origin_x + width > mi.rcWork.right) {
    origin_x = mi.rcWork.right - width - 8;
  }
  if (origin_x < mi.rcWork.left) {
    origin_x = mi.rcWork.left + 8;
  }

  if (origin_y + height > mi.rcWork.bottom) {
    origin_y = pt.y - height - offset_y;
  }
  if (origin_y < mi.rcWork.top) {
    origin_y = mi.rcWork.top + 8;
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

static GraphicsPath* CreateRoundRectPath(int x, int y, int width, int height, int radius) {
  GraphicsPath* path = new GraphicsPath();
  int d = radius * 2;
  path->AddArc(x, y, d, d, 180, 90);
  path->AddArc(x + width - d, y, d, d, 270, 90);
  path->AddArc(x + width - d, y + height - d, d, d, 0, 90);
  path->AddArc(x, y + height - d, d, d, 90, 90);
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

  // Double buffering with GDI+ Bitmap
  Bitmap buffer(w, h);
  Graphics g(&buffer);
  g.SetSmoothingMode(SmoothingModeAntiAlias);
  g.SetTextRenderingHint(TextRenderingHintClearTypeGridFit);

  // Background Surface Color (#131318)
  Color surface_color(255, 19, 19, 24);
  SolidBrush bg_brush(surface_color);
  g.Clear(Color(0, 0, 0, 0));

  // Rounded Card Background
  GraphicsPath* card_path = CreateRoundRectPath(0, 0, w - 1, h - 1, kCornerRadius);
  g.FillPath(&bg_brush, card_path);

  // Subtle Border (#FFFFFF1F)
  Pen border_pen(Color(31, 255, 255, 255), 1.0f);
  g.DrawPath(&border_pen, card_path);
  delete card_path;

  // Fonts
  FontFamily font_family(L"Segoe UI");
  Gdiplus::Font title_font(&font_family, 10.5f, FontStyleBold, UnitPoint);
  Gdiplus::Font preview_font(&font_family, 9.0f, FontStyleRegular, UnitPoint);
  Gdiplus::Font chip_font(&font_family, 9.5f, FontStyleBold, UnitPoint);
  Gdiplus::Font status_font(&font_family, 9.0f, FontStyleRegular, UnitPoint);
  Gdiplus::Font close_font(&font_family, 10.0f, FontStyleRegular, UnitPoint);

  // Colors
  SolidBrush text_primary_brush(Color(255, 245, 245, 247));
  SolidBrush text_secondary_brush(Color(255, 152, 152, 159));
  SolidBrush error_brush(Color(255, 240, 87, 107));
  Color primary_color(255, 139, 92, 246);       // #8B5CF6
  Color primary_hover_color(255, 124, 58, 237); // #7C3AED

  // 1. Title: "What do you want to do?"
  PointF title_pos(static_cast<REAL>(kHorizontalPadding), static_cast<REAL>(kVerticalPadding));
  g.DrawString(L"What do you want to do?", -1, &title_font, title_pos, &text_primary_brush);

  // 2. Close button: "×"
  if (is_close_hovered_) {
    SolidBrush close_bg_brush(Color(255, 36, 36, 45));
    g.FillEllipse(&close_bg_brush, close_button_rect_.left, close_button_rect_.top,
                  kCloseButtonSize, kCloseButtonSize);
  }
  StringFormat center_format;
  center_format.SetAlignment(StringAlignmentCenter);
  center_format.SetLineAlignment(StringAlignmentCenter);
  RectF close_rect_f(static_cast<REAL>(close_button_rect_.left),
                     static_cast<REAL>(close_button_rect_.top),
                     static_cast<REAL>(kCloseButtonSize),
                     static_cast<REAL>(kCloseButtonSize));
  g.DrawString(L"×", -1, &close_font, close_rect_f, &center_format, &text_secondary_brush);

  // 3. Selected Text Preview
  PointF preview_pos(static_cast<REAL>(kHorizontalPadding),
                     static_cast<REAL>(kVerticalPadding + kHeaderHeight + 2));
  g.DrawString(truncated_preview_.c_str(), -1, &preview_font, preview_pos, &text_secondary_brush);

  // 4. Status Row (Loading / Error)
  if (is_expanded_) {
    REAL status_y = static_cast<REAL>(kVerticalPadding + kHeaderHeight + kPreviewHeight + 6);

    if (is_loading_) {
      // Draw spinning indicator
      REAL cx = static_cast<REAL>(kHorizontalPadding + 7);
      REAL cy = status_y + 7;
      REAL radius = 6.0f;
      Pen spinner_pen(primary_color, 2.0f);
      g.DrawArc(&spinner_pen, cx - radius, cy - radius, radius * 2, radius * 2,
                static_cast<REAL>(spinner_angle_), 270.0f);

      PointF status_pos(static_cast<REAL>(kHorizontalPadding + 20), status_y);
      g.DrawString(status_text_.c_str(), -1, &status_font, status_pos, &text_primary_brush);
    } else if (is_error_) {
      PointF status_pos(static_cast<REAL>(kHorizontalPadding), status_y);
      g.DrawString(status_text_.c_str(), -1, &status_font, status_pos, &error_brush);
    }
  }

  // 5. Command Chips (Bottom row)
  for (size_t i = 0; i < chips_.size(); ++i) {
    const auto& chip = chips_[i];
    int chip_w = chip.rect.right - chip.rect.left;
    int chip_h = chip.rect.bottom - chip.rect.top;

    GraphicsPath* chip_path = CreateRoundRectPath(chip.rect.left, chip.rect.top,
                                                  chip_w, chip_h, chip_h / 2);

    Color bg = (chip.is_hovered || chip.is_focused) ? primary_hover_color : primary_color;
    SolidBrush chip_bg_brush(bg);
    g.FillPath(&chip_bg_brush, chip_path);

    // If focused by keyboard, draw highlight ring
    if (chip.is_focused) {
      Pen focus_pen(Color(255, 255, 255, 255), 1.5f);
      g.DrawPath(&focus_pen, chip_path);
    }

    RectF chip_rect_f(static_cast<REAL>(chip.rect.left),
                      static_cast<REAL>(chip.rect.top),
                      static_cast<REAL>(chip_w),
                      static_cast<REAL>(chip_h));
    g.DrawString(chip.command.c_str(), -1, &chip_font, chip_rect_f, &center_format, &text_primary_brush);

    delete chip_path;
  }

  // Blit buffer to screen
  Graphics screen(hdc);
  screen.DrawImage(&buffer, 0, 0);

  ::EndPaint(hwnd_, &ps);
}

