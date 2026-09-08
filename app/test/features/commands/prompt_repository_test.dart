import 'package:atfix/features/commands/data/generated/generated_command_definitions.dart';
import 'package:atfix/features/commands/data/repositories/prompt_repository.dart';
import 'package:atfix/features/commands/domain/repositories/command_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PromptRepository & CommandRegistry Schema v2 Tests', () {
    late PromptRepository repository;
    late CommandRegistryImpl registry;

    setUp(() {
      repository = PromptRepositoryImpl();
      registry = CommandRegistryImpl(repository);
    });

    test('loads all 7 canonical commands in order', () {
      final commands = repository.commands;
      expect(commands.length, equals(7));

      final triggers = commands.map((c) => c.command).toList();
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

      final ids = commands.map((c) => c.id).toList();
      expect(
        ids,
        equals([
          'fix',
          'rewrite',
          'professional',
          'casual',
          'short',
          'expand',
          'translate',
        ]),
      );
    });

    test('strictly rejects @pro and pro lookups', () {
      expect(repository.getCommand('@pro'), isNull);
      expect(repository.getCommand('pro'), isNull);
      expect(repository.hasPrompt('@pro'), isFalse);
      expect(repository.hasPrompt('pro'), isFalse);
      expect(repository.getPrompt('@pro'), isNull);
      expect(repository.getPrompt('pro'), isNull);
    });

    test('resolves @professional canonical command and prompt', () {
      final cmd = repository.getCommand('@professional');
      expect(cmd, isNotNull);
      expect(cmd!.id, equals('professional'));
      expect(cmd.label, equals('Professional'));
      expect(cmd.actionLabel, equals('Making professional...'));
      expect(cmd.description, equals('Make the tone professional and formal'));
      expect(cmd.requiresInput, isFalse);
      expect(cmd.inputType, isNull);

      final prompt = repository.getPrompt('professional');
      expect(prompt, isNotNull);
      expect(prompt, contains('professional tone'));
    });

    test('action label resolves dynamically for commands and fallback', () {
      expect(repository.getActionLabel('@fix'), equals('Fixing...'));
      expect(repository.getActionLabel('@rewrite'), equals('Rewriting...'));
      expect(repository.getActionLabel('@professional'), equals('Making professional...'));
      expect(repository.getActionLabel('@casual'), equals('Making casual...'));
      expect(repository.getActionLabel('@short'), equals('Shortening...'));
      expect(repository.getActionLabel('@expand'), equals('Expanding...'));
      expect(repository.getActionLabel('@translate'), equals('Translating...'));
      expect(repository.getActionLabel('@pro'), equals('Transforming...'));
      expect(repository.getActionLabel('@unknown'), equals('Transforming...'));
    });

    test('interpolates template variables in getPrompt', () {
      final prompt = repository.getPrompt('translate', {'language': 'German'});
      expect(prompt, isNotNull);
      expect(prompt, contains('German'));
      expect(prompt, isNot(contains('{{language}}')));
    });

    test('initializes with custom generated definitions when provided', () {
      final customRepo = PromptRepositoryImpl([
        const GeneratedCommandDefinition(
          id: 'custom',
          command: '@custom',
          label: 'Custom',
          actionLabel: 'Customizing...',
          description: 'Custom command',
          order: 1,
          requiresInput: false,
          inputType: null,
          system: 'Custom system prompt',
        ),
      ]);
      expect(customRepo.commands.length, equals(1));
      expect(customRepo.getCommand('@custom')?.label, equals('Custom'));
      expect(customRepo.getPrompt('custom'), equals('Custom system prompt'));
    });

    test('CommandRegistry reflects repository commands and supports disabling triggers', () {
      final entities = registry.commands;
      expect(entities.length, equals(7));
      expect(entities.any((e) => e.trigger == '@professional'), isTrue);
      expect(entities.any((e) => e.trigger == '@pro'), isFalse);

      final fix = entities.firstWhere((e) => e.trigger == '@fix');
      expect(fix.description, equals('Fix grammar, spelling, and punctuation'));

      final findProfessional = registry.findByTrigger('@professional');
      expect(findProfessional, isNotNull);
      expect(findProfessional!.description, equals('Make the tone professional and formal'));

      registry.setDisabledTriggers({'@rewrite', '@casual'});
      final updated = registry.commands;
      final rewrite = updated.firstWhere((e) => e.trigger == '@rewrite');
      final casual = updated.firstWhere((e) => e.trigger == '@casual');
      final pro = updated.firstWhere((e) => e.trigger == '@professional');

      expect(rewrite.enabled, isFalse);
      expect(casual.enabled, isFalse);
      expect(pro.enabled, isTrue);
    });
  });
}
