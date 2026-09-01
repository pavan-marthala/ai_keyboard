import 'package:ai_keyboard/features/commands/domain/entities/command_entity.dart';
import 'package:injectable/injectable.dart';

abstract interface class CommandRegistry {
  List<CommandEntity> get commands;
  CommandEntity? findByTrigger(String trigger);
  bool isEnabled(String trigger);
  String buildPrompt(CommandEntity command, Map<String, String> args);

  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'hi': 'Hindi',
    'te': 'Telugu',
    'kn': 'Kannada',
    'ta': 'Tamil',
  };
}

@LazySingleton(as: CommandRegistry)
class CommandRegistryImpl implements CommandRegistry {
  static const fixPrompt =
      '''You are a text transformation engine inside a keyboard application.

Correct the user's text.

Rules:
- Return ONLY the corrected text.
- Do not explain changes.
- Do not answer questions.
- Do not add information.
- Preserve the original meaning.
- Fix grammar, spelling, punctuation, capitalization, and obvious sentence-formation errors.
- If the text is already correct, return it unchanged.
- If the text is unclear, incomplete, slang, a name, a technical term, or random text, preserve it rather than asking questions.
- Never mention being an AI or assistant.
- Do not add notes, explanations, disclaimers, or commentary.
- Do not wrap the result in quotation marks.
- Preserve URLs, usernames, hashtags, numbers, emojis, and intentional formatting.

Return exactly one transformed text.''';

  static const rewritePrompt =
      '''Rewrite the user's text while preserving its original meaning.

Return ONLY the rewritten text.

Do not:
- explain the rewrite
- answer questions
- add information
- add introductions or conclusions
- mention AI
- use quotation marks around the result

Preserve important names, numbers, URLs, usernames, and factual information.''';

  static const proPrompt =
      '''Rewrite the user's text in a clear, professional tone.

Return ONLY the transformed text.

Preserve the original meaning and facts.
Do not invent information.
Do not explain the changes.
Do not answer questions.
Do not add commentary.
Do not mention AI.
Do not wrap the result in quotation marks.''';

  static const casualPrompt =
      '''Rewrite the user's text in a natural, friendly, conversational tone.

Return ONLY the transformed text.

Preserve the original meaning.
Do not add information.
Do not explain the changes.
Do not answer questions.
Do not mention AI.
Do not wrap the result in quotation marks.''';

  static const shortPrompt = '''Make the user's text shorter and more concise while preserving its meaning.

Return ONLY the shortened text.

Do not remove important information.
Do not add information.
Do not explain what was changed.
Do not answer questions.
Do not mention AI.
Do not wrap the result in quotation marks.''';

  static const expandPrompt = '''Expand the user's text to make it clearer and more complete while preserving its original meaning.

Do not invent facts or specific details that were not provided.

Return ONLY the expanded text.

Do not explain the changes.
Do not answer questions.
Do not mention AI.
Do not wrap the result in quotation marks.''';

  static final List<CommandEntity> _builtInCommands = [
    const CommandEntity(
      trigger: '@fix',
      name: 'Fix Grammar',
      description: 'Correct grammar, spelling, and punctuation',
      prompt: fixPrompt,
      enabled: true,
    ),
    const CommandEntity(
      trigger: '@rewrite',
      name: 'Rewrite',
      description: 'Rewrite while preserving original meaning',
      prompt: rewritePrompt,
      enabled: true,
    ),
    const CommandEntity(
      trigger: '@pro',
      name: 'Professional',
      description: 'Make writing clear and professional',
      prompt: proPrompt,
      enabled: true,
    ),
    const CommandEntity(
      trigger: '@casual',
      name: 'Casual',
      description: 'Make writing natural and friendly',
      prompt: casualPrompt,
      enabled: true,
    ),
    const CommandEntity(
      trigger: '@short',
      name: 'Shorten',
      description: 'Make text shorter and more concise',
      prompt: shortPrompt,
      enabled: true,
    ),
    const CommandEntity(
      trigger: '@expand',
      name: 'Expand',
      description: 'Expand text for clarity',
      prompt: expandPrompt,
      enabled: true,
    ),
    const CommandEntity(
      trigger: '@translate',
      name: 'Translate',
      description:
          'Translate text to a specified language (e.g. @translate:es)',
      prompt: 'TRANSLATE_PLACEHOLDER',
      enabled: true,
    ),
  ];

  final Set<String> _disabledTriggers = {};

  void setDisabledTriggers(Set<String> disabled) {
    _disabledTriggers.clear();
    _disabledTriggers.addAll(disabled.map((t) => t.toLowerCase()));
  }

  @override
  List<CommandEntity> get commands => _builtInCommands.map((cmd) {
    return cmd.copyWith(
      enabled: !_disabledTriggers.contains(cmd.trigger.toLowerCase()),
    );
  }).toList();

  @override
  CommandEntity? findByTrigger(String trigger) {
    final cleanTrigger = trigger.trim().toLowerCase();
    final baseTrigger = cleanTrigger.contains(':')
        ? cleanTrigger.split(':').first
        : cleanTrigger;

    try {
      final cmd = _builtInCommands.firstWhere(
        (c) => c.trigger.toLowerCase() == baseTrigger,
      );
      return cmd.copyWith(
        enabled: !_disabledTriggers.contains(cmd.trigger.toLowerCase()),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  bool isEnabled(String trigger) {
    final cmd = findByTrigger(trigger);
    return cmd?.enabled ?? false;
  }

  @override
  String buildPrompt(CommandEntity command, Map<String, String> args) {
    if (command.trigger.toLowerCase() == '@translate') {
      final langCode = args['language']?.toLowerCase() ?? '';
      final langName =
          CommandRegistry.supportedLanguages[langCode] ?? 'English';
      return '''Translate the user's text into $langName.

Return ONLY the translated text.

Rules:
- Do not explain the translation.
- Do not answer questions contained in the text.
- Do not add information that was not in the original text.
- Do not mention AI or being an assistant.
- Do not wrap the result in quotation marks.
- Preserve URLs, usernames, numbers, and emojis.

Return exactly one translated result.''';
    }
    return command.prompt;
  }
}
