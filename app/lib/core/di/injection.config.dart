// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:ai_keyboard/core/di/register_module.dart' as _i638;
import 'package:ai_keyboard/features/ai_service/data/providers/gemini_provider.dart'
    as _i369;
import 'package:ai_keyboard/features/ai_service/data/providers/groq_provider.dart'
    as _i362;
import 'package:ai_keyboard/features/ai_service/data/providers/openai_provider.dart'
    as _i788;
import 'package:ai_keyboard/features/ai_service/data/providers/openrouter_provider.dart'
    as _i339;
import 'package:ai_keyboard/features/ai_service/data/repositories/ai_repository_impl.dart'
    as _i754;
import 'package:ai_keyboard/features/ai_service/domain/repositories/ai_repository.dart'
    as _i177;
import 'package:ai_keyboard/features/ai_service/domain/usecases/transform_text_usecase.dart'
    as _i532;
import 'package:ai_keyboard/features/commands/domain/repositories/command_registry.dart'
    as _i648;
import 'package:ai_keyboard/features/commands/presentation/bloc/command_bloc.dart'
    as _i45;
import 'package:ai_keyboard/features/desktop_onboarding/data/datasources/desktop_platform_channel_datasource.dart'
    as _i469;
import 'package:ai_keyboard/features/desktop_onboarding/data/repositories/desktop_capability_repository_impl.dart'
    as _i899;
import 'package:ai_keyboard/features/desktop_onboarding/domain/repositories/desktop_capability_repository.dart'
    as _i860;
import 'package:ai_keyboard/features/desktop_onboarding/presentation/bloc/desktop_onboarding_bloc.dart'
    as _i1036;
import 'package:ai_keyboard/features/playground/data/services/keyboard_status_service.dart'
    as _i608;
import 'package:ai_keyboard/features/settings/data/repositories/credentials_repository_impl.dart'
    as _i499;
import 'package:ai_keyboard/features/settings/data/repositories/settings_repository_impl.dart'
    as _i725;
import 'package:ai_keyboard/features/settings/domain/repositories/credentials_repository.dart'
    as _i921;
import 'package:ai_keyboard/features/settings/domain/repositories/settings_repository.dart'
    as _i615;
import 'package:ai_keyboard/features/settings/presentation/bloc/settings_bloc.dart'
    as _i144;
import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i361.Dio>(() => registerModule.dio);
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i469.DesktopPlatformChannelDataSource>(
      () => _i469.DesktopPlatformChannelDataSource(),
    );
    gh.lazySingleton<_i608.KeyboardStatusService>(
      () => _i608.KeyboardStatusService(),
    );
    gh.lazySingleton<_i648.CommandRegistry>(() => _i648.CommandRegistryImpl());
    gh.lazySingleton<_i369.GeminiProvider>(
      () => _i369.GeminiProvider(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i362.GroqProvider>(
      () => _i362.GroqProvider(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i788.OpenAiProvider>(
      () => _i788.OpenAiProvider(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i339.OpenRouterProvider>(
      () => _i339.OpenRouterProvider(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i615.SettingsRepository>(
      () => _i725.SettingsRepositoryImpl(gh<_i460.SharedPreferences>()),
    );
    gh.factory<_i45.CommandBloc>(
      () => _i45.CommandBloc(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i860.DesktopCapabilityRepository>(
      () => _i899.DesktopCapabilityRepositoryImpl(
        gh<_i460.SharedPreferences>(),
        gh<_i469.DesktopPlatformChannelDataSource>(),
      ),
    );
    gh.lazySingleton<_i921.CredentialsRepository>(
      () => _i499.CredentialsRepositoryImpl(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i177.AiRepository>(
      () => _i754.AiRepositoryImpl(
        gh<_i788.OpenAiProvider>(),
        gh<_i369.GeminiProvider>(),
        gh<_i339.OpenRouterProvider>(),
        gh<_i362.GroqProvider>(),
      ),
    );
    gh.factory<_i1036.DesktopOnboardingBloc>(
      () =>
          _i1036.DesktopOnboardingBloc(gh<_i860.DesktopCapabilityRepository>()),
    );
    gh.factory<_i532.TransformTextUseCase>(
      () => _i532.TransformTextUseCase(
        gh<_i177.AiRepository>(),
        gh<_i615.SettingsRepository>(),
        gh<_i921.CredentialsRepository>(),
      ),
    );
    gh.factory<_i144.SettingsBloc>(
      () => _i144.SettingsBloc(
        gh<_i615.SettingsRepository>(),
        gh<_i921.CredentialsRepository>(),
        gh<_i177.AiRepository>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i638.RegisterModule {}
