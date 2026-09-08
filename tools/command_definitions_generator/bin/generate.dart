import 'dart:io';
import 'package:args/args.dart';
import 'package:command_definitions_generator/command_definitions_generator.dart';

void main(List<String> args) {
  final repoRoot = CommandDefinitionsGenerator.findRepoRoot();
  final defaultInput = CommandDefinitionsGenerator.defaultInputPath(repoRoot);

  final parser = ArgParser()
    ..addOption(
      'input',
      abbr: 'i',
      help: 'Path to canonical ai_prompts.json input file.',
      defaultsTo: defaultInput,
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Optional isolated output directory override (defaults to platform-local paths in repository).',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Display usage instructions.',
    );

  final ArgResults parsed;
  try {
    parsed = parser.parse(args);
  } catch (e) {
    stderr.writeln('Argument error: $e');
    stderr.writeln(parser.usage);
    exit(64); // EX_USAGE
  }

  if (parsed['help'] == true) {
    stdout.writeln('AtFix Command Definitions Generator');
    stdout.writeln('Reads canonical command JSON and generates strongly typed source files for Dart, Kotlin, Swift, and C++.\n');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final inputPath = parsed['input'] as String;
  final outputArg = parsed['output'] as String?;

  try {
    final generator = CommandDefinitionsGenerator();
    final bool isAssetTransformer = outputArg != null && outputArg.toLowerCase().endsWith('.json');

    final List<File> writtenFiles;
    if (isAssetTransformer) {
      // Flutter asset transformer mode:
      // 1. Generate platform-local files across Flutter, Android, macOS, Windows
      writtenFiles = generator.run(
        inputPath: inputPath,
        outputDir: null,
      );
      // 2. Write/copy the validated asset file to the requested transformer destination
      final destFile = File(outputArg);
      destFile.parent.createSync(recursive: true);
      File(inputPath).copySync(destFile.path);
    } else {
      writtenFiles = generator.run(
        inputPath: inputPath,
        outputDir: outputArg,
      );
    }

    stdout.writeln('Successfully generated ${writtenFiles.length} source file(s) from $inputPath:');
    for (final file in writtenFiles) {
      stdout.writeln('  - ${file.path}');
    }
    exit(0);
  } on ValidationException catch (e) {
    stderr.writeln('Validation Error: ${e.message}');
    if (e.commandKey != null) {
      stderr.writeln('  Command: ${e.commandKey}');
    }
    if (e.field != null) {
      stderr.writeln('  Field: ${e.field}');
    }
    exit(1);
  } on FileSystemException catch (e) {
    stderr.writeln('File System Error: ${e.message} (${e.path})');
    exit(1);
  } catch (e, st) {
    stderr.writeln('Fatal Error: $e');
    stderr.writeln(st);
    exit(1);
  }
}
