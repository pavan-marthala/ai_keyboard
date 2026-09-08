import 'dart:convert';

import 'package:atfix/core/utils/check_platforms.dart';
import 'package:atfix/features/desktop_onboarding/data/datasources/desktop_platform_channel_datasource.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/desktop_shortcut.dart';
import '../../domain/repositories/desktop_shortcut_repository.dart';

@LazySingleton(as: DesktopShortcutRepository)
class DesktopShortcutRepositoryImpl implements DesktopShortcutRepository {
  static const String _storageKey = 'desktop_shortcut';

  final SharedPreferences _prefs;
  final DesktopPlatformChannelDataSource _dataSource;

  DesktopShortcutRepositoryImpl(this._prefs, this._dataSource);

  @override
  Future<DesktopShortcut> getShortcut() async {
    if (!PlatformChecker.isMacOS() && !PlatformChecker.isWindows()) {
      return DesktopShortcut.macOsDefault;
    }

    final rawJson = _prefs.getString(_storageKey);
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final map = jsonDecode(rawJson) as Map<String, dynamic>;
        final parsed = DesktopShortcut.fromJson(map);
        if (parsed.isValid) {
          return parsed;
        }
      } catch (_) {}
    }

    return DesktopShortcut.defaultForPlatform();
  }

  @override
  Future<bool> registerShortcut(DesktopShortcut shortcut) async {
    if (!shortcut.isValid) return false;
    return _dataSource.registerHotkey(shortcut.toJson());
  }

  @override
  Future<bool> registerAndSaveShortcut(DesktopShortcut shortcut) async {
    if (!shortcut.isValid) return false;

    final success = await _dataSource.registerHotkey(shortcut.toJson());
    if (success) {
      await _prefs.setString(_storageKey, jsonEncode(shortcut.toJson()));
    }
    return success;
  }
}
