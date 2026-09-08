import 'package:atfix/core/utils/check_platforms.dart';

/// Platform-neutral representation of a global keyboard shortcut.
class DesktopShortcut {
  final String key;
  final List<String> modifiers;

  const DesktopShortcut({
    required this.key,
    required this.modifiers,
  });

  /// Default shortcut on macOS: Control + Option + Space.
  static const DesktopShortcut macOsDefault = DesktopShortcut(
    key: 'space',
    modifiers: ['control', 'option'],
  );

  /// Default shortcut on Windows: Control + Alt + Space.
  static const DesktopShortcut windowsDefault = DesktopShortcut(
    key: 'space',
    modifiers: ['control', 'alt'],
  );

  /// Default shortcut for the current running platform.
  factory DesktopShortcut.defaultForPlatform({bool? isMacOS}) {
    if (isMacOS ?? (PlatformChecker.isMacOS() || !PlatformChecker.isWindows())) {
      return macOsDefault;
    }
    return windowsDefault;
  }

  factory DesktopShortcut.fromJson(Map<String, dynamic> json) {
    final rawKey = (json['key'] as String? ?? '').trim().toLowerCase();
    final rawModifiers = (json['modifiers'] as List<dynamic>? ?? [])
        .map((m) {
          final mod = m.toString().trim().toLowerCase();
          if (mod == 'ctrl') return 'control';
          if (mod == 'cmd' || mod == 'meta') return 'command';
          return mod;
        })
        .where((m) => m.isNotEmpty)
        .toList();

    return DesktopShortcut(
      key: rawKey,
      modifiers: rawModifiers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key.toLowerCase(),
      'modifiers': modifiers.map((m) => m.toLowerCase()).toList(),
    };
  }

  /// Whether the shortcut combination is valid.
  bool get isValid {
    final cleanKey = key.trim().toLowerCase();
    if (cleanKey.isEmpty) return false;

    // A modifier cannot be the primary key
    const modifierTokens = {
      'control',
      'ctrl',
      'option',
      'alt',
      'shift',
      'command',
      'cmd',
      'meta',
      'windows',
      'win',
    };
    if (modifierTokens.contains(cleanKey)) return false;

    if (modifiers.isEmpty) return false;

    final seen = <String>{};
    for (final m in modifiers) {
      final norm = _canonicalModifier(m);
      if (norm.isEmpty || !seen.add(norm)) return false;
    }

    return true;
  }

  /// Canonical modifier grouping to detect duplicates (e.g. 'alt' and 'option').
  static String _canonicalModifier(String mod) {
    final clean = mod.trim().toLowerCase();
    if (clean == 'ctrl' || clean == 'control') return 'control';
    if (clean == 'alt' || clean == 'option') return 'alt';
    if (clean == 'shift') return 'shift';
    if (clean == 'cmd' || clean == 'command' || clean == 'meta' || clean == 'windows' || clean == 'win') {
      return 'meta';
    }
    return clean;
  }

  /// Human-readable display string using platform-appropriate naming and canonical order.
  String displayString({required bool isMacOS}) {
    final parts = <String>[];

    // Canonical order: Control -> Option/Alt -> Shift -> Command/Win
    final canonicalModifiers = modifiers.map(_canonicalModifier).toSet();

    if (canonicalModifiers.contains('control')) {
      parts.add(isMacOS ? 'Control' : 'Ctrl');
    }
    if (canonicalModifiers.contains('alt')) {
      parts.add(isMacOS ? 'Option' : 'Alt');
    }
    if (canonicalModifiers.contains('shift')) {
      parts.add('Shift');
    }
    if (canonicalModifiers.contains('meta')) {
      parts.add(isMacOS ? 'Command' : 'Windows');
    }

    // Capitalize key
    final cleanKey = key.trim();
    if (cleanKey.toLowerCase() == 'space') {
      parts.add('Space');
    } else if (cleanKey.length == 1) {
      parts.add(cleanKey.toUpperCase());
    } else if (cleanKey.isNotEmpty) {
      parts.add(cleanKey[0].toUpperCase() + cleanKey.substring(1));
    }

    return parts.join(' + ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DesktopShortcut) return false;

    if (key.trim().toLowerCase() != other.key.trim().toLowerCase()) return false;

    final myMods = modifiers.map(_canonicalModifier).toSet();
    final otherMods = other.modifiers.map(_canonicalModifier).toSet();
    return myMods.length == otherMods.length && myMods.containsAll(otherMods);
  }

  @override
  int get hashCode => Object.hash(
        key.trim().toLowerCase(),
        Object.hashAllUnordered(modifiers.map(_canonicalModifier)),
      );

  @override
  String toString() => 'DesktopShortcut(key: $key, modifiers: $modifiers)';
}
