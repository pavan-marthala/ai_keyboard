// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettingsState {

 UserSettings get settings; bool get isLoading; Map<AiProviderType, bool> get hasApiKeyMap; Map<AiProviderType, List<AiModel>> get modelsMap; bool get isFetchingModels; Failure? get modelsError; Failure? get failure;
/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsStateCopyWith<SettingsState> get copyWith => _$SettingsStateCopyWithImpl<SettingsState>(this as SettingsState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SettingsState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsState&&(identical(other.settings, _this.settings) || other.settings == _this.settings)&&(identical(other.isLoading, _this.isLoading) || other.isLoading == _this.isLoading)&&const DeepCollectionEquality().equals(other.hasApiKeyMap, _this.hasApiKeyMap)&&const DeepCollectionEquality().equals(other.modelsMap, _this.modelsMap)&&(identical(other.isFetchingModels, _this.isFetchingModels) || other.isFetchingModels == _this.isFetchingModels)&&(identical(other.modelsError, _this.modelsError) || other.modelsError == _this.modelsError)&&(identical(other.failure, _this.failure) || other.failure == _this.failure));
}


@override
int get hashCode {
  final _this = this as SettingsState;
  return Object.hash(runtimeType,_this.settings,_this.isLoading,const DeepCollectionEquality().hash(_this.hasApiKeyMap),const DeepCollectionEquality().hash(_this.modelsMap),_this.isFetchingModels,_this.modelsError,_this.failure);
}

@override
String toString() {
  final _this = this as SettingsState;
  return 'SettingsState(settings: ${_this.settings}, isLoading: ${_this.isLoading}, hasApiKeyMap: ${_this.hasApiKeyMap}, modelsMap: ${_this.modelsMap}, isFetchingModels: ${_this.isFetchingModels}, modelsError: ${_this.modelsError}, failure: ${_this.failure})';
}


}

/// @nodoc
abstract mixin class $SettingsStateCopyWith<$Res>  {
  factory $SettingsStateCopyWith(SettingsState value, $Res Function(SettingsState) _then) = _$SettingsStateCopyWithImpl;
@useResult
$Res call({
 UserSettings settings, bool isLoading, Map<AiProviderType, bool> hasApiKeyMap, Map<AiProviderType, List<AiModel>> modelsMap, bool isFetchingModels, Failure? modelsError, Failure? failure
});


$UserSettingsCopyWith<$Res> get settings;$FailureCopyWith<$Res>? get modelsError;$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$SettingsStateCopyWithImpl<$Res>
    implements $SettingsStateCopyWith<$Res> {
  _$SettingsStateCopyWithImpl(this._self, this._then);

  final SettingsState _self;
  final $Res Function(SettingsState) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? settings = null,Object? isLoading = null,Object? hasApiKeyMap = null,Object? modelsMap = null,Object? isFetchingModels = null,Object? modelsError = freezed,Object? failure = freezed,}) {
  return _then(SettingsState(
settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as UserSettings,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,hasApiKeyMap: null == hasApiKeyMap ? _self.hasApiKeyMap : hasApiKeyMap // ignore: cast_nullable_to_non_nullable
as Map<AiProviderType, bool>,modelsMap: null == modelsMap ? _self.modelsMap : modelsMap // ignore: cast_nullable_to_non_nullable
as Map<AiProviderType, List<AiModel>>,isFetchingModels: null == isFetchingModels ? _self.isFetchingModels : isFetchingModels // ignore: cast_nullable_to_non_nullable
as bool,modelsError: freezed == modelsError ? _self.modelsError : modelsError // ignore: cast_nullable_to_non_nullable
as Failure?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}
/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSettingsCopyWith<$Res> get settings {
  
  return $UserSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get modelsError {
    if (_self.modelsError == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.modelsError!, (value) {
    return _then(_self.copyWith(modelsError: value));
  });
}/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}


/// Adds pattern-matching-related methods to [SettingsState].
extension SettingsStatePatterns on SettingsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettingsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettingsState value)  $default,){
final _that = this;
switch (_that) {
case _SettingsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettingsState value)?  $default,){
final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UserSettings settings,  bool isLoading,  Map<AiProviderType, bool> hasApiKeyMap,  Map<AiProviderType, List<AiModel>> modelsMap,  bool isFetchingModels,  Failure? modelsError,  Failure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
return $default(_that.settings,_that.isLoading,_that.hasApiKeyMap,_that.modelsMap,_that.isFetchingModels,_that.modelsError,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UserSettings settings,  bool isLoading,  Map<AiProviderType, bool> hasApiKeyMap,  Map<AiProviderType, List<AiModel>> modelsMap,  bool isFetchingModels,  Failure? modelsError,  Failure? failure)  $default,) {final _that = this;
switch (_that) {
case _SettingsState():
return $default(_that.settings,_that.isLoading,_that.hasApiKeyMap,_that.modelsMap,_that.isFetchingModels,_that.modelsError,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UserSettings settings,  bool isLoading,  Map<AiProviderType, bool> hasApiKeyMap,  Map<AiProviderType, List<AiModel>> modelsMap,  bool isFetchingModels,  Failure? modelsError,  Failure? failure)?  $default,) {final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
return $default(_that.settings,_that.isLoading,_that.hasApiKeyMap,_that.modelsMap,_that.isFetchingModels,_that.modelsError,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _SettingsState implements SettingsState {
  const _SettingsState({this.settings = const UserSettings(), this.isLoading = false,  Map<AiProviderType, bool> hasApiKeyMap = const {},  Map<AiProviderType, List<AiModel>> modelsMap = const {}, this.isFetchingModels = false, this.modelsError, this.failure}): _hasApiKeyMap = hasApiKeyMap,_modelsMap = modelsMap;
  

@override@JsonKey() final  UserSettings settings;
@override@JsonKey() final  bool isLoading;
 final  Map<AiProviderType, bool> _hasApiKeyMap;
@override@JsonKey() Map<AiProviderType, bool> get hasApiKeyMap {
  if (_hasApiKeyMap is EqualUnmodifiableMapView) return _hasApiKeyMap;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_hasApiKeyMap);
}

 final  Map<AiProviderType, List<AiModel>> _modelsMap;
@override@JsonKey() Map<AiProviderType, List<AiModel>> get modelsMap {
  if (_modelsMap is EqualUnmodifiableMapView) return _modelsMap;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_modelsMap);
}

@override@JsonKey() final  bool isFetchingModels;
@override final  Failure? modelsError;
@override final  Failure? failure;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsStateCopyWith<_SettingsState> get copyWith => __$SettingsStateCopyWithImpl<_SettingsState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettingsState&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other.hasApiKeyMap, _hasApiKeyMap)&&const DeepCollectionEquality().equals(other.modelsMap, _modelsMap)&&(identical(other.isFetchingModels, isFetchingModels) || other.isFetchingModels == isFetchingModels)&&(identical(other.modelsError, modelsError) || other.modelsError == modelsError)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,settings,isLoading,const DeepCollectionEquality().hash(_hasApiKeyMap),const DeepCollectionEquality().hash(_modelsMap),isFetchingModels,modelsError,failure);
}

