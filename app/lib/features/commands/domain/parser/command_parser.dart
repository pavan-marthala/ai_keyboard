import 'package:atfix/features/commands/domain/entities/command_entity.dart';
import 'package:atfix/features/commands/domain/repositories/command_registry.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'command_parser.freezed.dart';

@freezed
abstract class ParsedCommandResult with _$ParsedCommandResult {
  const factory ParsedCommandResult({
    required String cleanText,
    required CommandEntity command,
    required String rawTrigger,
    required Map<String, String> arguments,
    required String prompt,
  }) = _ParsedCommandResult;
}

class CommandParser {
  /// Parses the input string against available commands.
  /// Strictly checks commands located at the END of the input text.
  /// Ignores emails, usernames, URLs, and unsupported parameters.
  static ParsedCommandResult? parse({
    required String input,
    required List<CommandEntity> availableCommands,
  }) {
    if (input.trim().isEmpty) return null;

    final enabledCommands = availableCommands.where((c) => c.enabled).toList();
    if (enabledCommands.isEmpty) return null;

    final trimmedInput = input.trimRight();
    final tokens = trimmedInput.split(RegExp(r'\s+'));
    if (tokens.isEmpty) return null;

    final lastToken = tokens.last;
    if (!lastToken.startsWith('@')) return null;

    // False positive check: emails or URLs
    if (lastToken.contains('://')) return null;

    final cleanLastToken = lastToken.replaceAll(RegExp(r'[.,!?]+$'), '');
    final String rawTrigger = cleanLastToken.toLowerCase();

    String baseTrigger = rawTrigger;
    final Map<String, String> arguments = {};

    if (rawTrigger.contains(':')) {
      final parts = rawTrigger.split(':');
      baseTrigger = parts.first;
      if (parts.length > 1) {
        arguments['language'] = parts[1].toLowerCase();
      }
    }

    final matchedCommand = enabledCommands.firstWhere(
      (c) => c.trigger.toLowerCase() == baseTrigger,
      orElse: () => const CommandEntity(
        trigger: '',
        name: '',
        description: '',
        prompt: '',
        enabled: false,
      ),
    );

    if (matchedCommand.trigger.isEmpty) return null;

    // Special validation for @translate
    if (baseTrigger == '@translate') {
      final lang = arguments['language'];
      if (lang == null ||
          !CommandRegistry.supportedLanguages.containsKey(lang)) {
        return null; // Invalid or missing language code
      }
    }

    final remainingTokens = tokens.sublist(0, tokens.length - 1);
    final cleanText = remainingTokens.join(' ').trim();
    if (cleanText.isEmpty) return null; // Require non-empty text before command

    final registry = CommandRegistryImpl();
    final prompt = registry.buildPrompt(matchedCommand, arguments);

    return ParsedCommandResult(
      cleanText: cleanText,
      command: matchedCommand,
      rawTrigger: rawTrigger,
      arguments: arguments,
      prompt: prompt,
    );
  }
}
