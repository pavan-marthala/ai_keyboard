import 'dart:io';
import 'package:command_definitions_generator/command_definitions_generator.dart';
import 'package:test/test.dart';

void main() {
  group('CommandDefinitionValidator Tests', () {
    late String canonicalJson;

    setUpAll(() {
      final repoRoot = CommandDefinitionsGenerator.findRepoRoot();
      final canonicalFile = File(CommandDefinitionsGenerator.defaultInputPath(repoRoot));
      expect(canonicalFile.existsSync(), isTrue, reason: 'Canonical ai_prompts.json must exist');
      canonicalJson = canonicalFile.readAsStringSync();
    });

    Map<String, dynamic> createValidCommandMap() {
      return {
        'version': 2,
        'commands': {
          'fix': {
            'command': '@fix',
            'label': 'Fix',
            'actionLabel': 'Fixing...',
            'description': 'Fix grammar and spelling',
            'order': 1,
            'requiresInput': false,
            'inputType': null,
            'system': 'System prompt for fix',
          },
          'professional': {
            'command': '@professional',
            'label': 'Professional',
            'actionLabel': 'Making professional...',
            'description': 'Make tone professional',
            'order': 2,
            'requiresInput': false,
            'inputType': null,
            'system': 'System prompt for professional',
          },
        },
      };
    }

    test('1. Current shared/prompts/ai_prompts.json validates successfully', () {
      final models = CommandDefinitionValidator.validateJson(canonicalJson);
      expect(models.length, equals(7));

      final triggers = models.map((m) => m.command).toList();
      expect(
        triggers,
        equals([
          '@fix',
          '@rewrite',
          '@professional',
          '@casual',
          '@short',
          '@expand',
          '@translate',
        ]),
      );
    });

    test('2. Malformed JSON fails', () {
      expect(
        () => CommandDefinitionValidator.validateJson('{not valid json'),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('Malformed JSON'),
        )),
      );
    });

    test('3. Missing version fails', () {
      final map = createValidCommandMap()..remove('version');
      expect(
        () => CommandDefinitionValidator.validate(map),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('Missing required field "version"'),
        )),
      );
    });

    test('4. Incorrect version fails', () {
      final map = createValidCommandMap()..['version'] = 1;
      expect(
        () => CommandDefinitionValidator.validate(map),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('Unsupported version: 1. Expected version 2'),
        )),
      );
    });

    test('5. Missing commands fails', () {
      final map = createValidCommandMap()..remove('commands');
      expect(
        () => CommandDefinitionValidator.validate(map),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('Missing required field "commands"'),
        )),
      );
    });

    test('6. Empty commands fails', () {
      final map = createValidCommandMap()..['commands'] = {};
      expect(
        () => CommandDefinitionValidator.validate(map),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('non-empty JSON object'),
        )),
      );
    });

    test('7. Missing description fails', () {
      final map = createValidCommandMap();
      (map['commands'] as Map<String, dynamic>)['fix'].remove('description');
      expect(
        () => CommandDefinitionValidator.validate(map),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('missing required field "description"'),
        )),
      );
    });

    test('8. Missing actionLabel fails', () {
      final map = createValidCommandMap();
      (map['commands'] as Map<String, dynamic>)['fix'].remove('actionLabel');
      expect(
        () => CommandDefinitionValidator.validate(map),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('missing required field "actionLabel"'),
        )),
      );
    });

    test('9. Missing system fails', () {
      final map = createValidCommandMap();
      (map['commands'] as Map<String, dynamic>)['fix'].remove('system');
      expect(
        () => CommandDefinitionValidator.validate(map),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('missing required field "system"'),
        )),
      );
    });

    test('10. Incorrect field types fail', () {
      final map = createValidCommandMap();
      (map['commands'] as Map<String, dynamic>)['fix']['label'] = 12345;
      expect(
        () => CommandDefinitionValidator.validate(map),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('non-empty string'),
        )),
      );
    });

    test('11. order: "1" fails', () {
      final map = createValidCommandMap();
      (map['commands'] as Map<String, dynamic>)['fix']['order'] = '1';
      expect(
        () => CommandDefinitionValidator.validate(map),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('must be an integer, but got String'),
        )),
      );
    });

    test('12. requiresInput: 1 fails', () {
      final map = createValidCommandMap();
      (map['commands'] as Map<String, dynamic>)['fix']['requiresInput'] = 1;
      expect(
        () => CommandDefinitionValidator.validate(map),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('must be a boolean, but got int'),
        )),
      );
    });

    test('13. Command without @ fails', () {
      final map = createValidCommandMap();
      (map['commands'] as Map<String, dynamic>)['fix']['command'] = 'fix';
      expect(
        () => CommandDefinitionValidator.validate(map),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('starting with "@"'),
        )),
      );
    });

    test('14. @pro fails', () {
      final map = createValidCommandMap();
      (map['commands'] as Map<String, dynamic>)['professional']['command'] = '@pro';
      expect(
        () => CommandDefinitionValidator.validate(map),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('@pro" is deprecated and rejected'),
        )),
      );
    });

    test('15. pro fails', () {
      final map = createValidCommandMap();
      (map['commands'] as Map<String, dynamic>)['pro'] = {
        'command': '@professional',
        'label': 'Professional',
        'actionLabel': 'Making professional...',
        'description': 'Description',
        'order': 3,
        'requiresInput': false,
        'inputType': null,
        'system': 'Prompt',
      };
      expect(
        () => CommandDefinitionValidator.validate(map),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('deprecated and rejected'),
        )),
      );
    });

    test('16. @professional succeeds', () {
      final map = createValidCommandMap();
      final models = CommandDefinitionValidator.validate(map);
      final pro = models.firstWhere((m) => m.command == '@professional');
      expect(pro.id, equals('professional'));
      expect(pro.label, equals('Professional'));
    });

    test('17. Duplicate command triggers fail', () {
      final map = createValidCommandMap();
      (map['commands'] as Map<String, dynamic>)['professional']['command'] = '@fix';
      expect(
        () => CommandDefinitionValidator.validate(map),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('Duplicate command trigger "@fix"'),
        )),
      );
    });

    test('18. Duplicate order values fail', () {
      final map = createValidCommandMap();
      (map['commands'] as Map<String, dynamic>)['professional']['order'] = 1;
      expect(
        () => CommandDefinitionValidator.validate(map),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('Duplicate order 1 in command "professional"'),
        )),
      );
    });

    test('19. requiresInput: true with null/missing inputType fails', () {
      final map = createValidCommandMap();
      (map['commands'] as Map<String, dynamic>)['fix']['requiresInput'] = true;
      (map['commands'] as Map<String, dynamic>)['fix']['inputType'] = null;
      expect(
        () => CommandDefinitionValidator.validate(map),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('inputType must be a non-empty string when requiresInput is true'),
        )),
      );
    });

    test('20. requiresInput: false with non-null inputType fails', () {
      final map = createValidCommandMap();
      (map['commands'] as Map<String, dynamic>)['fix']['requiresInput'] = false;
      (map['commands'] as Map<String, dynamic>)['fix']['inputType'] = 'language';
      expect(
        () => CommandDefinitionValidator.validate(map),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('inputType must be null or absent when requiresInput is false'),
        )),
      );
    });

    test('21. Empty system fails', () {
      final map = createValidCommandMap();
      (map['commands'] as Map<String, dynamic>)['fix']['system'] = '';
      expect(
        () => CommandDefinitionValidator.validate(map),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('must be a non-empty string'),
        )),
      );
    });
  });
}
