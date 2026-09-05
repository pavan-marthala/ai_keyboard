import 'package:atfix/core/errors/failures.dart';
import 'package:atfix/core/errors/result.dart';
import 'package:atfix/features/settings/domain/entities/ai_provider_type.dart';

abstract class CredentialsRepository {
  Future<Result<String?, Failure>> getApiKey(AiProviderType provider);
  Future<Result<void, Failure>> saveApiKey(
    AiProviderType provider,
    String apiKey,
  );
  Future<Result<void, Failure>> deleteApiKey(AiProviderType provider);
}
