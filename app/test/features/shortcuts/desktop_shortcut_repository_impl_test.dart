import 'dart:convert';

import 'package:atfix/features/desktop_onboarding/data/datasources/desktop_platform_channel_datasource.dart';
import 'package:atfix/features/shortcuts/data/repositories/desktop_shortcut_repository_impl.dart';
import 'package:atfix/features/shortcuts/domain/entities/desktop_shortcut.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDesktopPlatformChannelDataSource
    implements DesktopPlatformChannelDataSource {
  bool registerHotkeyResult = true;
  Map<String, dynamic>? lastRegisteredHotkey;

  @override
  Future<bool> registerHotkey(Map<String, dynamic> shortcutJson) async {
    lastRegisteredHotkey = shortcutJson;
    return registerHotkeyResult;
  }

  @override
  Future<Map<String, dynamic>?> getRegisteredHotkey() async {
    return lastRegisteredHotkey;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late MockDesktopPlatformChannelDataSource dataSource;
  late DesktopShortcutRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    dataSource = MockDesktopPlatformChannelDataSource();
    repository = DesktopShortcutRepositoryImpl(prefs, dataSource);
  });

  group('DesktopShortcutRepositoryImpl', () {
    test('getShortcut returns default when nothing is stored', () async {
      final shortcut = await repository.getShortcut();
      expect(shortcut.isValid, isTrue);
      expect(shortcut.key, 'space');
    });

    test('getShortcut returns stored shortcut when valid', () async {
      const stored = DesktopShortcut(key: 'k', modifiers: ['control', 'option']);
      await prefs.setString('desktop_shortcut', jsonEncode(stored.toJson()));

      final shortcut = await repository.getShortcut();
      expect(shortcut, equals(stored));
    });

    test('registerAndSaveShortcut persists when registration succeeds', () async {
      dataSource.registerHotkeyResult = true;

      const candidate = DesktopShortcut(key: 'j', modifiers: ['control', 'alt']);
      final result = await repository.registerAndSaveShortcut(candidate);

      expect(result, isTrue);
      expect(dataSource.lastRegisteredHotkey, equals(candidate.toJson()));

      final rawStored = prefs.getString('desktop_shortcut');
      expect(rawStored, isNotNull);
      final decoded = DesktopShortcut.fromJson(jsonDecode(rawStored!));
      expect(decoded, equals(candidate));
    });

    test('registerAndSaveShortcut does NOT persist when registration fails', () async {
      const existing = DesktopShortcut(key: 'space', modifiers: ['control', 'option']);
      await prefs.setString('desktop_shortcut', jsonEncode(existing.toJson()));

      dataSource.registerHotkeyResult = false;

      const candidate = DesktopShortcut(key: 'x', modifiers: ['control', 'alt']);
      final result = await repository.registerAndSaveShortcut(candidate);

      expect(result, isFalse);

      // Verify storage still has the existing shortcut
      final rawStored = prefs.getString('desktop_shortcut');
      final decoded = DesktopShortcut.fromJson(jsonDecode(rawStored!));
      expect(decoded, equals(existing));
    });

    test('rejects invalid shortcut without calling datasource', () async {
      const invalid = DesktopShortcut(key: '', modifiers: []);
      final result = await repository.registerAndSaveShortcut(invalid);

      expect(result, isFalse);
      expect(dataSource.lastRegisteredHotkey, isNull);
    });
  });
}
