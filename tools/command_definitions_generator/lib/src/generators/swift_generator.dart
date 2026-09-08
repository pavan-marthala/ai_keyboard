import '../models/command_definition_model.dart';
import 'code_generator.dart';

/// Generates Swift source file for command definitions.
class SwiftGenerator implements CodeGenerator {
  @override
  String get targetLanguage => 'Swift';

  @override
  Map<String, String> generate(List<CommandDefinitionModel> commands) {
    final buffer = StringBuffer();
    buffer.write(CodeGenerator.fileHeader);
    buffer.write('\n');
    buffer.write('import Foundation\n\n');
    buffer.write('public struct GeneratedCommandDefinition: Equatable {\n');
    buffer.write('    public let id: String\n');
    buffer.write('    public let command: String\n');
    buffer.write('    public let label: String\n');
    buffer.write('    public let actionLabel: String\n');
    buffer.write('    public let description: String\n');
    buffer.write('    public let order: Int\n');
    buffer.write('    public let requiresInput: Bool\n');
    buffer.write('    public let inputType: String?\n');
    buffer.write('    public let system: String\n\n');
    buffer.write('    public init(\n');
    buffer.write('        id: String,\n');
    buffer.write('        command: String,\n');
    buffer.write('        label: String,\n');
    buffer.write('        actionLabel: String,\n');
    buffer.write('        description: String,\n');
    buffer.write('        order: Int,\n');
    buffer.write('        requiresInput: Bool,\n');
    buffer.write('        inputType: String?,\n');
    buffer.write('        system: String\n');
    buffer.write('    ) {\n');
    buffer.write('        self.id = id\n');
    buffer.write('        self.command = command\n');
    buffer.write('        self.label = label\n');
    buffer.write('        self.actionLabel = actionLabel\n');
    buffer.write('        self.description = description\n');
    buffer.write('        self.order = order\n');
    buffer.write('        self.requiresInput = requiresInput\n');
    buffer.write('        self.inputType = inputType\n');
    buffer.write('        self.system = system\n');
    buffer.write('    }\n');
    buffer.write('}\n\n');

    buffer.write('public enum GeneratedCommandDefinitions {\n');
    buffer.write('    public static let commands: [GeneratedCommandDefinition] = [\n');

    for (final cmd in commands) {
      buffer.write('        GeneratedCommandDefinition(\n');
      buffer.write('            id: ${StringEscaper.escapeSwift(cmd.id)},\n');
      buffer.write('            command: ${StringEscaper.escapeSwift(cmd.command)},\n');
      buffer.write('            label: ${StringEscaper.escapeSwift(cmd.label)},\n');
      buffer.write('            actionLabel: ${StringEscaper.escapeSwift(cmd.actionLabel)},\n');
      buffer.write('            description: ${StringEscaper.escapeSwift(cmd.description)},\n');
      buffer.write('            order: ${cmd.order},\n');
      buffer.write('            requiresInput: ${cmd.requiresInput},\n');
      final inputTypeVal = cmd.inputType != null ? StringEscaper.escapeSwift(cmd.inputType!) : 'nil';
      buffer.write('            inputType: $inputTypeVal,\n');
      buffer.write('            system: ${StringEscaper.escapeSwift(cmd.system)}\n');
      buffer.write('        ),\n');
    }

    buffer.write('    ]\n');
    buffer.write('}\n');

    return {
      'swift/GeneratedCommandDefinitions.swift': buffer.toString(),
    };
  }
}
