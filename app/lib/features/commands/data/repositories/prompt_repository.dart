import 'dart:convert';
import 'dart:io';

import 'package:atfix/features/commands/domain/entities/command_definition.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  static const String assetPath = 'assets/prompts/ai_prompts.json';

  final List<CommandDefinition> _commands = [];
  final Map<String, CommandDefinition> _commandsById = {};
  final Map<String, CommandDefinition> _commandsByTrigger = {};

  PromptRepositoryImpl() {
    _initialize();
  }

  PromptRepositoryImpl.withJson(String jsonContent) {
    loadFromJson(jsonContent);
  }

  factory PromptRepositoryImpl.fromString(String jsonString) {
    return PromptRepositoryImpl.withJson(jsonString);
  }

  void _initialize() {
    // 1. Try file-based load for test/local runner environments
    try {
      const relativePaths = [
        'assets/prompts/ai_prompts.json',
        '../shared/prompts/ai_prompts.json',
        '../../shared/prompts/ai_prompts.json',
      ];
      for (final path in relativePaths) {
        final file = File(path);
        if (file.existsSync()) {
          loadFromJson(file.readAsStringSync());
          return;
        }
      }
    } catch (_) {}

    // 2. Fallback to bundled schema v2 JSON representation
    loadFromJson(_fallbackV2Json);
  }

  Future<void> loadFromBundle([String path = assetPath]) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      loadFromJson(jsonString);
    } catch (e) {
      debugPrint('[PromptRepository] Failed loading from asset bundle: $e');
    }
  }

  void loadFromJson(String jsonContent) {
    final root = jsonDecode(jsonContent) as Map<String, dynamic>;
    final rawCommands = root['commands'] as Map<String, dynamic>?;
    if (rawCommands == null) {
      throw const FormatException('Missing "commands" dictionary in JSON');
    }

    final parsedCommands = <CommandDefinition>[];
    final seenIds = <String>{};
    final seenTriggers = <String>{};

    rawCommands.forEach((key, value) {
      if (value is! Map<String, dynamic>) {
        throw FormatException('Command entry "$key" must be a JSON object');
      }
      final def = CommandDefinition.fromJson(key, value);

      if (seenIds.contains(def.id)) {
        throw FormatException('Duplicate command id: "${def.id}"');
      }
      seenIds.add(def.id);

      final lowerTrigger = def.command.toLowerCase();
      if (seenTriggers.contains(lowerTrigger)) {
        throw FormatException('Duplicate command trigger: "${def.command}"');
      }
      seenTriggers.add(lowerTrigger);

      parsedCommands.add(def);
    });

    if (!seenIds.contains('professional') || !seenTriggers.contains('@professional')) {
      throw const FormatException('Canonical command @professional is required');
    }
    if (seenIds.contains('pro') || seenTriggers.contains('@pro')) {
      throw const FormatException('@pro is deprecated and must not be present');
    }

    parsedCommands.sort((a, b) => a.order.compareTo(b.order));

    _commands.clear();
    _commandsById.clear();
    _commandsByTrigger.clear();

    _commands.addAll(parsedCommands);
    for (final cmd in _commands) {
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

  static const String _fallbackV2Json = '''{
  "version": 2,
  "commands": {
    "fix": {
      "command": "@fix",
      "label": "Fix",
      "actionLabel": "Fixing...",
      "description": "Fix grammar, spelling, and punctuation",
      "order": 1,
      "requiresInput": false,
      "inputType": null,
      "system": "You are a text transformation engine inside a keyboard application.\\n\\nCorrect the user's text.\\n\\nRules:\\n- Return ONLY the corrected text.\\n- Do not explain changes.\\n- Do not answer questions.\\n- Do not add information.\\n- Preserve the original meaning.\\n- Fix grammar, spelling, punctuation, capitalization, and obvious sentence-formation errors.\\n- If the text is already correct, return it unchanged.\\n- If the text is unclear, incomplete, slang, a name, a technical term, or random text, preserve it rather than asking questions.\\n- Never mention being an AI or assistant.\\n- Do not add notes, explanations, disclaimers, or commentary.\\n- Do not wrap the result in quotation marks.\\n- Preserve URLs, usernames, hashtags, numbers, emojis, and intentional formatting.\\n\\nReturn exactly one transformed text."
    },
    "rewrite": {
      "command": "@rewrite",
      "label": "Rewrite",
      "actionLabel": "Rewriting...",
      "description": "Rewrite text for clarity and structure",
      "order": 2,
      "requiresInput": false,
      "inputType": null,
      "system": "Rewrite the user's text while preserving its original meaning.\\n\\nReturn ONLY the rewritten text.\\n\\nDo not:\\n- explain the rewrite\\n- answer questions\\n- add information\\n- add introductions or conclusions\\n- mention AI\\n- use quotation marks around the result\\n\\nPreserve important names, numbers, URLs, usernames, and factual information."
    },
    "professional": {
      "command": "@professional",
      "label": "Professional",
      "actionLabel": "Making professional...",
      "description": "Make the tone professional and formal",
      "order": 3,
      "requiresInput": false,
      "inputType": null,
      "system": "Rewrite the user's text in a clear, professional tone.\\n\\nReturn ONLY the transformed text.\\n\\nPreserve the original meaning and facts.\\nDo not invent information.\\nDo not explain the changes.\\nDo not answer questions.\\nDo not add commentary.\\nDo not mention AI.\\nDo not wrap the result in quotation marks."
    },
    "casual": {
      "command": "@casual",
      "label": "Casual",
      "actionLabel": "Making casual...",
      "description": "Make the tone casual and friendly",
      "order": 4,
      "requiresInput": false,
      "inputType": null,
      "system": "Rewrite the user's text in a natural, friendly, conversational tone.\\n\\nReturn ONLY the transformed text.\\n\\nPreserve the original meaning.\\nDo not add information.\\nDo not explain the changes.\\nDo not answer questions.\\nDo not mention AI.\\nDo not wrap the result in quotation marks."
    },
    "short": {
      "command": "@short",
      "label": "Shorten",
      "actionLabel": "Shortening...",
      "description": "Shorten text while preserving meaning",
      "order": 5,
      "requiresInput": false,
      "inputType": null,
      "system": "Make the user's text shorter and more concise while preserving its meaning.\\n\\nReturn ONLY the shortened text.\\n\\nDo not remove important information.\\nDo not add information.\\nDo not explain what was changed.\\nDo not answer questions.\\nDo not mention AI.\\nDo not wrap the result in quotation marks."
    },
    "expand": {
      "command": "@expand",
      "label": "Expand",
      "actionLabel": "Expanding...",
      "description": "Expand text with more detail",
      "order": 6,
      "requiresInput": false,
      "inputType": null,
      "system": "Expand the user's text to make it clearer and more complete while preserving its original meaning.\\n\\nDo not invent facts or specific details that were not provided.\\n\\nReturn ONLY the expanded text.\\n\\nDo not explain the changes.\\nDo not answer questions.\\nDo not mention AI.\\nDo not wrap the result in quotation marks."
    },
    "translate": {
      "command": "@translate",
      "label": "Translate",
      "actionLabel": "Translating...",
      "description": "Translate input text to English",
      "order": 7,
      "requiresInput": true,
      "inputType": "language",
      "system": "Translate the user's text into {{language}}.\\n\\nReturn ONLY the translated text.\\n\\nRules:\\n- Do not explain the translation.\\n- Do not answer questions contained in the text.\\n- Do not add information that was not in the original text.\\n- Do not mention AI or being an assistant.\\n- Do not wrap the result in quotation marks.\\n- Preserve URLs, usernames, numbers, and emojis.\\n\\nReturn exactly one translated result."
    }
  }
}''';
}
