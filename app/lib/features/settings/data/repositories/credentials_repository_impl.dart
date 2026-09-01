import 'package:ai_keyboard/core/errors/failures.dart';
import 'package:ai_keyboard/core/errors/result.dart';
import 'package:ai_keyboard/features/settings/domain/entities/ai_provider_type.dart';
import 'package:ai_keyboard/features/settings/domain/repositories/credentials_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CredentialsRepository)
class CredentialsRepositoryImpl implements CredentialsRepository {
  final FlutterSecureStorage _secureStorage;
  static const _channel = MethodChannel('com.pk.ai_keyboard/credentials');

  CredentialsRepositoryImpl(this._secureStorage);

  @override
  Future<Result<String?, Failure>> getApiKey(AiProviderType provider) async {
    try {
      final String? apiKey = await _channel.invokeMethod('getApiKey', {
        'provider': provider.name,
      });
      if (apiKey != null && apiKey.isNotEmpty) {
        return Success(apiKey);
      }
      final fallbackKey =
          await _secureStorage.read(key: 'api_key_${provider.name}');
      return Success(fallbackKey);
    } catch (e) {
      final apiKey =
          await _secureStorage.read(key: 'api_key_${provider.name}');
      return Success(apiKey);
    }
  }

  @override
  Future<Result<void, Failure>> saveApiKey(
    AiProviderType provider,
    String apiKey,
  ) async {
    try {
      await _channel.invokeMethod('saveApiKey', {
        'provider': provider.name,
        'apiKey': apiKey,
      });
      await _secureStorage.write(
        key: 'api_key_${provider.name}',
        value: apiKey,
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(Failure.cache(message: e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> deleteApiKey(AiProviderType provider) async {
    try {
      await _channel.invokeMethod('deleteApiKey', {
        'provider': provider.name,
      });
      await _secureStorage.delete(key: 'api_key_${provider.name}');
      return const Success(null);
    } catch (e) {
      return FailureResult(Failure.cache(message: e.toString()));
    }
  }
}
