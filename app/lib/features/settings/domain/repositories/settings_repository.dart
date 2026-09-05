import 'package:atfix/core/errors/failures.dart';
import 'package:atfix/core/errors/result.dart';
import 'package:atfix/features/settings/domain/entities/user_settings.dart';

abstract class SettingsRepository {
  Future<Result<UserSettings, Failure>> getSettings();
  Future<Result<void, Failure>> saveSettings(UserSettings settings);
}
