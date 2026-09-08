import 'dart:convert';

import 'package:atfix/features/commands/domain/entities/command_entity.dart';
import 'package:atfix/features/commands/domain/repositories/command_registry.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'command_event.dart';
import 'command_state.dart';

@injectable
class CommandBloc extends Bloc<CommandEvent, CommandState> {
  final SharedPreferences _prefs;
  final CommandRegistry _commandRegistry;
  static const String _commandsStorageKey = 'custom_commands';

  CommandBloc(
    this._prefs,
    this._commandRegistry,
  ) : super(const CommandState()) {
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

  List<CommandEntity> get _defaultCommands => _commandRegistry.commands;

  Future<void> _onLoadCommands(Emitter<CommandState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final jsonString = _prefs.getString(_commandsStorageKey);
      if (jsonString == null) {
        emit(state.copyWith(commands: _defaultCommands, isLoading: false));
        return;
      }
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      final List<CommandEntity> rawCommands = jsonList
          .map((item) => CommandEntity.fromJson(item as Map<String, dynamic>))
          .toList();

      var hasMigrated = false;
      final commands = <CommandEntity>[];
      for (final cmd in rawCommands) {
        if (cmd.trigger.toLowerCase() == '@pro') {
          hasMigrated = true;
          final proEntity = _commandRegistry.findByTrigger('@professional');
          if (proEntity != null) {
            commands.add(proEntity.copyWith(enabled: cmd.enabled));
          }
        } else {
          commands.add(cmd);
        }
      }

      if (hasMigrated) {
        await _saveCommands(commands);
      }

      emit(state.copyWith(commands: commands, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          commands: _defaultCommands,
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
    await _saveCommands(_defaultCommands);
    emit(state.copyWith(commands: _defaultCommands));
  }
}
