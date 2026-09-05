import 'package:atfix/features/commands/domain/entities/command_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'command_state.freezed.dart';

@freezed
abstract class CommandState with _$CommandState {
  const factory CommandState({
    @Default([]) List<CommandEntity> commands,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _CommandState;
}
