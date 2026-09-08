import '../models/command_definition_model.dart';
import 'code_generator.dart';

/// Generates Dart source file for command definitions.
class DartGenerator implements CodeGenerator {
  @override
  String get targetLanguage => 'Dart';

  @override
  Map<String, String> generate(List<CommandDefinitionModel> commands) {
    final buffer = StringBuffer();
    buffer.write(CodeGenerator.fileHeader);
    buffer.write('\n');
    buffer.write('class GeneratedCommandDefinition {\n');
    buffer.write('  final String id;\n');
    buffer.write('  final String command;\n');
    buffer.write('  final String label;\n');
    buffer.write('  final String actionLabel;\n');
    buffer.write('  final String description;\n');
    buffer.write('  final int order;\n');
    buffer.write('  final bool requiresInput;\n');
    buffer.write('  final String? inputType;\n');
    buffer.write('  final String system;\n');
    buffer.write('\n');
    buffer.write('  const GeneratedCommandDefinition({\n');
    buffer.write('    required this.id,\n');
    buffer.write('    required this.command,\n');
    buffer.write('    required this.label,\n');
    buffer.write('    required this.actionLabel,\n');
    buffer.write('    required this.description,\n');
    buffer.write('    required this.order,\n');
    buffer.write('    required this.requiresInput,\n');
    buffer.write('    this.inputType,\n');
    buffer.write('    required this.system,\n');
    buffer.write('  });\n');
    buffer.write('}\n\n');

    buffer.write('class GeneratedCommandDefinitions {\n');
    buffer.write('  static const List<GeneratedCommandDefinition> commands = [\n');

    for (final cmd in commands) {
      buffer.write('    GeneratedCommandDefinition(\n');
      buffer.write('      id: ${StringEscaper.escapeDart(cmd.id)},\n');
      buffer.write('      command: ${StringEscaper.escapeDart(cmd.command)},\n');
      buffer.write('      label: ${StringEscaper.escapeDart(cmd.label)},\n');
      buffer.write('      actionLabel: ${StringEscaper.escapeDart(cmd.actionLabel)},\n');
      buffer.write('      description: ${StringEscaper.escapeDart(cmd.description)},\n');
      buffer.write('      order: ${cmd.order},\n');
      buffer.write('      requiresInput: ${cmd.requiresInput},\n');
      final inputTypeVal = cmd.inputType != null ? StringEscaper.escapeDart(cmd.inputType!) : 'null';
      buffer.write('      inputType: $inputTypeVal,\n');
      buffer.write('      system: ${StringEscaper.escapeDart(cmd.system)},\n');
      buffer.write('    ),\n');
    }

    buffer.write('  ];\n');
    buffer.write('}\n');

    return {
      'dart/generated_command_definitions.dart': buffer.toString(),
    };
  }
}
