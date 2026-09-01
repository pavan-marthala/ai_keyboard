import 'package:ai_keyboard/features/commands/domain/parser/command_parser.dart';
import 'package:ai_keyboard/features/commands/domain/repositories/command_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CommandParser tests', () {
    final registry = CommandRegistryImpl();
    final testCommands = registry.commands;

    test('should parse @fix command at the end of input text', () {
      const input = 'I am not able to attend the meeting tommorow @fix';
      final result = CommandParser.parse(
        input: input,
        availableCommands: testCommands,
      );

      expect(result, isNotNull);
      expect(
        result!.cleanText,
        equals('I am not able to attend the meeting tommorow'),
      );
      expect(result.command.trigger, equals('@fix'));
    });

    test('should parse command case-insensitively (@FIX)', () {
      const input = 'This is a test message @FIX';
      final result = CommandParser.parse(
        input: input,
        availableCommands: testCommands,
      );

      expect(result, isNotNull);
      expect(result!.cleanText, equals('This is a test message'));
      expect(result.command.trigger, equals('@fix'));
    });

    test('should parse @translate:es with explicit language argument', () {
      const input = 'I am going home @translate:es';
      final result = CommandParser.parse(
        input: input,
        availableCommands: testCommands,
      );

      expect(result, isNotNull);
      expect(result!.cleanText, equals('I am going home'));
      expect(result.command.trigger, equals('@translate'));
      expect(result.arguments['language'], equals('es'));
      expect(result.prompt, contains('Spanish'));
    });

    test(
      'should reject @translate with unsupported or missing language tag',
      () {
        final invalidResult = CommandParser.parse(
          input: 'Hello @translate:xyz',
          availableCommands: testCommands,
        );
        expect(invalidResult, isNull);

        final noLangResult = CommandParser.parse(
          input: 'Hello @translate',
          availableCommands: testCommands,
        );
        expect(noLangResult, isNull);
      },
    );

    test('should ignore commands in the middle of a sentence', () {
      const input = 'I am @fix going office tomorrow';
      final result = CommandParser.parse(
        input: input,
        availableCommands: testCommands,
      );

      expect(result, isNull);
    });

    test('should ignore email addresses and usernames', () {
      expect(
        CommandParser.parse(
          input: 'Send email to user@example.com',
          availableCommands: testCommands,
        ),
        isNull,
      );

      expect(
        CommandParser.parse(
          input: 'Hello @john how are you?',
          availableCommands: testCommands,
        ),
        isNull,
      );
    });

    test('should ignore disabled commands', () {
      final disabledCommands = testCommands
          .map((c) => c.trigger == '@rewrite' ? c.copyWith(enabled: false) : c)
          .toList();

      final result = CommandParser.parse(
        input: 'Rewrite this text @rewrite',
        availableCommands: disabledCommands,
      );

      expect(result, isNull);
    });

    test('should return null for empty input or no text before trigger', () {
      expect(
        CommandParser.parse(input: '   ', availableCommands: testCommands),
        isNull,
      );

      expect(
        CommandParser.parse(input: '@fix', availableCommands: testCommands),
        isNull,
      );
    });
  });
}
