// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'command_parser.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ParsedCommandResult {

 String get cleanText; CommandEntity get command;
/// Create a copy of ParsedCommandResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParsedCommandResultCopyWith<ParsedCommandResult> get copyWith => _$ParsedCommandResultCopyWithImpl<ParsedCommandResult>(this as ParsedCommandResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ParsedCommandResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParsedCommandResult&&(identical(other.cleanText, _this.cleanText) || other.cleanText == _this.cleanText)&&(identical(other.command, _this.command) || other.command == _this.command));
}


@override
int get hashCode {
  final _this = this as ParsedCommandResult;
  return Object.hash(runtimeType,_this.cleanText,_this.command);
}

@override
String toString() {
  final _this = this as ParsedCommandResult;
  return 'ParsedCommandResult(cleanText: ${_this.cleanText}, command: ${_this.command})';
}


}

/// @nodoc
abstract mixin class $ParsedCommandResultCopyWith<$Res>  {
  factory $ParsedCommandResultCopyWith(ParsedCommandResult value, $Res Function(ParsedCommandResult) _then) = _$ParsedCommandResultCopyWithImpl;
@useResult
$Res call({
 String cleanText, CommandEntity command
});


$CommandEntityCopyWith<$Res> get command;

}
/// @nodoc
class _$ParsedCommandResultCopyWithImpl<$Res>
    implements $ParsedCommandResultCopyWith<$Res> {
  _$ParsedCommandResultCopyWithImpl(this._self, this._then);

  final ParsedCommandResult _self;
  final $Res Function(ParsedCommandResult) _then;

/// Create a copy of ParsedCommandResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cleanText = null,Object? command = null,}) {
  return _then(ParsedCommandResult(
cleanText: null == cleanText ? _self.cleanText : cleanText // ignore: cast_nullable_to_non_nullable
as String,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as CommandEntity,
  ));
}
/// Create a copy of ParsedCommandResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommandEntityCopyWith<$Res> get command {
  
  return $CommandEntityCopyWith<$Res>(_self.command, (value) {
    return _then(_self.copyWith(command: value));
  });
}
}


/// Adds pattern-matching-related methods to [ParsedCommandResult].
extension ParsedCommandResultPatterns on ParsedCommandResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParsedCommandResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParsedCommandResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParsedCommandResult value)  $default,){
final _that = this;
switch (_that) {
case _ParsedCommandResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParsedCommandResult value)?  $default,){
final _that = this;
switch (_that) {
case _ParsedCommandResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String cleanText,  CommandEntity command)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParsedCommandResult() when $default != null:
return $default(_that.cleanText,_that.command);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String cleanText,  CommandEntity command)  $default,) {final _that = this;
switch (_that) {
case _ParsedCommandResult():
return $default(_that.cleanText,_that.command);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String cleanText,  CommandEntity command)?  $default,) {final _that = this;
switch (_that) {
case _ParsedCommandResult() when $default != null:
return $default(_that.cleanText,_that.command);case _:
  return null;

}
}

}

/// @nodoc


class _ParsedCommandResult implements ParsedCommandResult {
  const _ParsedCommandResult({required this.cleanText, required this.command});
  

@override final  String cleanText;
@override final  CommandEntity command;

/// Create a copy of ParsedCommandResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParsedCommandResultCopyWith<_ParsedCommandResult> get copyWith => __$ParsedCommandResultCopyWithImpl<_ParsedCommandResult>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParsedCommandResult&&(identical(other.cleanText, cleanText) || other.cleanText == cleanText)&&(identical(other.command, command) || other.command == command));
}


@override
int get hashCode {
    return Object.hash(runtimeType,cleanText,command);
}

@override
String toString() {
    return 'ParsedCommandResult(cleanText: $cleanText, command: $command)';
}


}

/// @nodoc
abstract mixin class _$ParsedCommandResultCopyWith<$Res> implements $ParsedCommandResultCopyWith<$Res> {
  factory _$ParsedCommandResultCopyWith(_ParsedCommandResult value, $Res Function(_ParsedCommandResult) _then) = __$ParsedCommandResultCopyWithImpl;
@override @useResult
$Res call({
 String cleanText, CommandEntity command
});


@override $CommandEntityCopyWith<$Res> get command;

}
/// @nodoc
class __$ParsedCommandResultCopyWithImpl<$Res>
    implements _$ParsedCommandResultCopyWith<$Res> {
  __$ParsedCommandResultCopyWithImpl(this._self, this._then);

  final _ParsedCommandResult _self;
  final $Res Function(_ParsedCommandResult) _then;

/// Create a copy of ParsedCommandResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cleanText = null,Object? command = null,}) {
  return _then(_ParsedCommandResult(
cleanText: null == cleanText ? _self.cleanText : cleanText // ignore: cast_nullable_to_non_nullable
as String,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as CommandEntity,
  ));
}

/// Create a copy of ParsedCommandResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommandEntityCopyWith<$Res> get command {
  
  return $CommandEntityCopyWith<$Res>(_self.command, (value) {
    return _then(_self.copyWith(command: value));
  });
}
}

// dart format on
