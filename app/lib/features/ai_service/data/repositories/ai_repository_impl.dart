import 'package:ai_keyboard/core/errors/failures.dart';
import 'package:ai_keyboard/core/errors/result.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_request.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_response.dart';
import 'package:ai_keyboard/features/ai_service/domain/repositories/ai_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AiRepository)
class AiRepositoryImpl implements AiRepository {
  @override
  Future<Result<AiResponse, Failure>> transformText({
    required AiRequest request,
    required String apiKey,
  }) async {
    return FailureResult(
      Failure.providerNotConfigured(providerName: request.config.provider.name),
    );
  }
}
