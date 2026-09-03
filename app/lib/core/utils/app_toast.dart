import 'package:ai_keyboard/core/theme/app_colors.dart';
import 'package:ai_keyboard/core/theme/app_theme.dart';
import 'package:ai_keyboard/core/utils/sized_context.dart';
import 'package:ai_keyboard/main.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';

void showNotificationToast({
  required String message,
  dynamic Function()? onTap,
}) {
  _show(
    type: _ToastType.notification,
    message: message,
    onTap: onTap,
    duration: const Duration(seconds: 3),
  );
}

void showSuccessToast({required String message, dynamic Function()? onTap}) {
  _show(
    type: _ToastType.success,
    message: message,
    onTap: onTap,
    duration: const Duration(seconds: 3),
  );
}

void showErrorToast({required String message, dynamic Function()? onTap}) {
  _show(
    type: _ToastType.error,
    message: message,
    onTap: onTap,
    duration: const Duration(seconds: 5),
  );
}

void showWarningToast({required String message, dynamic Function()? onTap}) {
  _show(
    type: _ToastType.warning,
    message: message,
    onTap: onTap,
    duration: const Duration(seconds: 3),
  );
}

void showInfoToast({required String message, dynamic Function()? onTap}) {
  _show(
    type: _ToastType.info,
    message: message,
    onTap: onTap,
    duration: const Duration(seconds: 3),
  );
}

enum _ToastType { notification, success, error, warning, info }

void _show({
  required _ToastType type,
  required String message,
  dynamic Function()? onTap,
  required Duration duration,
}) {
  final context = rootNavigatorKey.currentContext;
  if (context == null) return;

  DelightToastBar(
    builder: (ctx) => _ToastPill(type: type, message: message, onTap: onTap),
    autoDismiss: true,
    position: DelightSnackbarPosition.top,
    snackbarDuration: duration,
  ).show(context);
}

class _ToastPill extends StatelessWidget {
  final _ToastType type;
  final String message;
  final dynamic Function()? onTap;

  const _ToastPill({required this.type, required this.message, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final width = context.widthPx;
    final style = _resolveStyle(type, colors);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width * 0.9),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
            decoration: BoxDecoration(
              color: style.accent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: style.accent.withValues(alpha: 0.30),
                width: 1,
              ),

              boxShadow: [
                BoxShadow(
                  color: style.accent.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: style.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillStyle {
  final Color accent;

  final Color textColor;

  const _PillStyle({required this.accent, required this.textColor});
}

_PillStyle _resolveStyle(_ToastType type, AppColors colors) {
  switch (type) {
    case _ToastType.success:
      return _PillStyle(accent: colors.success, textColor: colors.white);

    case _ToastType.error:
      return _PillStyle(accent: colors.error, textColor: colors.white);

    case _ToastType.warning:
      return _PillStyle(accent: Color(0xFFF59E0B), textColor: colors.white);

    case _ToastType.info:
    case _ToastType.notification:
      return _PillStyle(accent: colors.primary500, textColor: colors.white);
  }
}
