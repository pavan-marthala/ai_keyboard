// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'command_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommandEvent {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CommandEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CommandEvent()';
}


}

/// @nodoc
class $CommandEventCopyWith<$Res>  {
$CommandEventCopyWith(CommandEvent _, $Res Function(CommandEvent) __);
}


/// Adds pattern-matching-related methods to [CommandEvent].
extension CommandEventPatterns on CommandEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _LoadCommands value)?  loadCommands,TResult Function( _AddCommand value)?  addCommand,TResult Function( _UpdateCommand value)?  updateCommand,TResult Function( _DeleteCommand value)?  deleteCommand,TResult Function( _ToggleCommandEnabled value)?  toggleCommandEnabled,TResult Function( _ResetToDefaults value)?  resetToDefaults,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoadCommands() when loadCommands != null:
return loadCommands(_that);case _AddCommand() when addCommand != null:
return addCommand(_that);case _UpdateCommand() when updateCommand != null:
return updateCommand(_that);case _DeleteCommand() when deleteCommand != null:
return deleteCommand(_that);case _ToggleCommandEnabled() when toggleCommandEnabled != null:
return toggleCommandEnabled(_that);case _ResetToDefaults() when resetToDefaults != null:
return resetToDefaults(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _LoadCommands value)  loadCommands,required TResult Function( _AddCommand value)  addCommand,required TResult Function( _UpdateCommand value)  updateCommand,required TResult Function( _DeleteCommand value)  deleteCommand,required TResult Function( _ToggleCommandEnabled value)  toggleCommandEnabled,required TResult Function( _ResetToDefaults value)  resetToDefaults,}){
final _that = this;
switch (_that) {
case _LoadCommands():
return loadCommands(_that);case _AddCommand():
return addCommand(_that);case _UpdateCommand():
return updateCommand(_that);case _DeleteCommand():
return deleteCommand(_that);case _ToggleCommandEnabled():
return toggleCommandEnabled(_that);case _ResetToDefaults():
return resetToDefaults(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _LoadCommands value)?  loadCommands,TResult? Function( _AddCommand value)?  addCommand,TResult? Function( _UpdateCommand value)?  updateCommand,TResult? Function( _DeleteCommand value)?  deleteCommand,TResult? Function( _ToggleCommandEnabled value)?  toggleCommandEnabled,TResult? Function( _ResetToDefaults value)?  resetToDefaults,}){
final _that = this;
switch (_that) {
case _LoadCommands() when loadCommands != null:
return loadCommands(_that);case _AddCommand() when addCommand != null:
return addCommand(_that);case _UpdateCommand() when updateCommand != null:
return updateCommand(_that);case _DeleteCommand() when deleteCommand != null:
return deleteCommand(_that);case _ToggleCommandEnabled() when toggleCommandEnabled != null:
return toggleCommandEnabled(_that);case _ResetToDefaults() when resetToDefaults != null:
return resetToDefaults(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadCommands,TResult Function( CommandEntity command)?  addCommand,TResult Function( CommandEntity command)?  updateCommand,TResult Function( String trigger)?  deleteCommand,TResult Function( String trigger)?  toggleCommandEnabled,TResult Function()?  resetToDefaults,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoadCommands() when loadCommands != null:
return loadCommands();case _AddCommand() when addCommand != null:
return addCommand(_that.command);case _UpdateCommand() when updateCommand != null:
return updateCommand(_that.command);case _DeleteCommand() when deleteCommand != null:
return deleteCommand(_that.trigger);case _ToggleCommandEnabled() when toggleCommandEnabled != null:
return toggleCommandEnabled(_that.trigger);case _ResetToDefaults() when resetToDefaults != null:
return resetToDefaults();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadCommands,required TResult Function( CommandEntity command)  addCommand,required TResult Function( CommandEntity command)  updateCommand,required TResult Function( String trigger)  deleteCommand,required TResult Function( String trigger)  toggleCommandEnabled,required TResult Function()  resetToDefaults,}) {final _that = this;
switch (_that) {
case _LoadCommands():
return loadCommands();case _AddCommand():
return addCommand(_that.command);case _UpdateCommand():
return updateCommand(_that.command);case _DeleteCommand():
return deleteCommand(_that.trigger);case _ToggleCommandEnabled():
return toggleCommandEnabled(_that.trigger);case _ResetToDefaults():
return resetToDefaults();case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadCommands,TResult? Function( CommandEntity command)?  addCommand,TResult? Function( CommandEntity command)?  updateCommand,TResult? Function( String trigger)?  deleteCommand,TResult? Function( String trigger)?  toggleCommandEnabled,TResult? Function()?  resetToDefaults,}) {final _that = this;
switch (_that) {
case _LoadCommands() when loadCommands != null:
return loadCommands();case _AddCommand() when addCommand != null:
return addCommand(_that.command);case _UpdateCommand() when updateCommand != null:
return updateCommand(_that.command);case _DeleteCommand() when deleteCommand != null:
return deleteCommand(_that.trigger);case _ToggleCommandEnabled() when toggleCommandEnabled != null:
return toggleCommandEnabled(_that.trigger);case _ResetToDefaults() when resetToDefaults != null:
return resetToDefaults();case _:
  return null;

}
}

}

