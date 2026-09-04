// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'desktop_capability.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DesktopCapability {

 DesktopCapabilityType get type; String get title; String get description; DesktopCapabilityStatus get status; bool get isRequired;
/// Create a copy of DesktopCapability
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesktopCapabilityCopyWith<DesktopCapability> get copyWith => _$DesktopCapabilityCopyWithImpl<DesktopCapability>(this as DesktopCapability, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DesktopCapability;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesktopCapability&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.isRequired, _this.isRequired) || other.isRequired == _this.isRequired));
}


@override
int get hashCode {
  final _this = this as DesktopCapability;
  return Object.hash(runtimeType,_this.type,_this.title,_this.description,_this.status,_this.isRequired);
}

@override
String toString() {
  final _this = this as DesktopCapability;
  return 'DesktopCapability(type: ${_this.type}, title: ${_this.title}, description: ${_this.description}, status: ${_this.status}, isRequired: ${_this.isRequired})';
}


}

/// @nodoc
abstract mixin class $DesktopCapabilityCopyWith<$Res>  {
  factory $DesktopCapabilityCopyWith(DesktopCapability value, $Res Function(DesktopCapability) _then) = _$DesktopCapabilityCopyWithImpl;
@useResult
$Res call({
 DesktopCapabilityType type, String title, String description, DesktopCapabilityStatus status, bool isRequired
});




}
/// @nodoc
class _$DesktopCapabilityCopyWithImpl<$Res>
    implements $DesktopCapabilityCopyWith<$Res> {
  _$DesktopCapabilityCopyWithImpl(this._self, this._then);

  final DesktopCapability _self;
  final $Res Function(DesktopCapability) _then;

/// Create a copy of DesktopCapability
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? title = null,Object? description = null,Object? status = null,Object? isRequired = null,}) {
  return _then(DesktopCapability(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DesktopCapabilityType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DesktopCapabilityStatus,isRequired: null == isRequired ? _self.isRequired : isRequired // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DesktopCapability].
extension DesktopCapabilityPatterns on DesktopCapability {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesktopCapability value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesktopCapability() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesktopCapability value)  $default,){
final _that = this;
switch (_that) {
case _DesktopCapability():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesktopCapability value)?  $default,){
final _that = this;
switch (_that) {
case _DesktopCapability() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DesktopCapabilityType type,  String title,  String description,  DesktopCapabilityStatus status,  bool isRequired)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesktopCapability() when $default != null:
return $default(_that.type,_that.title,_that.description,_that.status,_that.isRequired);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DesktopCapabilityType type,  String title,  String description,  DesktopCapabilityStatus status,  bool isRequired)  $default,) {final _that = this;
switch (_that) {
case _DesktopCapability():
return $default(_that.type,_that.title,_that.description,_that.status,_that.isRequired);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DesktopCapabilityType type,  String title,  String description,  DesktopCapabilityStatus status,  bool isRequired)?  $default,) {final _that = this;
switch (_that) {
case _DesktopCapability() when $default != null:
return $default(_that.type,_that.title,_that.description,_that.status,_that.isRequired);case _:
  return null;

}
}

}

/// @nodoc


class _DesktopCapability implements DesktopCapability {
  const _DesktopCapability({required this.type, required this.title, required this.description, required this.status, this.isRequired = true});
  

@override final  DesktopCapabilityType type;
@override final  String title;
@override final  String description;
@override final  DesktopCapabilityStatus status;
@override@JsonKey() final  bool isRequired;

/// Create a copy of DesktopCapability
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesktopCapabilityCopyWith<_DesktopCapability> get copyWith => __$DesktopCapabilityCopyWithImpl<_DesktopCapability>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesktopCapability&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.isRequired, isRequired) || other.isRequired == isRequired));
}


@override
int get hashCode {
    return Object.hash(runtimeType,type,title,description,status,isRequired);
}

@override
String toString() {
    return 'DesktopCapability(type: $type, title: $title, description: $description, status: $status, isRequired: $isRequired)';
}


}

/// @nodoc
abstract mixin class _$DesktopCapabilityCopyWith<$Res> implements $DesktopCapabilityCopyWith<$Res> {
  factory _$DesktopCapabilityCopyWith(_DesktopCapability value, $Res Function(_DesktopCapability) _then) = __$DesktopCapabilityCopyWithImpl;
@override @useResult
$Res call({
 DesktopCapabilityType type, String title, String description, DesktopCapabilityStatus status, bool isRequired
});




}
/// @nodoc
class __$DesktopCapabilityCopyWithImpl<$Res>
    implements _$DesktopCapabilityCopyWith<$Res> {
  __$DesktopCapabilityCopyWithImpl(this._self, this._then);

  final _DesktopCapability _self;
  final $Res Function(_DesktopCapability) _then;

/// Create a copy of DesktopCapability
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? title = null,Object? description = null,Object? status = null,Object? isRequired = null,}) {
  return _then(_DesktopCapability(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DesktopCapabilityType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DesktopCapabilityStatus,isRequired: null == isRequired ? _self.isRequired : isRequired // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
