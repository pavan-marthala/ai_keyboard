import 'package:ai_keyboard/core/errors/failures.dart';
import 'package:ai_keyboard/core/errors/result.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_model.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_request.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_response.dart';
import 'package:ai_keyboard/features/settings/domain/entities/ai_provider_type.dart';

abstract class AiProvider {
  AiProviderType get type;
  Future<Result<List<AiModel>, Failure>> getModels(String apiKey);
  Future<Result<AiResponse, Failure>> transform({
    required AiRequest request,
    required String apiKey,
  });
}
