import 'package:atfix/features/shortcuts/domain/entities/desktop_shortcut.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DesktopShortcut', () {
    test('default shortcuts are defined correctly', () {
      expect(DesktopShortcut.macOsDefault.key, 'space');
      expect(DesktopShortcut.macOsDefault.modifiers, ['control', 'option']);

      expect(DesktopShortcut.windowsDefault.key, 'space');
      expect(DesktopShortcut.windowsDefault.modifiers, ['control', 'alt']);
    });

    test('defaultForPlatform respects isMacOS parameter', () {
      final mac = DesktopShortcut.defaultForPlatform(isMacOS: true);
      expect(mac, equals(DesktopShortcut.macOsDefault));

      final win = DesktopShortcut.defaultForPlatform(isMacOS: false);
      expect(win, equals(DesktopShortcut.windowsDefault));
    });

    test('toJson and fromJson serialize and deserialize correctly', () {
      const shortcut = DesktopShortcut(
        key: 'space',
        modifiers: ['control', 'alt'],
      );

      final json = shortcut.toJson();
      expect(json, {
        'key': 'space',
        'modifiers': ['control', 'alt'],
      });

      final reconstructed = DesktopShortcut.fromJson(json);
      expect(reconstructed, equals(shortcut));
    });

    test('canonical modifiers normalization', () {
      final shortcut = DesktopShortcut.fromJson({
        'key': 'A',
        'modifiers': ['CTRL', 'ALT', 'CMD', 'SHIFT'],
      });

      expect(shortcut.key, 'a');
      expect(shortcut.modifiers, containsAll(['control', 'alt', 'command', 'shift']));
    });

    test('displayString formats correctly for macOS and Windows', () {
      const macShortcut = DesktopShortcut(
        key: 'space',
        modifiers: ['control', 'option'],
      );
      expect(macShortcut.displayString(isMacOS: true), 'Control + Option + Space');

      const winShortcut = DesktopShortcut(
        key: 'space',
        modifiers: ['control', 'alt'],
      );
      expect(winShortcut.displayString(isMacOS: false), 'Ctrl + Alt + Space');

      const fullMacShortcut = DesktopShortcut(
        key: 'k',
        modifiers: ['control', 'option', 'command', 'shift'],
      );
      expect(
        fullMacShortcut.displayString(isMacOS: true),
        'Control + Option + Shift + Command + K',
      );

      const fullWinShortcut = DesktopShortcut(
        key: 'k',
        modifiers: ['control', 'alt', 'windows', 'shift'],
      );
      expect(
        fullWinShortcut.displayString(isMacOS: false),
        'Ctrl + Alt + Shift + Windows + K',
      );
    });

    test('validation rules work as expected', () {
      // Valid shortcut
      expect(
        const DesktopShortcut(key: 'space', modifiers: ['control', 'alt']).isValid,
        isTrue,
      );

      // Empty key is invalid
      expect(
        const DesktopShortcut(key: '', modifiers: ['control', 'alt']).isValid,
        isFalse,
      );

      // Empty modifiers is invalid
      expect(
        const DesktopShortcut(key: 'space', modifiers: []).isValid,
        isFalse,
      );

      // Modifier key as primary key is invalid
      expect(
        const DesktopShortcut(key: 'control', modifiers: ['alt']).isValid,
        isFalse,
      );
      expect(
        const DesktopShortcut(key: 'shift', modifiers: ['control']).isValid,
        isFalse,
      );
    });
  });
}