/// @nodoc


class _LoadCommands implements CommandEvent {
  const _LoadCommands();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadCommands);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CommandEvent.loadCommands()';
}


}




/// @nodoc


class _AddCommand implements CommandEvent {
  const _AddCommand(this.command);
  

 final  CommandEntity command;

/// Create a copy of CommandEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddCommandCopyWith<_AddCommand> get copyWith => __$AddCommandCopyWithImpl<_AddCommand>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddCommand&&(identical(other.command, command) || other.command == command));
}


@override
int get hashCode {
    return Object.hash(runtimeType,command);
}

@override
String toString() {
    return 'CommandEvent.addCommand(command: $command)';
}


}

/// @nodoc
abstract mixin class _$AddCommandCopyWith<$Res> implements $CommandEventCopyWith<$Res> {
  factory _$AddCommandCopyWith(_AddCommand value, $Res Function(_AddCommand) _then) = __$AddCommandCopyWithImpl;
@useResult
$Res call({
 CommandEntity command
});


$CommandEntityCopyWith<$Res> get command;

}
/// @nodoc
class __$AddCommandCopyWithImpl<$Res>
    implements _$AddCommandCopyWith<$Res> {
  __$AddCommandCopyWithImpl(this._self, this._then);

  final _AddCommand _self;
  final $Res Function(_AddCommand) _then;

/// Create a copy of CommandEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? command = null,}) {
  return _then(_AddCommand(
null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as CommandEntity,
  ));
}

/// Create a copy of CommandEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommandEntityCopyWith<$Res> get command {
  
  return $CommandEntityCopyWith<$Res>(_self.command, (value) {
    return _then(_self.copyWith(command: value));
  });
}
}

/// @nodoc


class _UpdateCommand implements CommandEvent {
  const _UpdateCommand(this.command);
  

 final  CommandEntity command;

/// Create a copy of CommandEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateCommandCopyWith<_UpdateCommand> get copyWith => __$UpdateCommandCopyWithImpl<_UpdateCommand>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateCommand&&(identical(other.command, command) || other.command == command));
}


@override
int get hashCode {
    return Object.hash(runtimeType,command);
}

@override
String toString() {
    return 'CommandEvent.updateCommand(command: $command)';
}


}

