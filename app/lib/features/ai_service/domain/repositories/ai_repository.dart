import 'package:ai_keyboard/core/errors/failures.dart';
import 'package:ai_keyboard/core/errors/result.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_request.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_response.dart';

abstract class AiRepository {
  Future<Result<AiResponse, Failure>> transformText({
    required AiRequest request,
    required String apiKey,
  });
}
