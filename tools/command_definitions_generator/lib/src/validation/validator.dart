import 'dart:convert';
import '../models/command_definition_model.dart';

/// Exception thrown when command definition JSON fails schema or semantic validation.
class ValidationException implements Exception {
  final String message;
  final String? commandKey;
  final String? field;

  ValidationException(this.message, {this.commandKey, this.field});

  @override
  String toString() => message;
}

/// Strict validator for command definitions.
class CommandDefinitionValidator {
  static final RegExp _identifierRegex = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');

  /// Parses and strictly validates a JSON string.
  static List<CommandDefinitionModel> validateJson(String jsonString) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (e) {
      throw ValidationException('Malformed JSON: $e');
    }
    return validate(decoded);
  }

  /// Strictly validates a decoded JSON object.
  static List<CommandDefinitionModel> validate(dynamic json) {
    if (json is! Map) {
      throw ValidationException('Root must be a JSON object');
    }

    // 1. Validate version
    if (!json.containsKey('version')) {
      throw ValidationException('Missing required field "version"', field: 'version');
    }
    final dynamic version = json['version'];
    if (version is! int) {
      throw ValidationException(
        'Field "version" must be an integer, but got ${version.runtimeType}',
        field: 'version',
      );
    }
    if (version != 2) {
      throw ValidationException(
        'Unsupported version: $version. Expected version 2',
        field: 'version',
      );
    }

    // 2. Validate commands map
    if (!json.containsKey('commands')) {
      throw ValidationException('Missing required field "commands"', field: 'commands');
    }
    final dynamic rawCommands = json['commands'];
    if (rawCommands is! Map) {
      throw ValidationException('Field "commands" must be a JSON object', field: 'commands');
    }
    if (rawCommands.isEmpty) {
      throw ValidationException('Field "commands" must be a non-empty JSON object', field: 'commands');
    }

    final models = <CommandDefinitionModel>[];
    final seenIds = <String>{};
    final seenTriggers = <String>{};
    final seenOrders = <int>{};

    for (final entry in rawCommands.entries) {
      final dynamic rawKey = entry.key;
      if (rawKey is! String || rawKey.isEmpty) {
        throw ValidationException('Command key must be a non-empty string');
      }

      final key = rawKey;

      // Validate key identifier format
      if (!_identifierRegex.hasMatch(key)) {
        throw ValidationException(
          'Invalid command key "$key": must be a valid generator identifier',
          commandKey: key,
        );
      }

      // Prohibit deprecated 'pro' / '@pro'
      if (key.toLowerCase() == 'pro' || key.toLowerCase() == '@pro') {
        throw ValidationException(
          'Command "$key" is deprecated and rejected',
          commandKey: key,
        );
      }

      final dynamic cmdVal = entry.value;
      if (cmdVal is! Map) {
        throw ValidationException(
          'Command "$key" definition must be a JSON object',
          commandKey: key,
        );
      }

      final cmdMap = cmdVal;

      // Duplicate key check
      if (!seenIds.add(key.toLowerCase())) {
        throw ValidationException(
          'Duplicate command ID: "$key"',
          commandKey: key,
        );
      }

      // Validate command trigger
      if (!cmdMap.containsKey('command')) {
        throw ValidationException(
          'Command "$key" is missing required field "command"',
          commandKey: key,
          field: 'command',
        );
      }
      final dynamic rawTrigger = cmdMap['command'];
      if (rawTrigger is! String) {
        throw ValidationException(
          'Command "$key": "command" must be a string, but got ${rawTrigger.runtimeType}',
          commandKey: key,
          field: 'command',
        );
      }
      if (rawTrigger.isEmpty || !rawTrigger.startsWith('@')) {
        throw ValidationException(
          'Command "$key": "command" must be a non-empty string starting with "@"',
          commandKey: key,
          field: 'command',
        );
      }
      if (rawTrigger.toLowerCase() == '@pro') {
        throw ValidationException(
          'Command "$key": "@pro" is deprecated and rejected',
          commandKey: key,
          field: 'command',
        );
      }
      if (!seenTriggers.add(rawTrigger.toLowerCase())) {
        throw ValidationException(
          'Duplicate command trigger "$rawTrigger" in command "$key"',
          commandKey: key,
          field: 'command',
        );
      }

      // Validate label
      if (!cmdMap.containsKey('label')) {
        throw ValidationException(
          'Command "$key" is missing required field "label"',
          commandKey: key,
          field: 'label',
        );
      }
      final dynamic rawLabel = cmdMap['label'];
      if (rawLabel is! String || rawLabel.isEmpty) {
        throw ValidationException(
          'Command "$key": "label" must be a non-empty string',
          commandKey: key,
          field: 'label',
        );
      }

      // Validate actionLabel
      if (!cmdMap.containsKey('actionLabel')) {
        throw ValidationException(
          'Command "$key" is missing required field "actionLabel"',
          commandKey: key,
          field: 'actionLabel',
        );
      }
      final dynamic rawActionLabel = cmdMap['actionLabel'];
      if (rawActionLabel is! String || rawActionLabel.isEmpty) {
        throw ValidationException(
          'Command "$key": "actionLabel" must be a non-empty string',
          commandKey: key,
          field: 'actionLabel',
        );
      }

      // Validate description
      if (!cmdMap.containsKey('description')) {
        throw ValidationException(
          'Command "$key" is missing required field "description"',
          commandKey: key,
          field: 'description',
        );
      }
      final dynamic rawDescription = cmdMap['description'];
      if (rawDescription is! String || rawDescription.isEmpty) {
        throw ValidationException(
          'Command "$key": "description" must be a non-empty string',
          commandKey: key,
          field: 'description',
        );
      }

      // Validate order
      if (!cmdMap.containsKey('order')) {
        throw ValidationException(
          'Command "$key" is missing required field "order"',
          commandKey: key,
          field: 'order',
        );
      }
      final dynamic rawOrder = cmdMap['order'];
      if (rawOrder is! int) {
        throw ValidationException(
          'Command "$key": "order" must be an integer, but got ${rawOrder.runtimeType}',
          commandKey: key,
          field: 'order',
        );
      }
      if (rawOrder <= 0) {
        throw ValidationException(
          'Command "$key": "order" must be greater than zero',
          commandKey: key,
          field: 'order',
        );
      }
      if (!seenOrders.add(rawOrder)) {
        throw ValidationException(
          'Duplicate order $rawOrder in command "$key"',
          commandKey: key,
          field: 'order',
        );
      }

      // Validate requiresInput
      if (!cmdMap.containsKey('requiresInput')) {
        throw ValidationException(
          'Command "$key" is missing required field "requiresInput"',
          commandKey: key,
          field: 'requiresInput',
        );
      }
      final dynamic rawRequiresInput = cmdMap['requiresInput'];
      if (rawRequiresInput is! bool) {
        throw ValidationException(
          'Command "$key": "requiresInput" must be a boolean, but got ${rawRequiresInput.runtimeType}',
          commandKey: key,
          field: 'requiresInput',
        );
      }

      // Validate inputType
      final dynamic rawInputType = cmdMap['inputType'];
      final String? inputType;
      if (rawRequiresInput == true) {
        if (rawInputType is! String || rawInputType.isEmpty) {
          throw ValidationException(
            'Invalid command "$key": inputType must be a non-empty string when requiresInput is true.',
            commandKey: key,
            field: 'inputType',
          );
        }
        inputType = rawInputType;
      } else {
        if (rawInputType != null) {
          throw ValidationException(
            'Invalid command "$key": inputType must be null or absent when requiresInput is false.',
            commandKey: key,
            field: 'inputType',
          );
        }
        inputType = null;
      }

      // Validate system prompt
      if (!cmdMap.containsKey('system')) {
        throw ValidationException(
          'Command "$key" is missing required field "system"',
          commandKey: key,
          field: 'system',
        );
      }
      final dynamic rawSystem = cmdMap['system'];
      if (rawSystem is! String || rawSystem.isEmpty) {
        throw ValidationException(
          'Command "$key": "system" must be a non-empty string',
          commandKey: key,
          field: 'system',
        );
      }

      models.add(CommandDefinitionModel(
        id: key,
        command: rawTrigger,
        label: rawLabel,
        actionLabel: rawActionLabel,
        description: rawDescription,
        order: rawOrder,
        requiresInput: rawRequiresInput,
        inputType: inputType,
        system: rawSystem, // Preserved exactly without trimming/modification
      ));
    }

    // Sort ascending by order
    models.sort((a, b) => a.order.compareTo(b.order));

    return List.unmodifiable(models);
  }
}
