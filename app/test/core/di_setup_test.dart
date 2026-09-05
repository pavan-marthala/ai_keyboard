import 'package:atfix/core/di/injection.dart';
import 'package:atfix/features/ai_service/domain/repositories/ai_repository.dart';
import 'package:atfix/features/ai_service/domain/usecases/transform_text_usecase.dart';
import 'package:atfix/features/commands/presentation/bloc/command_bloc.dart';
import 'package:atfix/features/settings/domain/repositories/credentials_repository.dart';
import 'package:atfix/features/settings/domain/repositories/settings_repository.dart';
import 'package:atfix/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await getIt.reset();
  });

  test('should register and resolve core dependencies', () async {
    await configureDependencies();

    expect(getIt.isRegistered<SettingsRepository>(), isTrue);
    expect(getIt.isRegistered<CredentialsRepository>(), isTrue);
    expect(getIt.isRegistered<SettingsBloc>(), isTrue);
    expect(getIt.isRegistered<CommandBloc>(), isTrue);
    expect(getIt.isRegistered<AiRepository>(), isTrue);
    expect(getIt.isRegistered<TransformTextUseCase>(), isTrue);
  });
}
