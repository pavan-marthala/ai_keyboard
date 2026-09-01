// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'command_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CommandEntity {

 String get trigger; String get name; String get description; String get prompt; bool get enabled;
/// Create a copy of CommandEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommandEntityCopyWith<CommandEntity> get copyWith => _$CommandEntityCopyWithImpl<CommandEntity>(this as CommandEntity, _$identity);

  /// Serializes this CommandEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CommandEntity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommandEntity&&(identical(other.trigger, _this.trigger) || other.trigger == _this.trigger)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.prompt, _this.prompt) || other.prompt == _this.prompt)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CommandEntity;
  return Object.hash(runtimeType,_this.trigger,_this.name,_this.description,_this.prompt,_this.enabled);
}

@override
String toString() {
  final _this = this as CommandEntity;
  return 'CommandEntity(trigger: ${_this.trigger}, name: ${_this.name}, description: ${_this.description}, prompt: ${_this.prompt}, enabled: ${_this.enabled})';
}


}

/// @nodoc
abstract mixin class $CommandEntityCopyWith<$Res>  {
  factory $CommandEntityCopyWith(CommandEntity value, $Res Function(CommandEntity) _then) = _$CommandEntityCopyWithImpl;
@useResult
$Res call({
 String trigger, String name, String description, String prompt, bool enabled
});




}
/// @nodoc
class _$CommandEntityCopyWithImpl<$Res>
    implements $CommandEntityCopyWith<$Res> {
  _$CommandEntityCopyWithImpl(this._self, this._then);

  final CommandEntity _self;
  final $Res Function(CommandEntity) _then;

/// Create a copy of CommandEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? trigger = null,Object? name = null,Object? description = null,Object? prompt = null,Object? enabled = null,}) {
  return _then(CommandEntity(
trigger: null == trigger ? _self.trigger : trigger // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CommandEntity].
extension CommandEntityPatterns on CommandEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommandEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommandEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommandEntity value)  $default,){
final _that = this;
switch (_that) {
case _CommandEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommandEntity value)?  $default,){
final _that = this;
switch (_that) {
case _CommandEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String trigger,  String name,  String description,  String prompt,  bool enabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommandEntity() when $default != null:
return $default(_that.trigger,_that.name,_that.description,_that.prompt,_that.enabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String trigger,  String name,  String description,  String prompt,  bool enabled)  $default,) {final _that = this;
switch (_that) {
case _CommandEntity():
return $default(_that.trigger,_that.name,_that.description,_that.prompt,_that.enabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String trigger,  String name,  String description,  String prompt,  bool enabled)?  $default,) {final _that = this;
switch (_that) {
case _CommandEntity() when $default != null:
return $default(_that.trigger,_that.name,_that.description,_that.prompt,_that.enabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommandEntity implements CommandEntity {
  const _CommandEntity({required this.trigger, required this.name, required this.description, required this.prompt, this.enabled = true});
  factory _CommandEntity.fromJson(Map<String, dynamic> json) => _$CommandEntityFromJson(json);

@override final  String trigger;
@override final  String name;
@override final  String description;
@override final  String prompt;
@override@JsonKey() final  bool enabled;

/// Create a copy of CommandEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommandEntityCopyWith<_CommandEntity> get copyWith => __$CommandEntityCopyWithImpl<_CommandEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommandEntityToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommandEntity&&(identical(other.trigger, trigger) || other.trigger == trigger)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,trigger,name,description,prompt,enabled);
}

@override
String toString() {
    return 'CommandEntity(trigger: $trigger, name: $name, description: $description, prompt: $prompt, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$CommandEntityCopyWith<$Res> implements $CommandEntityCopyWith<$Res> {
  factory _$CommandEntityCopyWith(_CommandEntity value, $Res Function(_CommandEntity) _then) = __$CommandEntityCopyWithImpl;
@override @useResult
$Res call({
 String trigger, String name, String description, String prompt, bool enabled
});




}
/// @nodoc
class __$CommandEntityCopyWithImpl<$Res>
    implements _$CommandEntityCopyWith<$Res> {
  __$CommandEntityCopyWithImpl(this._self, this._then);

  final _CommandEntity _self;
  final $Res Function(_CommandEntity) _then;

/// Create a copy of CommandEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trigger = null,Object? name = null,Object? description = null,Object? prompt = null,Object? enabled = null,}) {
  return _then(_CommandEntity(
trigger: null == trigger ? _self.trigger : trigger // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
