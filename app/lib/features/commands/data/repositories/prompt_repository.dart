import 'package:atfix/features/commands/data/generated/generated_command_definitions.dart';
import 'package:atfix/features/commands/domain/entities/command_definition.dart';
import 'package:injectable/injectable.dart';

abstract interface class PromptRepository {
  List<CommandDefinition> get commands;
  CommandDefinition? getCommand(String triggerOrId);
  String? getPrompt(String id, [Map<String, String>? variables]);
  String getActionLabel(String triggerOrId);
  bool hasPrompt(String id);
}

@LazySingleton(as: PromptRepository)
class PromptRepositoryImpl implements PromptRepository {
  final List<CommandDefinition> _commands = [];
  final Map<String, CommandDefinition> _commandsById = {};
  final Map<String, CommandDefinition> _commandsByTrigger = {};

  PromptRepositoryImpl([List<GeneratedCommandDefinition>? customCommands]) {
    _populate(customCommands ?? GeneratedCommandDefinitions.commands);
  }

  void _populate(List<GeneratedCommandDefinition> source) {
    _commands.clear();
    _commandsById.clear();
    _commandsByTrigger.clear();

    for (final gen in source) {
      final cmd = CommandDefinition(
        id: gen.id,
        command: gen.command,
        label: gen.label,
        actionLabel: gen.actionLabel,
        description: gen.description,
        order: gen.order,
        requiresInput: gen.requiresInput,
        inputType: gen.inputType,
        system: gen.system,
      );
      _commands.add(cmd);
      _commandsById[cmd.id.toLowerCase()] = cmd;
      _commandsByTrigger[cmd.command.toLowerCase()] = cmd;
    }
  }

  @override
  List<CommandDefinition> get commands => List.unmodifiable(_commands);

  @override
  CommandDefinition? getCommand(String triggerOrId) {
    final clean = triggerOrId.trim().toLowerCase();
    final base = clean.contains(':') ? clean.split(':').first : clean;
    return _commandsByTrigger[base] ?? _commandsById[base];
  }

  @override
  String? getPrompt(String id, [Map<String, String>? variables]) {
    final cmd = getCommand(id);
    if (cmd == null) return null;

    var template = cmd.system;
    if (variables != null) {
      variables.forEach((key, val) {
        template = template.replaceAll('{{$key}}', val);
      });
    }
    return template;
  }

  @override
  String getActionLabel(String triggerOrId) {
    final cmd = getCommand(triggerOrId);
    return cmd?.actionLabel ?? 'Transforming...';
  }

  @override
  bool hasPrompt(String id) {
    return getCommand(id) != null;
  }
}

