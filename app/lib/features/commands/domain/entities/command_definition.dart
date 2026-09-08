class CommandDefinition {
  final String id;
  final String command;
  final String label;
  final String actionLabel;
  final String description;
  final int order;
  final bool requiresInput;
  final String? inputType;
  final String system;

  const CommandDefinition({
    required this.id,
    required this.command,
    required this.label,
    required this.actionLabel,
    required this.description,
    required this.order,
    required this.requiresInput,
    this.inputType,
    required this.system,
  });

  factory CommandDefinition.fromJson(String id, Map<String, dynamic> json) {
    final cleanId = id.trim().toLowerCase();
    if (cleanId.isEmpty) {
      throw const FormatException('Command ID cannot be empty');
    }
    if (cleanId == 'pro' || cleanId == '@pro') {
      throw const FormatException('@pro is deprecated and not supported');
    }

    final rawCommand = (json['command'] as String?)?.trim() ?? '';
    if (rawCommand.isEmpty || !rawCommand.startsWith('@')) {
      throw FormatException('Invalid command syntax "$rawCommand" for id "$id"');
    }
    if (rawCommand.toLowerCase() == '@pro') {
      throw const FormatException('@pro is deprecated and not supported');
    }

    final label = (json['label'] as String?)?.trim() ?? '';
    if (label.isEmpty) {
      throw FormatException('Command label cannot be empty for id "$id"');
    }

    final actionLabel = (json['actionLabel'] as String?)?.trim() ?? '';
    if (actionLabel.isEmpty) {
      throw FormatException('Command actionLabel cannot be empty for id "$id"');
    }

    final rawDescription = (json['description'] as String?)?.trim() ?? '';
    final description = rawDescription.isNotEmpty ? rawDescription : actionLabel;

    final order = json['order'] as int? ?? 0;
    if (order <= 0) {
      throw FormatException('Command order must be a positive integer for id "$id"');
    }

    final requiresInput = json['requiresInput'] as bool? ?? false;
    final inputType = (json['inputType'] as String?)?.trim();
    if (requiresInput && (inputType == null || inputType.isEmpty)) {
      throw FormatException(
        'Command id "$id" requires input but inputType is null or empty',
      );
    }

    final system = (json['system'] as String?)?.trim() ?? '';
    if (system.isEmpty) {
      throw FormatException('System prompt cannot be empty for id "$id"');
    }

    return CommandDefinition(
      id: cleanId,
      command: rawCommand,
      label: label,
      actionLabel: actionLabel,
      description: description,
      order: order,
      requiresInput: requiresInput,
      inputType: inputType,
      system: (json['system'] as String?) ?? '',
    );
  }
}
