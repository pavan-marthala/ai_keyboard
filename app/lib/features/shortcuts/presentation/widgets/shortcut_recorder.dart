import 'package:atfix/core/theme/app_theme.dart';
import 'package:atfix/core/utils/check_platforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/desktop_shortcut.dart';

/// Interactive desktop keyboard shortcut recorder widget.
class ShortcutRecorder extends StatefulWidget {
  final DesktopShortcut currentShortcut;
  final ValueChanged<DesktopShortcut> onShortcutChanged;
  final String? errorMessage;
  final bool enabled;

  const ShortcutRecorder({
    super.key,
    required this.currentShortcut,
    required this.onShortcutChanged,
    this.errorMessage,
    this.enabled = true,
  });

  @override
  State<ShortcutRecorder> createState() => _ShortcutRecorderState();
}

class _ShortcutRecorderState extends State<ShortcutRecorder> {
  final FocusNode _focusNode = FocusNode();
  bool _isRecording = false;
  String _liveModifiers = '';

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _startRecording() {
    if (!widget.enabled) return;
    setState(() {
      _isRecording = true;
      _liveModifiers = '';
    });
    _focusNode.requestFocus();
  }

  void _cancelRecording() {
    setState(() {
      _isRecording = false;
      _liveModifiers = '';
    });
    _focusNode.unfocus();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!_isRecording) return KeyEventResult.ignored;

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.handled;
    }

    final logicalKey = event.logicalKey;

    // Escape cancels recording
    if (logicalKey == LogicalKeyboardKey.escape) {
      _cancelRecording();
      return KeyEventResult.handled;
    }

    final isMacOS = PlatformChecker.isMacOS();
    final hk = HardwareKeyboard.instance;

    // Collect currently pressed modifiers
    final modifiers = <String>[];
    if (hk.isControlPressed) modifiers.add('control');
    if (hk.isAltPressed) modifiers.add(isMacOS ? 'option' : 'alt');
    if (hk.isShiftPressed) modifiers.add('shift');
    if (hk.isMetaPressed) modifiers.add(isMacOS ? 'command' : 'windows');

    // Check if the pressed key itself is a modifier
    final isModifierKey = logicalKey == LogicalKeyboardKey.controlLeft ||
        logicalKey == LogicalKeyboardKey.controlRight ||
        logicalKey == LogicalKeyboardKey.altLeft ||
        logicalKey == LogicalKeyboardKey.altRight ||
        logicalKey == LogicalKeyboardKey.shiftLeft ||
        logicalKey == LogicalKeyboardKey.shiftRight ||
        logicalKey == LogicalKeyboardKey.metaLeft ||
        logicalKey == LogicalKeyboardKey.metaRight;

    if (isModifierKey) {
      // Just update live modifier indicator
      final temp = DesktopShortcut(key: '', modifiers: modifiers);
      setState(() {
        _liveModifiers = temp.displayString(isMacOS: isMacOS);
      });
      return KeyEventResult.handled;
    }

    // Resolve primary key name
    final keyName = _resolveKeyName(logicalKey);
    if (keyName.isEmpty) return KeyEventResult.handled;

    final candidate = DesktopShortcut(
      key: keyName,
      modifiers: modifiers,
    );

    if (candidate.isValid) {
      widget.onShortcutChanged(candidate);
      setState(() {
        _isRecording = false;
        _liveModifiers = '';
      });
      _focusNode.unfocus();
    }

    return KeyEventResult.handled;
  }

  String _resolveKeyName(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.space) return 'space';
    if (key == LogicalKeyboardKey.enter) return 'return';
    if (key == LogicalKeyboardKey.tab) return 'tab';
    if (key == LogicalKeyboardKey.backspace) return 'backspace';

    final label = key.keyLabel.trim().toLowerCase();
    if (label.isNotEmpty && RegExp(r'^[a-z0-9]$').hasMatch(label)) {
      return label;
    }

    // Function keys (F1 .. F12)
    final debugName = key.debugName?.toLowerCase() ?? '';
    if (RegExp(r'^f[1-9][0-2]?$').hasMatch(debugName)) {
      return debugName;
    }

    return label;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;
    final isMacOS = PlatformChecker.isMacOS();

    final displayShortcut = widget.currentShortcut.displayString(isMacOS: isMacOS);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isRecording
                    ? colors.primary
                    : widget.errorMessage != null
                        ? colors.error
                        : colors.border,
                width: _isRecording ? 2 : 1,
              ),
              boxShadow: _isRecording
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? colors.primary.withValues(alpha: 0.15)
                        : colors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isRecording
                        ? Icons.keyboard_rounded
                        : Icons.keyboard_command_key_rounded,
                    color: _isRecording ? colors.primary : colors.textPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isRecording
                            ? 'Listening for shortcut...'
                            : 'Global Shortcut',
                        style: typo.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_isRecording)
                        Text(
                          _liveModifiers.isNotEmpty
                              ? '$_liveModifiers + ...'
                              : 'Press any combination (e.g. ${isMacOS ? "Control + Shift + K" : "Ctrl + Shift + K"}) or Esc to cancel',
                          style: typo.bodySmall.copyWith(
                            color: colors.primary300,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        Text(
                          'Press this shortcut from any app after selecting text',
                          style: typo.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (_isRecording) ...[
                  OutlinedButton(
                    onPressed: _cancelRecording,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      side: BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.borderLight),
                    ),
                    child: Text(
                      displayShortcut,
                      style: typo.titleMedium.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Change Shortcut',
                    onPressed: widget.enabled ? _startRecording : null,
                    icon: Icon(
                      Icons.edit_rounded,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.errorMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: colors.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.errorMessage!,
                      style: typo.bodySmall.copyWith(
                        color: colors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
