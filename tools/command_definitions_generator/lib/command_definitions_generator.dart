import 'dart:io';
import 'package:path/path.dart' as p;
import 'src/generators/code_generator.dart';
import 'src/generators/cpp_generator.dart';
import 'src/generators/dart_generator.dart';
import 'src/generators/kotlin_generator.dart';
import 'src/generators/swift_generator.dart';
import 'src/validation/validator.dart';

export 'src/generators/code_generator.dart';
export 'src/generators/cpp_generator.dart';
export 'src/generators/dart_generator.dart';
export 'src/generators/kotlin_generator.dart';
export 'src/generators/swift_generator.dart';
export 'src/models/command_definition_model.dart';
export 'src/validation/validator.dart';

/// Main orchestrator for reading, validating, converting, and generating command definition source files.
class CommandDefinitionsGenerator {
  final List<CodeGenerator> _generators;

  CommandDefinitionsGenerator({List<CodeGenerator>? generators})
      : _generators = generators ??
            [
              DartGenerator(),
              KotlinGenerator(),
              SwiftGenerator(),
              CppGenerator(),
            ];

  /// Finds the repository root by locating `shared/prompts/ai_prompts.json` upwards.
  static Directory findRepoRoot([Directory? startDir]) {
    var current = startDir ?? Directory.current;
    while (true) {
      final marker = File(p.join(current.path, 'shared', 'prompts', 'ai_prompts.json'));
      if (marker.existsSync()) {
        return current;
      }
      final parent = current.parent;
      if (parent.path == current.path) {
        break;
      }
      current = parent;
    }

    // Fallback: check relative to executable / script path
    try {
      var scriptDir = File(Platform.script.toFilePath()).parent;
      while (true) {
        final marker = File(p.join(scriptDir.path, 'shared', 'prompts', 'ai_prompts.json'));
        if (marker.existsSync()) {
          return scriptDir;
        }
        final parent = scriptDir.parent;
        if (parent.path == scriptDir.path) {
          break;
        }
        scriptDir = parent;
      }
    } catch (_) {}

    return Directory.current;
  }

  /// Default input path pointing to canonical `shared/prompts/ai_prompts.json`.
  static String defaultInputPath([Directory? repoRoot]) {
    final root = repoRoot ?? findRepoRoot();
    return p.join(root.path, 'shared', 'prompts', 'ai_prompts.json');
  }

  /// Default output directory pointing to `generated/commands/`.
  static String defaultOutputDir([Directory? repoRoot]) {
    final root = repoRoot ?? findRepoRoot();
    return p.join(root.path, 'generated', 'commands');
  }

  /// Generates code files in memory without writing to disk.
  Map<String, String> generateInMemory(String jsonContent) {
    final commands = CommandDefinitionValidator.validateJson(jsonContent);
    final results = <String, String>{};
    for (final generator in _generators) {
      final generatedFiles = generator.generate(commands);
      results.addAll(generatedFiles);
    }
    return results;
  }

  /// Executes the full generation pipeline from disk to disk.
  List<File> run({
    required String inputPath,
    required String outputDir,
  }) {
    final inputFile = File(inputPath);
    if (!inputFile.existsSync()) {
      throw FileSystemException('Input file does not exist', inputPath);
    }

    final jsonContent = inputFile.readAsStringSync();
    final generatedMap = generateInMemory(jsonContent);

    final writtenFiles = <File>[];
    for (final entry in generatedMap.entries) {
      final relPath = entry.key;
      final content = entry.value;
      final targetFile = File(p.join(outputDir, relPath));
      targetFile.parent.createSync(recursive: true);
      targetFile.writeAsStringSync(content, flush: true);
      writtenFiles.add(targetFile);
    }

    return writtenFiles;
  }
}
