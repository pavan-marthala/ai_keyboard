import 'package:freezed_annotation/freezed_annotation.dart';

part 'command_entity.freezed.dart';
part 'command_entity.g.dart';

@freezed
abstract class CommandEntity with _$CommandEntity {
  const factory CommandEntity({
    required String trigger,
    required String name,
    required String description,
    required String prompt,
    @Default(true) bool enabled,
  }) = _CommandEntity;

  factory CommandEntity.fromJson(Map<String, dynamic> json) =>
      _$CommandEntityFromJson(json);
}
