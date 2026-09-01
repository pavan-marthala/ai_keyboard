import 'package:ai_keyboard/features/commands/domain/entities/command_entity.dart';
import 'package:ai_keyboard/features/commands/domain/parser/command_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CommandParser tests', () {
    const testCommands = [
      CommandEntity(
        trigger: '@fix',
        name: 'Fix Grammar',
        description: 'Fixes grammar',
        prompt: 'Fix grammar',
        enabled: true,
      ),
      CommandEntity(
        trigger: '@pro',
        name: 'Make Professional',
        description: 'Make professional',
        prompt: 'Make professional',
        enabled: true,
      ),
      CommandEntity(
        trigger: '@disabled',
        name: 'Disabled Command',
        description: 'Disabled',
        prompt: 'Disabled',
        enabled: false,
      ),
    ];

    test('should parse command at the end of input text', () {
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

    test('should parse command case-insensitively', () {
      const input = 'This is a test message @FIX';
      final result = CommandParser.parse(
        input: input,
        availableCommands: testCommands,
      );

      expect(result, isNotNull);
      expect(result!.cleanText, equals('This is a test message'));
      expect(result.command.trigger, equals('@fix'));
    });

    test('should ignore unknown command triggers', () {
      const input = 'Hello @john how are you?';
      final result = CommandParser.parse(
        input: input,
        availableCommands: testCommands,
      );

      expect(result, isNull);
    });

    test('should ignore disabled commands', () {
      const input = 'Some text @disabled';
      final result = CommandParser.parse(
        input: input,
        availableCommands: testCommands,
      );

      expect(result, isNull);
    });

    test('should return null for empty input', () {
      final result = CommandParser.parse(
        input: '   ',
        availableCommands: testCommands,
      );

      expect(result, isNull);
    });

    test('should strip trailing punctuation attached to trigger', () {
      const input = 'Fix this sentence please @fix.';
      final result = CommandParser.parse(
        input: input,
        availableCommands: testCommands,
      );

      expect(result, isNotNull);
      expect(result!.cleanText, equals('Fix this sentence please'));
      expect(result.command.trigger, equals('@fix'));
    });
  });
}
