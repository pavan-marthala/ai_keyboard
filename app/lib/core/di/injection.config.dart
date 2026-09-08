// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:atfix/core/di/register_module.dart' as _i49;
import 'package:atfix/features/ai_service/data/providers/gemini_provider.dart'
    as _i742;
import 'package:atfix/features/ai_service/data/providers/groq_provider.dart'
    as _i47;
import 'package:atfix/features/ai_service/data/providers/openai_provider.dart'
    as _i365;
import 'package:atfix/features/ai_service/data/providers/openrouter_provider.dart'
    as _i935;
import 'package:atfix/features/ai_service/data/repositories/ai_repository_impl.dart'
    as _i793;
import 'package:atfix/features/ai_service/domain/repositories/ai_repository.dart'
    as _i675;
import 'package:atfix/features/ai_service/domain/usecases/transform_text_usecase.dart'
    as _i340;
import 'package:atfix/features/commands/data/repositories/prompt_repository.dart'
    as _i882;
import 'package:atfix/features/commands/domain/repositories/command_registry.dart'
    as _i146;
import 'package:atfix/features/commands/presentation/bloc/command_bloc.dart'
    as _i528;
import 'package:atfix/features/desktop_onboarding/data/datasources/desktop_platform_channel_datasource.dart'
    as _i801;
import 'package:atfix/features/desktop_onboarding/data/repositories/desktop_capability_repository_impl.dart'
    as _i362;
import 'package:atfix/features/desktop_onboarding/domain/repositories/desktop_capability_repository.dart'
    as _i527;
import 'package:atfix/features/desktop_onboarding/presentation/bloc/desktop_onboarding_bloc.dart'
    as _i1065;
import 'package:atfix/features/playground/data/services/keyboard_status_service.dart'
    as _i818;
import 'package:atfix/features/settings/data/repositories/credentials_repository_impl.dart'
    as _i871;
import 'package:atfix/features/settings/data/repositories/settings_repository_impl.dart'
    as _i20;
import 'package:atfix/features/settings/domain/repositories/credentials_repository.dart'
    as _i1021;
import 'package:atfix/features/settings/domain/repositories/settings_repository.dart'
    as _i261;
import 'package:atfix/features/settings/presentation/bloc/settings_bloc.dart'
    as _i251;
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
    gh.lazySingleton<_i801.DesktopPlatformChannelDataSource>(
      () => _i801.DesktopPlatformChannelDataSource(),
    );
    gh.lazySingleton<_i818.KeyboardStatusService>(
      () => _i818.KeyboardStatusService(),
    );
    gh.lazySingleton<_i882.PromptRepository>(
      () => _i882.PromptRepositoryImpl(),
    );
    gh.lazySingleton<_i527.DesktopCapabilityRepository>(
      () => _i362.DesktopCapabilityRepositoryImpl(
        gh<_i460.SharedPreferences>(),
        gh<_i801.DesktopPlatformChannelDataSource>(),
      ),
    );
    gh.lazySingleton<_i742.GeminiProvider>(
      () => _i742.GeminiProvider(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i47.GroqProvider>(
      () => _i47.GroqProvider(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i365.OpenAiProvider>(
      () => _i365.OpenAiProvider(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i935.OpenRouterProvider>(
      () => _i935.OpenRouterProvider(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i261.SettingsRepository>(
      () => _i20.SettingsRepositoryImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i1021.CredentialsRepository>(
      () => _i871.CredentialsRepositoryImpl(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i146.CommandRegistry>(
      () => _i146.CommandRegistryImpl(gh<_i882.PromptRepository>()),
    );
    gh.factory<_i1065.DesktopOnboardingBloc>(
      () =>
          _i1065.DesktopOnboardingBloc(gh<_i527.DesktopCapabilityRepository>()),
    );
    gh.lazySingleton<_i675.AiRepository>(
      () => _i793.AiRepositoryImpl(
        gh<_i365.OpenAiProvider>(),
        gh<_i742.GeminiProvider>(),
        gh<_i935.OpenRouterProvider>(),
        gh<_i47.GroqProvider>(),
      ),
    );
    gh.factory<_i251.SettingsBloc>(
      () => _i251.SettingsBloc(
        gh<_i261.SettingsRepository>(),
        gh<_i1021.CredentialsRepository>(),
        gh<_i675.AiRepository>(),
      ),
    );
    gh.factory<_i528.CommandBloc>(
      () => _i528.CommandBloc(
        gh<_i460.SharedPreferences>(),
        gh<_i146.CommandRegistry>(),
      ),
    );
    gh.factory<_i340.TransformTextUseCase>(
      () => _i340.TransformTextUseCase(
        gh<_i675.AiRepository>(),
        gh<_i261.SettingsRepository>(),
        gh<_i1021.CredentialsRepository>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i49.RegisterModule {}
