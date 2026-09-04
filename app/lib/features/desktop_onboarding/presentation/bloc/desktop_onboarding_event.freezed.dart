// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'desktop_onboarding_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DesktopOnboardingEvent {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DesktopOnboardingEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DesktopOnboardingEvent()';
}


}

/// @nodoc
class $DesktopOnboardingEventCopyWith<$Res>  {
$DesktopOnboardingEventCopyWith(DesktopOnboardingEvent _, $Res Function(DesktopOnboardingEvent) __);
}


/// Adds pattern-matching-related methods to [DesktopOnboardingEvent].
extension DesktopOnboardingEventPatterns on DesktopOnboardingEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _CheckCapabilities value)?  checkCapabilities,TResult Function( _RequestCapability value)?  requestCapability,TResult Function( _OpenSettings value)?  openSettings,TResult Function( _CompleteOnboarding value)?  completeOnboarding,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckCapabilities() when checkCapabilities != null:
return checkCapabilities(_that);case _RequestCapability() when requestCapability != null:
return requestCapability(_that);case _OpenSettings() when openSettings != null:
return openSettings(_that);case _CompleteOnboarding() when completeOnboarding != null:
return completeOnboarding(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _CheckCapabilities value)  checkCapabilities,required TResult Function( _RequestCapability value)  requestCapability,required TResult Function( _OpenSettings value)  openSettings,required TResult Function( _CompleteOnboarding value)  completeOnboarding,}){
final _that = this;
switch (_that) {
case _CheckCapabilities():
return checkCapabilities(_that);case _RequestCapability():
return requestCapability(_that);case _OpenSettings():
return openSettings(_that);case _CompleteOnboarding():
return completeOnboarding(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _CheckCapabilities value)?  checkCapabilities,TResult? Function( _RequestCapability value)?  requestCapability,TResult? Function( _OpenSettings value)?  openSettings,TResult? Function( _CompleteOnboarding value)?  completeOnboarding,}){
final _that = this;
switch (_that) {
case _CheckCapabilities() when checkCapabilities != null:
return checkCapabilities(_that);case _RequestCapability() when requestCapability != null:
return requestCapability(_that);case _OpenSettings() when openSettings != null:
return openSettings(_that);case _CompleteOnboarding() when completeOnboarding != null:
return completeOnboarding(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  checkCapabilities,TResult Function( DesktopCapabilityType type)?  requestCapability,TResult Function( DesktopCapabilityType type)?  openSettings,TResult Function()?  completeOnboarding,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckCapabilities() when checkCapabilities != null:
return checkCapabilities();case _RequestCapability() when requestCapability != null:
return requestCapability(_that.type);case _OpenSettings() when openSettings != null:
return openSettings(_that.type);case _CompleteOnboarding() when completeOnboarding != null:
return completeOnboarding();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  checkCapabilities,required TResult Function( DesktopCapabilityType type)  requestCapability,required TResult Function( DesktopCapabilityType type)  openSettings,required TResult Function()  completeOnboarding,}) {final _that = this;
switch (_that) {
case _CheckCapabilities():
return checkCapabilities();case _RequestCapability():
return requestCapability(_that.type);case _OpenSettings():
return openSettings(_that.type);case _CompleteOnboarding():
return completeOnboarding();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  checkCapabilities,TResult? Function( DesktopCapabilityType type)?  requestCapability,TResult? Function( DesktopCapabilityType type)?  openSettings,TResult? Function()?  completeOnboarding,}) {final _that = this;
switch (_that) {
case _CheckCapabilities() when checkCapabilities != null:
return checkCapabilities();case _RequestCapability() when requestCapability != null:
return requestCapability(_that.type);case _OpenSettings() when openSettings != null:
return openSettings(_that.type);case _CompleteOnboarding() when completeOnboarding != null:
return completeOnboarding();case _:
  return null;

}
}

}

/// @nodoc


class _CheckCapabilities implements DesktopOnboardingEvent {
  const _CheckCapabilities();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckCapabilities);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DesktopOnboardingEvent.checkCapabilities()';
}


}




/// @nodoc


class _RequestCapability implements DesktopOnboardingEvent {
  const _RequestCapability(this.type);
  

 final  DesktopCapabilityType type;

/// Create a copy of DesktopOnboardingEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RequestCapabilityCopyWith<_RequestCapability> get copyWith => __$RequestCapabilityCopyWithImpl<_RequestCapability>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RequestCapability&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode {
    return Object.hash(runtimeType,type);
}

@override
String toString() {
    return 'DesktopOnboardingEvent.requestCapability(type: $type)';
}


}

/// @nodoc
abstract mixin class _$RequestCapabilityCopyWith<$Res> implements $DesktopOnboardingEventCopyWith<$Res> {
  factory _$RequestCapabilityCopyWith(_RequestCapability value, $Res Function(_RequestCapability) _then) = __$RequestCapabilityCopyWithImpl;
@useResult
$Res call({
 DesktopCapabilityType type
});




}
/// @nodoc
class __$RequestCapabilityCopyWithImpl<$Res>
    implements _$RequestCapabilityCopyWith<$Res> {
  __$RequestCapabilityCopyWithImpl(this._self, this._then);

  final _RequestCapability _self;
  final $Res Function(_RequestCapability) _then;

/// Create a copy of DesktopOnboardingEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? type = null,}) {
  return _then(_RequestCapability(
null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DesktopCapabilityType,
  ));
}


}

/// @nodoc


class _OpenSettings implements DesktopOnboardingEvent {
  const _OpenSettings(this.type);
  

 final  DesktopCapabilityType type;

/// Create a copy of DesktopOnboardingEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenSettingsCopyWith<_OpenSettings> get copyWith => __$OpenSettingsCopyWithImpl<_OpenSettings>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenSettings&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode {
    return Object.hash(runtimeType,type);
}

@override
String toString() {
    return 'DesktopOnboardingEvent.openSettings(type: $type)';
}


}

/// @nodoc
abstract mixin class _$OpenSettingsCopyWith<$Res> implements $DesktopOnboardingEventCopyWith<$Res> {
  factory _$OpenSettingsCopyWith(_OpenSettings value, $Res Function(_OpenSettings) _then) = __$OpenSettingsCopyWithImpl;
@useResult
$Res call({
 DesktopCapabilityType type
});




}
/// @nodoc
class __$OpenSettingsCopyWithImpl<$Res>
    implements _$OpenSettingsCopyWith<$Res> {
  __$OpenSettingsCopyWithImpl(this._self, this._then);

  final _OpenSettings _self;
  final $Res Function(_OpenSettings) _then;

/// Create a copy of DesktopOnboardingEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? type = null,}) {
  return _then(_OpenSettings(
null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DesktopCapabilityType,
  ));
}


}

/// @nodoc


class _CompleteOnboarding implements DesktopOnboardingEvent {
  const _CompleteOnboarding();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompleteOnboarding);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DesktopOnboardingEvent.completeOnboarding()';
}


}




// dart format on
