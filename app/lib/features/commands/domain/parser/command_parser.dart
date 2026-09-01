import 'package:ai_keyboard/features/commands/domain/entities/command_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'command_parser.freezed.dart';

@freezed
abstract class ParsedCommandResult with _$ParsedCommandResult {
  const factory ParsedCommandResult({
    required String cleanText,
    required CommandEntity command,
  }) = _ParsedCommandResult;
}

class CommandParser {
  /// Parses the input string against a list of available commands.
  /// Identifies valid command triggers starting with '@'.
  /// Returns [ParsedCommandResult] if a registered, enabled command is found; otherwise returns `null`.
  static ParsedCommandResult? parse({
    required String input,
    required List<CommandEntity> availableCommands,
  }) {
    if (input.trim().isEmpty) return null;

    final enabledCommands = availableCommands.where((c) => c.enabled).toList();
    if (enabledCommands.isEmpty) return null;

    final trimmedInput = input.trim();
    final tokens = trimmedInput.split(RegExp(r'\s+'));

    if (tokens.isEmpty) return null;

    for (int i = tokens.length - 1; i >= 0; i--) {
      final token = tokens[i];
      if (token.startsWith('@')) {
        final cleanTrigger = token.replaceAll(RegExp(r'[.,!?]+$'), '');
        final matchedCommand = enabledCommands.firstWhere(
          (c) => c.trigger.toLowerCase() == cleanTrigger.toLowerCase(),
          orElse: () => const CommandEntity(
            trigger: '',
            name: '',
            description: '',
            prompt: '',
            enabled: false,
          ),
        );

        if (matchedCommand.trigger.isNotEmpty) {
          final remainingTokens = List<String>.from(tokens)..removeAt(i);
          final cleanText = remainingTokens.join(' ').trim();

          return ParsedCommandResult(
            cleanText: cleanText,
            command: matchedCommand,
          );
        }
      }
    }

    return null;
  }
}
