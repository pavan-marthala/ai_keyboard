import 'package:atfix/core/errors/failures.dart';
import 'package:atfix/core/errors/result.dart';
import 'package:atfix/features/ai_service/domain/entities/ai_model.dart';
import 'package:atfix/features/ai_service/domain/entities/ai_request.dart';
import 'package:atfix/features/ai_service/domain/entities/ai_response.dart';
import 'package:atfix/features/settings/domain/entities/ai_provider_type.dart';

abstract class AiRepository {
  Future<Result<List<AiModel>, Failure>> getModels({
    required AiProviderType provider,
    required String apiKey,
    bool forceRefresh = false,
  });

  Future<Result<AiResponse, Failure>> transformText({
    required AiRequest request,
    required String apiKey,
  });
}
