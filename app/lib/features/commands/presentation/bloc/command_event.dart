import 'package:ai_keyboard/features/commands/domain/entities/command_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'command_event.freezed.dart';

@freezed
class CommandEvent with _$CommandEvent {
  const factory CommandEvent.loadCommands() = _LoadCommands;
  const factory CommandEvent.addCommand(CommandEntity command) = _AddCommand;
  const factory CommandEvent.updateCommand(CommandEntity command) =
      _UpdateCommand;
  const factory CommandEvent.deleteCommand(String trigger) = _DeleteCommand;
  const factory CommandEvent.toggleCommandEnabled(String trigger) =
      _ToggleCommandEnabled;
  const factory CommandEvent.resetToDefaults() = _ResetToDefaults;
}
