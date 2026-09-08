/// Strongly typed internal model representing a command definition.
class CommandDefinitionModel {
  final String id;
  final String command;
  final String label;
  final String actionLabel;
  final String description;
  final int order;
  final bool requiresInput;
  final String? inputType;
  final String system;

  const CommandDefinitionModel({
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommandDefinitionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          command == other.command &&
          label == other.label &&
          actionLabel == other.actionLabel &&
          description == other.description &&
          order == other.order &&
          requiresInput == other.requiresInput &&
          inputType == other.inputType &&
          system == other.system;

  @override
  int get hashCode => Object.hash(
        id,
        command,
        label,
        actionLabel,
        description,
        order,
        requiresInput,
        inputType,
        system,
      );

  @override
  String toString() =>
      'CommandDefinitionModel(id: $id, command: $command, order: $order)';
}
