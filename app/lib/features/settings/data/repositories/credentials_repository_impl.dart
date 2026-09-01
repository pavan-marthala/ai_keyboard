import 'package:ai_keyboard/core/errors/failures.dart';
import 'package:ai_keyboard/core/errors/result.dart';
import 'package:ai_keyboard/features/settings/domain/entities/ai_provider_type.dart';
import 'package:ai_keyboard/features/settings/domain/repositories/credentials_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CredentialsRepository)
class CredentialsRepositoryImpl implements CredentialsRepository {
  final FlutterSecureStorage _secureStorage;

  CredentialsRepositoryImpl(this._secureStorage);

  String _getKeyForProvider(AiProviderType provider) =>
      'api_key_${provider.name}';

  @override
  Future<Result<String?, Failure>> getApiKey(AiProviderType provider) async {
    try {
      final apiKey =
          await _secureStorage.read(key: _getKeyForProvider(provider));
      return Success(apiKey);
    } catch (e) {
      return FailureResult(Failure.cache(message: e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> saveApiKey(
    AiProviderType provider,
    String apiKey,
  ) async {
    try {
      await _secureStorage.write(
        key: _getKeyForProvider(provider),
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
      await _secureStorage.delete(key: _getKeyForProvider(provider));
      return const Success(null);
    } catch (e) {
      return FailureResult(Failure.cache(message: e.toString()));
    }
  }
}
