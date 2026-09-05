import 'package:atfix/features/settings/domain/entities/ai_provider_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_model.freezed.dart';
part 'ai_model.g.dart';

@freezed
abstract class AiModel with _$AiModel {
  const factory AiModel({
    required String id,
    required String displayName,
    required AiProviderType provider,
    String? description,
    @Default([]) List<String> capabilities,
  }) = _AiModel;

  factory AiModel.fromJson(Map<String, dynamic> json) =>
      _$AiModelFromJson(json);
}