/// @nodoc
abstract mixin class _$UpdateCommandCopyWith<$Res> implements $CommandEventCopyWith<$Res> {
  factory _$UpdateCommandCopyWith(_UpdateCommand value, $Res Function(_UpdateCommand) _then) = __$UpdateCommandCopyWithImpl;
@useResult
$Res call({
 CommandEntity command
});


$CommandEntityCopyWith<$Res> get command;

}
/// @nodoc
class __$UpdateCommandCopyWithImpl<$Res>
    implements _$UpdateCommandCopyWith<$Res> {
  __$UpdateCommandCopyWithImpl(this._self, this._then);

  final _UpdateCommand _self;
  final $Res Function(_UpdateCommand) _then;

/// Create a copy of CommandEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? command = null,}) {
  return _then(_UpdateCommand(
null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as CommandEntity,
  ));
}

/// Create a copy of CommandEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommandEntityCopyWith<$Res> get command {
  
  return $CommandEntityCopyWith<$Res>(_self.command, (value) {
    return _then(_self.copyWith(command: value));
  });
}
}

/// @nodoc


class _DeleteCommand implements CommandEvent {
  const _DeleteCommand(this.trigger);
  

 final  String trigger;

/// Create a copy of CommandEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeleteCommandCopyWith<_DeleteCommand> get copyWith => __$DeleteCommandCopyWithImpl<_DeleteCommand>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeleteCommand&&(identical(other.trigger, trigger) || other.trigger == trigger));
}


@override
int get hashCode {
    return Object.hash(runtimeType,trigger);
}

@override
String toString() {
    return 'CommandEvent.deleteCommand(trigger: $trigger)';
}


}

/// @nodoc
abstract mixin class _$DeleteCommandCopyWith<$Res> implements $CommandEventCopyWith<$Res> {
  factory _$DeleteCommandCopyWith(_DeleteCommand value, $Res Function(_DeleteCommand) _then) = __$DeleteCommandCopyWithImpl;
@useResult
$Res call({
 String trigger
});




}
/// @nodoc
class __$DeleteCommandCopyWithImpl<$Res>
    implements _$DeleteCommandCopyWith<$Res> {
  __$DeleteCommandCopyWithImpl(this._self, this._then);

  final _DeleteCommand _self;
  final $Res Function(_DeleteCommand) _then;

/// Create a copy of CommandEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? trigger = null,}) {
  return _then(_DeleteCommand(
null == trigger ? _self.trigger : trigger // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ToggleCommandEnabled implements CommandEvent {
  const _ToggleCommandEnabled(this.trigger);
  

 final  String trigger;

/// Create a copy of CommandEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToggleCommandEnabledCopyWith<_ToggleCommandEnabled> get copyWith => __$ToggleCommandEnabledCopyWithImpl<_ToggleCommandEnabled>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToggleCommandEnabled&&(identical(other.trigger, trigger) || other.trigger == trigger));
}


@override
int get hashCode {
    return Object.hash(runtimeType,trigger);
}

@override
String toString() {
    return 'CommandEvent.toggleCommandEnabled(trigger: $trigger)';
}


}

/// @nodoc
abstract mixin class _$ToggleCommandEnabledCopyWith<$Res> implements $CommandEventCopyWith<$Res> {
  factory _$ToggleCommandEnabledCopyWith(_ToggleCommandEnabled value, $Res Function(_ToggleCommandEnabled) _then) = __$ToggleCommandEnabledCopyWithImpl;
@useResult
$Res call({
 String trigger
});




}
/// @nodoc
class __$ToggleCommandEnabledCopyWithImpl<$Res>
    implements _$ToggleCommandEnabledCopyWith<$Res> {
  __$ToggleCommandEnabledCopyWithImpl(this._self, this._then);

  final _ToggleCommandEnabled _self;
  final $Res Function(_ToggleCommandEnabled) _then;

/// Create a copy of CommandEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? trigger = null,}) {
  return _then(_ToggleCommandEnabled(
null == trigger ? _self.trigger : trigger // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ResetToDefaults implements CommandEvent {
  const _ResetToDefaults();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResetToDefaults);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CommandEvent.resetToDefaults()';
}


}




// dart format on
