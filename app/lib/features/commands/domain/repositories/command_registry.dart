import 'package:atfix/features/commands/data/repositories/prompt_repository.dart';
import 'package:atfix/features/commands/domain/entities/command_entity.dart';
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
  final PromptRepository _promptRepository;
  final Set<String> _disabledTriggers = {};

  CommandRegistryImpl([PromptRepository? promptRepository])
      : _promptRepository = promptRepository ?? PromptRepositoryImpl();

  PromptRepository get promptRepository => _promptRepository;

  void setDisabledTriggers(Set<String> disabled) {
    _disabledTriggers.clear();
    _disabledTriggers.addAll(disabled.map((t) => t.toLowerCase()));
  }

  @override
  List<CommandEntity> get commands => _promptRepository.commands.map((cmd) {
        return CommandEntity(
          trigger: cmd.command,
          name: cmd.label,
          description: cmd.description,
          prompt: cmd.system,
          enabled: !_disabledTriggers.contains(cmd.command.toLowerCase()),
        );
      }).toList();

  @override
  CommandEntity? findByTrigger(String trigger) {
    final cleanTrigger = trigger.trim().toLowerCase();
    final baseTrigger = cleanTrigger.contains(':')
        ? cleanTrigger.split(':').first
        : cleanTrigger;

    // Explicitly reject @pro
    if (baseTrigger == '@pro' || baseTrigger == 'pro') {
      return null;
    }

    final def = _promptRepository.getCommand(baseTrigger);
    if (def == null) return null;

    return CommandEntity(
      trigger: def.command,
      name: def.label,
      description: def.description,
      prompt: def.system,
      enabled: !_disabledTriggers.contains(def.command.toLowerCase()),
    );
  }

  @override
  bool isEnabled(String trigger) {
    final cmd = findByTrigger(trigger);
    return cmd?.enabled ?? false;
  }

  @override
  String buildPrompt(CommandEntity command, Map<String, String> args) {
    final def = _promptRepository.getCommand(command.trigger);
    final id = def?.id ?? (command.trigger.startsWith('@') ? command.trigger.substring(1) : command.trigger);

    if (id == 'translate') {
      final langCode = args['language']?.toLowerCase() ?? '';
      final langName = CommandRegistry.supportedLanguages[langCode] ?? 'English';
      return _promptRepository.getPrompt('translate', {'language': langName}) ?? command.prompt;
    }

    return _promptRepository.getPrompt(id) ?? command.prompt;
  }
}
