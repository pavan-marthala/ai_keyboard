import 'package:ai_keyboard/core/errors/failures.dart';
import 'package:ai_keyboard/core/errors/result.dart';
import 'package:ai_keyboard/features/settings/domain/entities/user_settings.dart';

abstract class SettingsRepository {
  Future<Result<UserSettings, Failure>> getSettings();
  Future<Result<void, Failure>> saveSettings(UserSettings settings);
}
