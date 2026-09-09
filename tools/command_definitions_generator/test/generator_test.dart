import 'dart:io';
import 'package:command_definitions_generator/command_definitions_generator.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Generator Tests', () {
    late String canonicalJson;
    late CommandDefinitionsGenerator generator;

    setUpAll(() {
      final repoRoot = CommandDefinitionsGenerator.findRepoRoot();
      final canonicalFile = File(CommandDefinitionsGenerator.defaultInputPath(repoRoot));
      canonicalJson = canonicalFile.readAsStringSync();
      generator = CommandDefinitionsGenerator();
    });

    test('1. All four target languages are generated', () {
      final inMemoryFiles = generator.generateInMemory(canonicalJson);
      expect(inMemoryFiles.keys.any((k) => k.startsWith('dart/')), isTrue);
      expect(inMemoryFiles.keys.any((k) => k.startsWith('kotlin/')), isTrue);
      expect(inMemoryFiles.keys.any((k) => k.startsWith('swift/')), isTrue);
      expect(inMemoryFiles.keys.any((k) => k.startsWith('cpp/')), isTrue);
    });

    test('2. C++ produces both .h and .cpp', () {
      final inMemoryFiles = generator.generateInMemory(canonicalJson);
      expect(inMemoryFiles.containsKey('cpp/generated_command_definitions.h'), isTrue);
      expect(inMemoryFiles.containsKey('cpp/generated_command_definitions.cpp'), isTrue);
    });

    test('3. The current canonical seven commands are present', () {
      final inMemoryFiles = generator.generateInMemory(canonicalJson);
      final definitionFiles = [
        inMemoryFiles['dart/generated_command_definitions.dart']!,
        inMemoryFiles['kotlin/GeneratedCommandDefinitions.kt']!,
        inMemoryFiles['swift/GeneratedCommandDefinitions.swift']!,
        inMemoryFiles['cpp/generated_command_definitions.cpp']!,
      ];
      for (final content in definitionFiles) {
        expect(content, contains('@fix'));
        expect(content, contains('@rewrite'));
        expect(content, contains('@professional'));
        expect(content, contains('@casual'));
        expect(content, contains('@short'));
        expect(content, contains('@expand'));
        expect(content, contains('@translate'));
      }
    });

    test('4. Command ordering follows order', () {
      final inMemoryFiles = generator.generateInMemory(canonicalJson);
      final dartContent = inMemoryFiles['dart/generated_command_definitions.dart']!;

      final fixIdx = dartContent.indexOf('@fix');
      final rewriteIdx = dartContent.indexOf('@rewrite');
      final proIdx = dartContent.indexOf('@professional');
      final casualIdx = dartContent.indexOf('@casual');
      final shortIdx = dartContent.indexOf('@short');
      final expandIdx = dartContent.indexOf('@expand');
      final transIdx = dartContent.indexOf('@translate');

      expect(fixIdx, lessThan(rewriteIdx));
      expect(rewriteIdx, lessThan(proIdx));
      expect(proIdx, lessThan(casualIdx));
      expect(casualIdx, lessThan(shortIdx));
      expect(shortIdx, lessThan(expandIdx));
      expect(expandIdx, lessThan(transIdx));
    });

    test('5. All command metadata is preserved', () {
      final inMemoryFiles = generator.generateInMemory(canonicalJson);
      final dartContent = inMemoryFiles['dart/generated_command_definitions.dart']!;

      expect(dartContent, contains('Fix grammar, spelling, and punctuation'));
      expect(dartContent, contains('Fixing...'));
      expect(dartContent, contains('Professional'));
      expect(dartContent, contains('Making professional...'));
      expect(dartContent, contains('Make the tone professional and formal'));
    });

    test('6. Complete system prompts are preserved', () {
      final inMemoryFiles = generator.generateInMemory(canonicalJson);
      final commands = CommandDefinitionValidator.validateJson(canonicalJson);
      final dartContent = inMemoryFiles['dart/generated_command_definitions.dart']!;

      for (final cmd in commands) {
        expect(dartContent, contains(StringEscaper.escapeDart(cmd.system)));
      }
    });

    test('7. Multiline prompts are correctly escaped', () {
      final testJson = '''
      {
        "version": 2,
        "commands": {
          "multiline": {
            "command": "@multiline",
            "label": "Multi",
            "actionLabel": "Running...",
            "description": "Multiline test",
            "order": 1,
            "requiresInput": false,
            "inputType": null,
            "system": "Line 1\\n\\nLine 2\\nLine 3"
          }
        }
      }
      ''';
      final inMemoryFiles = generator.generateInMemory(testJson);
      final dartContent = inMemoryFiles['dart/generated_command_definitions.dart']!;
      final kotlinContent = inMemoryFiles['kotlin/GeneratedCommandDefinitions.kt']!;
      final swiftContent = inMemoryFiles['swift/GeneratedCommandDefinitions.swift']!;
      final cppContent = inMemoryFiles['cpp/generated_command_definitions.cpp']!;

      expect(dartContent, contains(r'Line 1\n\nLine 2\nLine 3'));
      expect(kotlinContent, contains(r'Line 1\n\nLine 2\nLine 3'));
      expect(swiftContent, contains(r'Line 1\n\nLine 2\nLine 3'));
      expect(cppContent, contains(r'Line 1\n\nLine 2\nLine 3'));
    });

    test('8. Quotes and backslashes are correctly escaped', () {
      const testJson = r'''
      {
        "version": 2,
        "commands": {
          "quotes": {
            "command": "@quotes",
            "label": "Quotes & 'single' \"double\"",
            "actionLabel": "Testing...",
            "description": "Path \\folder\\file",
            "order": 1,
            "requiresInput": false,
            "inputType": null,
            "system": "Say 'hello' and \"world\" with backslash \\ here."
          }
        }
      }
      ''';
      final inMemoryFiles = generator.generateInMemory(testJson);
      final dartContent = inMemoryFiles['dart/generated_command_definitions.dart']!;
      final kotlinContent = inMemoryFiles['kotlin/GeneratedCommandDefinitions.kt']!;
      final swiftContent = inMemoryFiles['swift/GeneratedCommandDefinitions.swift']!;
      final cppContent = inMemoryFiles['cpp/generated_command_definitions.cpp']!;

      // Dart uses single-quoted strings
      expect(dartContent, contains(r"\'single\'"));
      expect(dartContent, contains(r'Path \\folder\\file'));
      expect(dartContent, contains(r'backslash \\ here.'));

      // Kotlin / Swift / C++ use double-quoted strings
      expect(kotlinContent, contains(r'\"double\"'));
      expect(kotlinContent, contains(r'Path \\folder\\file'));
      expect(swiftContent, contains(r'\"double\"'));
      expect(swiftContent, contains(r'Path \\folder\\file'));
      expect(cppContent, contains(r'\"double\"'));
      expect(cppContent, contains(r'Path \\folder\\file'));
    });

    test('9. Unicode survives generation', () {
      final testJson = '''
      {
        "version": 2,
        "commands": {
          "unicode": {
            "command": "@unicode",
            "label": "Unicode 🚀 日本語",
            "actionLabel": "Running...",
            "description": "Emoji and chars 🌟",
            "order": 1,
            "requiresInput": false,
            "inputType": null,
            "system": "Translate to Spanish: ¡Hola! 🌍"
          }
        }
      }
      ''';
      final inMemoryFiles = generator.generateInMemory(testJson);
      final definitionFiles = [
        inMemoryFiles['dart/generated_command_definitions.dart']!,
        inMemoryFiles['kotlin/GeneratedCommandDefinitions.kt']!,
        inMemoryFiles['swift/GeneratedCommandDefinitions.swift']!,
        inMemoryFiles['cpp/generated_command_definitions.cpp']!,
      ];
      for (final content in definitionFiles) {
        expect(content, contains('🚀'));
        expect(content, contains('日本語'));
        expect(content, contains('🌟'));
        expect(content, contains('¡Hola! 🌍'));
      }
    });

    test('10. @translate and its inputType are generated correctly', () {
      final inMemoryFiles = generator.generateInMemory(canonicalJson);

      final dartContent = inMemoryFiles['dart/generated_command_definitions.dart']!;
      expect(dartContent, contains("inputType: 'language'"));
      expect(dartContent, contains('requiresInput: true'));

      final kotlinContent = inMemoryFiles['kotlin/GeneratedCommandDefinitions.kt']!;
      expect(kotlinContent, contains('inputType = "language"'));
      expect(kotlinContent, contains('requiresInput = true'));

      final swiftContent = inMemoryFiles['swift/GeneratedCommandDefinitions.swift']!;
      expect(swiftContent, contains('inputType: "language"'));
      expect(swiftContent, contains('requiresInput: true'));

      final cppContent = inMemoryFiles['cpp/generated_command_definitions.cpp']!;
      expect(cppContent, contains('/*input_type=*/"language"'));
      expect(cppContent, contains('/*requires_input=*/true'));
    });

    test('11. Generated output contains the generated-file marker', () {
      final inMemoryFiles = generator.generateInMemory(canonicalJson);
      for (final entry in inMemoryFiles.entries) {
        expect(
          entry.value.startsWith('// GENERATED FILE - DO NOT EDIT.'),
          isTrue,
          reason: '${entry.key} must start with generated-file marker',
        );
      }
    });

    test('12. Running generation twice with identical input produces byte-identical output', () {
      final tempDir1 = Directory.systemTemp.createTempSync('gen_test_1');
      final tempDir2 = Directory.systemTemp.createTempSync('gen_test_2');

      try {
        final repoRoot = CommandDefinitionsGenerator.findRepoRoot();
        final canonicalPath = CommandDefinitionsGenerator.defaultInputPath(repoRoot);

        final run1Files = generator.run(
          inputPath: canonicalPath,
          outputDir: tempDir1.path,
        );

        final run2Files = generator.run(
          inputPath: canonicalPath,
          outputDir: tempDir2.path,
        );

        expect(run1Files.length, equals(run2Files.length));
        expect(run1Files.length, equals(5));

        for (var i = 0; i < run1Files.length; i++) {
          final file1 = run1Files[i];
          final file2 = run2Files[i];
          final bytes1 = file1.readAsBytesSync();
          final bytes2 = file2.readAsBytesSync();
          expect(bytes1, equals(bytes2), reason: '${file1.path} must match ${file2.path} byte-for-byte');
        }
      } finally {
        tempDir1.deleteSync(recursive: true);
        tempDir2.deleteSync(recursive: true);
      }
    });

    test('13. Committed platform generated files match generation from canonical ai_prompts.json', () {
      final repoRoot = CommandDefinitionsGenerator.findRepoRoot();
      final canonicalPath = CommandDefinitionsGenerator.defaultInputPath(repoRoot);
      final tempDir = Directory.systemTemp.createTempSync('gen_consistency_check_');

      try {
        final generatedFiles = generator.run(
          inputPath: canonicalPath,
          outputDir: tempDir.path,
        );

        expect(generatedFiles.length, equals(5));

        for (final generatedFile in generatedFiles) {
          final relKey = p.relative(generatedFile.path, from: tempDir.path);
          final committedRelPath = CommandDefinitionsGenerator.platformLocalPaths[relKey];
          expect(committedRelPath, isNotNull, reason: 'Unknown target generated file key: $relKey');

          final committedFile = File(p.join(repoRoot.path, committedRelPath!));
          expect(
            committedFile.existsSync(),
            isTrue,
            reason: 'Committed generated file missing: ${committedFile.path}',
          );

          final generatedContent = generatedFile.readAsStringSync();
          final committedContent = committedFile.readAsStringSync();

          expect(
            committedContent,
            equals(generatedContent),
            reason: 'Committed file at ${committedFile.path} is out of sync with canonical $canonicalPath.\n'
                'Please run: dart run tools/command_definitions_generator/bin/generate.dart --input=shared/prompts/ai_prompts.json',
          );
        }
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
