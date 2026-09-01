// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'command_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommandState {

 List<CommandEntity> get commands; bool get isLoading; String? get errorMessage;
/// Create a copy of CommandState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommandStateCopyWith<CommandState> get copyWith => _$CommandStateCopyWithImpl<CommandState>(this as CommandState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CommandState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommandState&&const DeepCollectionEquality().equals(other.commands, _this.commands)&&(identical(other.isLoading, _this.isLoading) || other.isLoading == _this.isLoading)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage));
}


@override
int get hashCode {
  final _this = this as CommandState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.commands),_this.isLoading,_this.errorMessage);
}

@override
String toString() {
  final _this = this as CommandState;
  return 'CommandState(commands: ${_this.commands}, isLoading: ${_this.isLoading}, errorMessage: ${_this.errorMessage})';
}


}

/// @nodoc
abstract mixin class $CommandStateCopyWith<$Res>  {
  factory $CommandStateCopyWith(CommandState value, $Res Function(CommandState) _then) = _$CommandStateCopyWithImpl;
@useResult
$Res call({
 List<CommandEntity> commands, bool isLoading, String? errorMessage
});




}
/// @nodoc
class _$CommandStateCopyWithImpl<$Res>
    implements $CommandStateCopyWith<$Res> {
  _$CommandStateCopyWithImpl(this._self, this._then);

  final CommandState _self;
  final $Res Function(CommandState) _then;

/// Create a copy of CommandState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? commands = null,Object? isLoading = null,Object? errorMessage = freezed,}) {
  return _then(CommandState(
commands: null == commands ? _self.commands : commands // ignore: cast_nullable_to_non_nullable
as List<CommandEntity>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CommandState].
extension CommandStatePatterns on CommandState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommandState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommandState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommandState value)  $default,){
final _that = this;
switch (_that) {
case _CommandState():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommandState value)?  $default,){
final _that = this;
switch (_that) {
case _CommandState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CommandEntity> commands,  bool isLoading,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommandState() when $default != null:
return $default(_that.commands,_that.isLoading,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CommandEntity> commands,  bool isLoading,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _CommandState():
return $default(_that.commands,_that.isLoading,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CommandEntity> commands,  bool isLoading,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _CommandState() when $default != null:
return $default(_that.commands,_that.isLoading,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _CommandState implements CommandState {
  const _CommandState({ List<CommandEntity> commands = const [], this.isLoading = false, this.errorMessage}): _commands = commands;
  

 final  List<CommandEntity> _commands;
@override@JsonKey() List<CommandEntity> get commands {
  if (_commands is EqualUnmodifiableListView) return _commands;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_commands);
}

@override@JsonKey() final  bool isLoading;
@override final  String? errorMessage;

/// Create a copy of CommandState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommandStateCopyWith<_CommandState> get copyWith => __$CommandStateCopyWithImpl<_CommandState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommandState&&const DeepCollectionEquality().equals(other.commands, _commands)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_commands),isLoading,errorMessage);
}

@override
String toString() {
    return 'CommandState(commands: $commands, isLoading: $isLoading, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$CommandStateCopyWith<$Res> implements $CommandStateCopyWith<$Res> {
  factory _$CommandStateCopyWith(_CommandState value, $Res Function(_CommandState) _then) = __$CommandStateCopyWithImpl;
@override @useResult
$Res call({
 List<CommandEntity> commands, bool isLoading, String? errorMessage
});




}
/// @nodoc
class __$CommandStateCopyWithImpl<$Res>
    implements _$CommandStateCopyWith<$Res> {
  __$CommandStateCopyWithImpl(this._self, this._then);

  final _CommandState _self;
  final $Res Function(_CommandState) _then;

/// Create a copy of CommandState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? commands = null,Object? isLoading = null,Object? errorMessage = freezed,}) {
  return _then(_CommandState(
commands: null == commands ? _self._commands : commands // ignore: cast_nullable_to_non_nullable
as List<CommandEntity>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
