import 'dart:convert';
import 'package:ai_keyboard/core/errors/failures.dart';
import 'package:ai_keyboard/core/errors/result.dart';
import 'package:ai_keyboard/features/settings/domain/entities/user_settings.dart';
import 'package:ai_keyboard/features/settings/domain/repositories/settings_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferences _prefs;
  static const String _settingsKey = 'user_settings';

  SettingsRepositoryImpl(this._prefs);

  @override
  Future<Result<UserSettings, Failure>> getSettings() async {
    try {
      final jsonString = _prefs.getString(_settingsKey);
      if (jsonString == null) {
        return const Success(UserSettings());
      }
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return Success(UserSettings.fromJson(jsonMap));
    } catch (e) {
      return FailureResult(Failure.cache(message: e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> saveSettings(UserSettings settings) async {
    try {
      final jsonString = jsonEncode(settings.toJson());
      await _prefs.setString(_settingsKey, jsonString);
      return const Success(null);
    } catch (e) {
      return FailureResult(Failure.cache(message: e.toString()));
    }
  }
}
