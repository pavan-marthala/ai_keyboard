import '../models/command_definition_model.dart';
import 'code_generator.dart';

/// Generates Kotlin source file for command definitions.
class KotlinGenerator implements CodeGenerator {
  @override
  String get targetLanguage => 'Kotlin';

  @override
  Map<String, String> generate(List<CommandDefinitionModel> commands) {
    final buffer = StringBuffer();
    buffer.write(CodeGenerator.fileHeader);
    buffer.write('\n');
    buffer.write('package com.pk.atfix.generated\n\n');
    buffer.write('data class GeneratedCommandDefinition(\n');
    buffer.write('    val id: String,\n');
    buffer.write('    val command: String,\n');
    buffer.write('    val label: String,\n');
    buffer.write('    val actionLabel: String,\n');
    buffer.write('    val description: String,\n');
    buffer.write('    val order: Int,\n');
    buffer.write('    val requiresInput: Boolean,\n');
    buffer.write('    val inputType: String?,\n');
    buffer.write('    val system: String\n');
    buffer.write(')\n\n');

    buffer.write('object GeneratedCommandDefinitions {\n');
    buffer.write('    val commands: List<GeneratedCommandDefinition> = listOf(\n');

    for (final cmd in commands) {
      buffer.write('        GeneratedCommandDefinition(\n');
      buffer.write('            id = ${StringEscaper.escapeKotlin(cmd.id)},\n');
      buffer.write('            command = ${StringEscaper.escapeKotlin(cmd.command)},\n');
      buffer.write('            label = ${StringEscaper.escapeKotlin(cmd.label)},\n');
      buffer.write('            actionLabel = ${StringEscaper.escapeKotlin(cmd.actionLabel)},\n');
      buffer.write('            description = ${StringEscaper.escapeKotlin(cmd.description)},\n');
      buffer.write('            order = ${cmd.order},\n');
      buffer.write('            requiresInput = ${cmd.requiresInput},\n');
      final inputTypeVal = cmd.inputType != null ? StringEscaper.escapeKotlin(cmd.inputType!) : 'null';
      buffer.write('            inputType = $inputTypeVal,\n');
      buffer.write('            system = ${StringEscaper.escapeKotlin(cmd.system)}\n');
      buffer.write('        ),\n');
    }

    buffer.write('    )\n');
    buffer.write('}\n');

    return {
      'kotlin/GeneratedCommandDefinitions.kt': buffer.toString(),
    };
  }
}