@override
String toString() {
    return 'SettingsState(settings: $settings, isLoading: $isLoading, hasApiKeyMap: $hasApiKeyMap, modelsMap: $modelsMap, isFetchingModels: $isFetchingModels, modelsError: $modelsError, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$SettingsStateCopyWith<$Res> implements $SettingsStateCopyWith<$Res> {
  factory _$SettingsStateCopyWith(_SettingsState value, $Res Function(_SettingsState) _then) = __$SettingsStateCopyWithImpl;
@override @useResult
$Res call({
 UserSettings settings, bool isLoading, Map<AiProviderType, bool> hasApiKeyMap, Map<AiProviderType, List<AiModel>> modelsMap, bool isFetchingModels, Failure? modelsError, Failure? failure
});


@override $UserSettingsCopyWith<$Res> get settings;@override $FailureCopyWith<$Res>? get modelsError;@override $FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$SettingsStateCopyWithImpl<$Res>
    implements _$SettingsStateCopyWith<$Res> {
  __$SettingsStateCopyWithImpl(this._self, this._then);

  final _SettingsState _self;
  final $Res Function(_SettingsState) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? settings = null,Object? isLoading = null,Object? hasApiKeyMap = null,Object? modelsMap = null,Object? isFetchingModels = null,Object? modelsError = freezed,Object? failure = freezed,}) {
  return _then(_SettingsState(
settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as UserSettings,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,hasApiKeyMap: null == hasApiKeyMap ? _self._hasApiKeyMap : hasApiKeyMap // ignore: cast_nullable_to_non_nullable
as Map<AiProviderType, bool>,modelsMap: null == modelsMap ? _self._modelsMap : modelsMap // ignore: cast_nullable_to_non_nullable
as Map<AiProviderType, List<AiModel>>,isFetchingModels: null == isFetchingModels ? _self.isFetchingModels : isFetchingModels // ignore: cast_nullable_to_non_nullable
as bool,modelsError: freezed == modelsError ? _self.modelsError : modelsError // ignore: cast_nullable_to_non_nullable
as Failure?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSettingsCopyWith<$Res> get settings {
  
  return $UserSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get modelsError {
    if (_self.modelsError == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.modelsError!, (value) {
    return _then(_self.copyWith(modelsError: value));
  });
}/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
