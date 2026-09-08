import '../models/command_definition_model.dart';
import 'code_generator.dart';

/// Generates C++ header and source files for command definitions.
class CppGenerator implements CodeGenerator {
  @override
  String get targetLanguage => 'C++';

  @override
  Map<String, String> generate(List<CommandDefinitionModel> commands) {
    return {
      'cpp/generated_command_definitions.h': _generateHeader(),
      'cpp/generated_command_definitions.cpp': _generateSource(commands),
    };
  }

  String _generateHeader() {
    final buffer = StringBuffer();
    buffer.write(CodeGenerator.fileHeader);
    buffer.write('\n');
    buffer.write('#ifndef ATFIX_GENERATED_COMMAND_DEFINITIONS_H_\n');
    buffer.write('#define ATFIX_GENERATED_COMMAND_DEFINITIONS_H_\n\n');
    buffer.write('#include <string>\n');
    buffer.write('#include <vector>\n\n');
    buffer.write('namespace atfix::generated {\n\n');
    buffer.write('struct GeneratedCommandDefinition {\n');
    buffer.write('  std::string id;\n');
    buffer.write('  std::string command;\n');
    buffer.write('  std::string label;\n');
    buffer.write('  std::string action_label;\n');
    buffer.write('  std::string description;\n');
    buffer.write('  int order{0};\n');
    buffer.write('  bool requires_input{false};\n');
    buffer.write('  std::string input_type;\n');
    buffer.write('  std::string system;\n');
    buffer.write('};\n\n');
    buffer.write('const std::vector<GeneratedCommandDefinition>& GetCommands();\n\n');
    buffer.write('}  // namespace atfix::generated\n\n');
    buffer.write('#endif  // ATFIX_GENERATED_COMMAND_DEFINITIONS_H_\n');
    return buffer.toString();
  }

  String _generateSource(List<CommandDefinitionModel> commands) {
    final buffer = StringBuffer();
    buffer.write(CodeGenerator.fileHeader);
    buffer.write('\n');
    buffer.write('#include "generated_command_definitions.h"\n\n');
    buffer.write('namespace atfix::generated {\n\n');
    buffer.write('const std::vector<GeneratedCommandDefinition>& GetCommands() {\n');
    buffer.write('  static const std::vector<GeneratedCommandDefinition> kCommands = {\n');

    for (final cmd in commands) {
      buffer.write('      GeneratedCommandDefinition{\n');
      buffer.write('          /*id=*/${StringEscaper.escapeCpp(cmd.id)},\n');
      buffer.write('          /*command=*/${StringEscaper.escapeCpp(cmd.command)},\n');
      buffer.write('          /*label=*/${StringEscaper.escapeCpp(cmd.label)},\n');
      buffer.write('          /*action_label=*/${StringEscaper.escapeCpp(cmd.actionLabel)},\n');
      buffer.write('          /*description=*/${StringEscaper.escapeCpp(cmd.description)},\n');
      buffer.write('          /*order=*/${cmd.order},\n');
      buffer.write('          /*requires_input=*/${cmd.requiresInput},\n');
      final inputTypeVal = cmd.inputType != null ? StringEscaper.escapeCpp(cmd.inputType!) : '""';
      buffer.write('          /*input_type=*/$inputTypeVal,\n');
      buffer.write('          /*system=*/${StringEscaper.escapeCpp(cmd.system)},\n');
      buffer.write('      },\n');
    }

    buffer.write('  };\n');
    buffer.write('  return kCommands;\n');
    buffer.write('}\n\n');
    buffer.write('}  // namespace atfix::generated\n');
    return buffer.toString();
  }
}
