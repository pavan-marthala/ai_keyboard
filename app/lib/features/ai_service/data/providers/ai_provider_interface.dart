import 'package:atfix/core/errors/failures.dart';
import 'package:atfix/core/errors/result.dart';
import 'package:atfix/features/ai_service/domain/entities/ai_model.dart';
import 'package:atfix/features/ai_service/domain/entities/ai_request.dart';
import 'package:atfix/features/ai_service/domain/entities/ai_response.dart';
import 'package:atfix/features/settings/domain/entities/ai_provider_type.dart';

abstract class AiProvider {
  AiProviderType get type;
  Future<Result<List<AiModel>, Failure>> getModels(String apiKey);
  Future<Result<AiResponse, Failure>> transform({
    required AiRequest request,
    required String apiKey,
  });
}
