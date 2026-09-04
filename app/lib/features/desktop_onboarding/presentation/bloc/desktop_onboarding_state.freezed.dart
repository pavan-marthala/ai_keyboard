// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'desktop_onboarding_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DesktopOnboardingState {

 bool get isLoading; List<DesktopCapability> get capabilities; bool get isAllRequiredGranted; bool get isCompleted; String? get errorMessage;
/// Create a copy of DesktopOnboardingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesktopOnboardingStateCopyWith<DesktopOnboardingState> get copyWith => _$DesktopOnboardingStateCopyWithImpl<DesktopOnboardingState>(this as DesktopOnboardingState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DesktopOnboardingState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesktopOnboardingState&&(identical(other.isLoading, _this.isLoading) || other.isLoading == _this.isLoading)&&const DeepCollectionEquality().equals(other.capabilities, _this.capabilities)&&(identical(other.isAllRequiredGranted, _this.isAllRequiredGranted) || other.isAllRequiredGranted == _this.isAllRequiredGranted)&&(identical(other.isCompleted, _this.isCompleted) || other.isCompleted == _this.isCompleted)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage));
}


@override
int get hashCode {
  final _this = this as DesktopOnboardingState;
  return Object.hash(runtimeType,_this.isLoading,const DeepCollectionEquality().hash(_this.capabilities),_this.isAllRequiredGranted,_this.isCompleted,_this.errorMessage);
}

@override
String toString() {
  final _this = this as DesktopOnboardingState;
  return 'DesktopOnboardingState(isLoading: ${_this.isLoading}, capabilities: ${_this.capabilities}, isAllRequiredGranted: ${_this.isAllRequiredGranted}, isCompleted: ${_this.isCompleted}, errorMessage: ${_this.errorMessage})';
}


}

/// @nodoc
abstract mixin class $DesktopOnboardingStateCopyWith<$Res>  {
  factory $DesktopOnboardingStateCopyWith(DesktopOnboardingState value, $Res Function(DesktopOnboardingState) _then) = _$DesktopOnboardingStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, List<DesktopCapability> capabilities, bool isAllRequiredGranted, bool isCompleted, String? errorMessage
});




}
/// @nodoc
class _$DesktopOnboardingStateCopyWithImpl<$Res>
    implements $DesktopOnboardingStateCopyWith<$Res> {
  _$DesktopOnboardingStateCopyWithImpl(this._self, this._then);

  final DesktopOnboardingState _self;
  final $Res Function(DesktopOnboardingState) _then;

/// Create a copy of DesktopOnboardingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? capabilities = null,Object? isAllRequiredGranted = null,Object? isCompleted = null,Object? errorMessage = freezed,}) {
  return _then(DesktopOnboardingState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,capabilities: null == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as List<DesktopCapability>,isAllRequiredGranted: null == isAllRequiredGranted ? _self.isAllRequiredGranted : isAllRequiredGranted // ignore: cast_nullable_to_non_nullable
as bool,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DesktopOnboardingState].
extension DesktopOnboardingStatePatterns on DesktopOnboardingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesktopOnboardingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesktopOnboardingState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesktopOnboardingState value)  $default,){
final _that = this;
switch (_that) {
case _DesktopOnboardingState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesktopOnboardingState value)?  $default,){
final _that = this;
switch (_that) {
case _DesktopOnboardingState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  List<DesktopCapability> capabilities,  bool isAllRequiredGranted,  bool isCompleted,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesktopOnboardingState() when $default != null:
return $default(_that.isLoading,_that.capabilities,_that.isAllRequiredGranted,_that.isCompleted,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  List<DesktopCapability> capabilities,  bool isAllRequiredGranted,  bool isCompleted,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _DesktopOnboardingState():
return $default(_that.isLoading,_that.capabilities,_that.isAllRequiredGranted,_that.isCompleted,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  List<DesktopCapability> capabilities,  bool isAllRequiredGranted,  bool isCompleted,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _DesktopOnboardingState() when $default != null:
return $default(_that.isLoading,_that.capabilities,_that.isAllRequiredGranted,_that.isCompleted,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _DesktopOnboardingState implements DesktopOnboardingState {
  const _DesktopOnboardingState({this.isLoading = false,  List<DesktopCapability> capabilities = const [], this.isAllRequiredGranted = false, this.isCompleted = false, this.errorMessage}): _capabilities = capabilities;
  

@override@JsonKey() final  bool isLoading;
 final  List<DesktopCapability> _capabilities;
@override@JsonKey() List<DesktopCapability> get capabilities {
  if (_capabilities is EqualUnmodifiableListView) return _capabilities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_capabilities);
}

@override@JsonKey() final  bool isAllRequiredGranted;
@override@JsonKey() final  bool isCompleted;
@override final  String? errorMessage;

/// Create a copy of DesktopOnboardingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesktopOnboardingStateCopyWith<_DesktopOnboardingState> get copyWith => __$DesktopOnboardingStateCopyWithImpl<_DesktopOnboardingState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesktopOnboardingState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other.capabilities, _capabilities)&&(identical(other.isAllRequiredGranted, isAllRequiredGranted) || other.isAllRequiredGranted == isAllRequiredGranted)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,isLoading,const DeepCollectionEquality().hash(_capabilities),isAllRequiredGranted,isCompleted,errorMessage);
}

@override
String toString() {
    return 'DesktopOnboardingState(isLoading: $isLoading, capabilities: $capabilities, isAllRequiredGranted: $isAllRequiredGranted, isCompleted: $isCompleted, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$DesktopOnboardingStateCopyWith<$Res> implements $DesktopOnboardingStateCopyWith<$Res> {
  factory _$DesktopOnboardingStateCopyWith(_DesktopOnboardingState value, $Res Function(_DesktopOnboardingState) _then) = __$DesktopOnboardingStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, List<DesktopCapability> capabilities, bool isAllRequiredGranted, bool isCompleted, String? errorMessage
});




}
/// @nodoc
class __$DesktopOnboardingStateCopyWithImpl<$Res>
    implements _$DesktopOnboardingStateCopyWith<$Res> {
  __$DesktopOnboardingStateCopyWithImpl(this._self, this._then);

  final _DesktopOnboardingState _self;
  final $Res Function(_DesktopOnboardingState) _then;

/// Create a copy of DesktopOnboardingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? capabilities = null,Object? isAllRequiredGranted = null,Object? isCompleted = null,Object? errorMessage = freezed,}) {
  return _then(_DesktopOnboardingState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,capabilities: null == capabilities ? _self._capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as List<DesktopCapability>,isAllRequiredGranted: null == isAllRequiredGranted ? _self.isAllRequiredGranted : isAllRequiredGranted // ignore: cast_nullable_to_non_nullable
as bool,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
