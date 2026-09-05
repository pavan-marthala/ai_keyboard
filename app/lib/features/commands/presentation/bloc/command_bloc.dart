import 'dart:convert';

import 'package:ai_keyboard/features/commands/domain/entities/command_entity.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'command_event.dart';
import 'command_state.dart';

const List<CommandEntity> defaultCommands = [
  CommandEntity(
    trigger: '@fix',
    name: 'Fix Grammar',
    description: 'Fix grammar, spelling, and punctuation',
    prompt: 'Fix grammar, spelling and punctuation. Preserve original meaning. Return only the corrected text.',
  ),
  CommandEntity(
    trigger: '@rewrite',
    name: 'Rewrite',
    description: 'Rewrite text for clarity and structure',
    prompt: 'Rewrite the text to be clear, elegant, and well structured. Return only the rewritten text.',
  ),
  CommandEntity(
    trigger: '@pro',
    name: 'Make Professional',
    description: 'Make the tone professional and formal',
    prompt: 'Rewrite the text in a professional, formal, and polite business tone. Return only the modified text.',
  ),
  CommandEntity(
    trigger: '@casual',
    name: 'Make Casual',
    description: 'Make the tone casual and friendly',
    prompt: 'Rewrite the text in a casual, conversational, and friendly tone. Return only the modified text.',
  ),
  CommandEntity(
    trigger: '@short',
    name: 'Shorten',
    description: 'Shorten text while preserving meaning',
    prompt: 'Shorten the text to be concise while preserving key points. Return only the shortened text.',
  ),
  CommandEntity(
    trigger: '@expand',
    name: 'Expand',
    description: 'Expand text with more detail',
    prompt: 'Expand the text with relevant detail, depth, and context. Return only the expanded text.',
  ),
  CommandEntity(
    trigger: '@translate',
    name: 'Translate to English',
    description: 'Translate input text to English',
    prompt: 'Translate the following text to fluent English. Return only the translated text.',
  ),
];

@injectable
class CommandBloc extends Bloc<CommandEvent, CommandState> {
  final SharedPreferences _prefs;
  static const String _commandsStorageKey = 'custom_commands';

  CommandBloc(this._prefs) : super(const CommandState()) {
    on<CommandEvent>((event, emit) async {
      await event.map(
        loadCommands: (_) async => _onLoadCommands(emit),
        addCommand: (e) async => _onAddCommand(e.command, emit),
        updateCommand: (e) async => _onUpdateCommand(e.command, emit),
        deleteCommand: (e) async => _onDeleteCommand(e.trigger, emit),
        toggleCommandEnabled: (e) async =>
            _onToggleCommandEnabled(e.trigger, emit),
        resetToDefaults: (_) async => _onResetToDefaults(emit),
      );
    });
  }

  Future<void> _onLoadCommands(Emitter<CommandState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final jsonString = _prefs.getString(_commandsStorageKey);
      if (jsonString == null) {
        emit(state.copyWith(commands: defaultCommands, isLoading: false));
        return;
      }
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      final List<CommandEntity> commands = jsonList
          .map((item) => CommandEntity.fromJson(item as Map<String, dynamic>))
          .toList();
      emit(state.copyWith(commands: commands, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          commands: defaultCommands,
          isLoading: false,
          errorMessage: 'Failed to load saved commands: $e',
        ),
      );
    }
  }

  static const _credentialsChannel = MethodChannel('com.pk.atfix/credentials');

  Future<void> _saveCommands(List<CommandEntity> commands) async {
    final jsonString = jsonEncode(commands.map((c) => c.toJson()).toList());
    await _prefs.setString(_commandsStorageKey, jsonString);

    try {
      final disabledTriggers = commands
          .where((c) => !c.enabled)
          .map((c) => c.trigger)
          .toList();
      await _credentialsChannel.invokeMethod('saveDisabledCommands', {
        'disabledTriggers': disabledTriggers,
      });
    } catch (_) {}
  }

  Future<void> _onAddCommand(
    CommandEntity command,
    Emitter<CommandState> emit,
  ) async {
    final updated = List<CommandEntity>.from(state.commands)..add(command);
    await _saveCommands(updated);
    emit(state.copyWith(commands: updated));
  }

  Future<void> _onUpdateCommand(
    CommandEntity command,
    Emitter<CommandState> emit,
  ) async {
    final updated = state.commands.map((c) {
      return c.trigger.toLowerCase() == command.trigger.toLowerCase()
          ? command
          : c;
    }).toList();
    await _saveCommands(updated);
    emit(state.copyWith(commands: updated));
  }

  Future<void> _onDeleteCommand(
    String trigger,
    Emitter<CommandState> emit,
  ) async {
    final updated = state.commands
        .where((c) => c.trigger.toLowerCase() != trigger.toLowerCase())
        .toList();
    await _saveCommands(updated);
    emit(state.copyWith(commands: updated));
  }

  Future<void> _onToggleCommandEnabled(
    String trigger,
    Emitter<CommandState> emit,
  ) async {
    final updated = state.commands.map((c) {
      return c.trigger.toLowerCase() == trigger.toLowerCase()
          ? c.copyWith(enabled: !c.enabled)
          : c;
    }).toList();
    await _saveCommands(updated);
    emit(state.copyWith(commands: updated));
  }

  Future<void> _onResetToDefaults(Emitter<CommandState> emit) async {
    await _saveCommands(defaultCommands);
    emit(state.copyWith(commands: defaultCommands));
  }
}
