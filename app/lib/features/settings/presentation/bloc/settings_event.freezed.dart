// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettingsEvent {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SettingsEvent()';
}


}

/// @nodoc
class $SettingsEventCopyWith<$Res>  {
$SettingsEventCopyWith(SettingsEvent _, $Res Function(SettingsEvent) __);
}


/// Adds pattern-matching-related methods to [SettingsEvent].
extension SettingsEventPatterns on SettingsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _LoadSettings value)?  loadSettings,TResult Function( _UpdateSettings value)?  updateSettings,TResult Function( _SaveApiKey value)?  saveApiKey,TResult Function( _DeleteApiKey value)?  deleteApiKey,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoadSettings() when loadSettings != null:
return loadSettings(_that);case _UpdateSettings() when updateSettings != null:
return updateSettings(_that);case _SaveApiKey() when saveApiKey != null:
return saveApiKey(_that);case _DeleteApiKey() when deleteApiKey != null:
return deleteApiKey(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _LoadSettings value)  loadSettings,required TResult Function( _UpdateSettings value)  updateSettings,required TResult Function( _SaveApiKey value)  saveApiKey,required TResult Function( _DeleteApiKey value)  deleteApiKey,}){
final _that = this;
switch (_that) {
case _LoadSettings():
return loadSettings(_that);case _UpdateSettings():
return updateSettings(_that);case _SaveApiKey():
return saveApiKey(_that);case _DeleteApiKey():
return deleteApiKey(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _LoadSettings value)?  loadSettings,TResult? Function( _UpdateSettings value)?  updateSettings,TResult? Function( _SaveApiKey value)?  saveApiKey,TResult? Function( _DeleteApiKey value)?  deleteApiKey,}){
final _that = this;
switch (_that) {
case _LoadSettings() when loadSettings != null:
return loadSettings(_that);case _UpdateSettings() when updateSettings != null:
return updateSettings(_that);case _SaveApiKey() when saveApiKey != null:
return saveApiKey(_that);case _DeleteApiKey() when deleteApiKey != null:
return deleteApiKey(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadSettings,TResult Function( UserSettings settings)?  updateSettings,TResult Function( AiProviderType provider,  String apiKey)?  saveApiKey,TResult Function( AiProviderType provider)?  deleteApiKey,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoadSettings() when loadSettings != null:
return loadSettings();case _UpdateSettings() when updateSettings != null:
return updateSettings(_that.settings);case _SaveApiKey() when saveApiKey != null:
return saveApiKey(_that.provider,_that.apiKey);case _DeleteApiKey() when deleteApiKey != null:
return deleteApiKey(_that.provider);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadSettings,required TResult Function( UserSettings settings)  updateSettings,required TResult Function( AiProviderType provider,  String apiKey)  saveApiKey,required TResult Function( AiProviderType provider)  deleteApiKey,}) {final _that = this;
switch (_that) {
case _LoadSettings():
return loadSettings();case _UpdateSettings():
return updateSettings(_that.settings);case _SaveApiKey():
return saveApiKey(_that.provider,_that.apiKey);case _DeleteApiKey():
return deleteApiKey(_that.provider);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadSettings,TResult? Function( UserSettings settings)?  updateSettings,TResult? Function( AiProviderType provider,  String apiKey)?  saveApiKey,TResult? Function( AiProviderType provider)?  deleteApiKey,}) {final _that = this;
switch (_that) {
case _LoadSettings() when loadSettings != null:
return loadSettings();case _UpdateSettings() when updateSettings != null:
return updateSettings(_that.settings);case _SaveApiKey() when saveApiKey != null:
return saveApiKey(_that.provider,_that.apiKey);case _DeleteApiKey() when deleteApiKey != null:
return deleteApiKey(_that.provider);case _:
  return null;

}
}

}

/// @nodoc


class _LoadSettings implements SettingsEvent {
  const _LoadSettings();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadSettings);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SettingsEvent.loadSettings()';
}


}




/// @nodoc


class _UpdateSettings implements SettingsEvent {
  const _UpdateSettings(this.settings);
  

 final  UserSettings settings;

/// Create a copy of SettingsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateSettingsCopyWith<_UpdateSettings> get copyWith => __$UpdateSettingsCopyWithImpl<_UpdateSettings>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateSettings&&(identical(other.settings, settings) || other.settings == settings));
}


@override
int get hashCode {
    return Object.hash(runtimeType,settings);
}

@override
String toString() {
    return 'SettingsEvent.updateSettings(settings: $settings)';
}


}

/// @nodoc
abstract mixin class _$UpdateSettingsCopyWith<$Res> implements $SettingsEventCopyWith<$Res> {
  factory _$UpdateSettingsCopyWith(_UpdateSettings value, $Res Function(_UpdateSettings) _then) = __$UpdateSettingsCopyWithImpl;
@useResult
$Res call({
 UserSettings settings
});


$UserSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class __$UpdateSettingsCopyWithImpl<$Res>
    implements _$UpdateSettingsCopyWith<$Res> {
  __$UpdateSettingsCopyWithImpl(this._self, this._then);

  final _UpdateSettings _self;
  final $Res Function(_UpdateSettings) _then;

/// Create a copy of SettingsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? settings = null,}) {
  return _then(_UpdateSettings(
null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as UserSettings,
  ));
}

/// Create a copy of SettingsEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSettingsCopyWith<$Res> get settings {
  
  return $UserSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}

/// @nodoc


class _SaveApiKey implements SettingsEvent {
  const _SaveApiKey({required this.provider, required this.apiKey});
  

 final  AiProviderType provider;
 final  String apiKey;

/// Create a copy of SettingsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SaveApiKeyCopyWith<_SaveApiKey> get copyWith => __$SaveApiKeyCopyWithImpl<_SaveApiKey>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SaveApiKey&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.apiKey, apiKey) || other.apiKey == apiKey));
}


@override
int get hashCode {
    return Object.hash(runtimeType,provider,apiKey);
}

@override
String toString() {
    return 'SettingsEvent.saveApiKey(provider: $provider, apiKey: $apiKey)';
}


}

/// @nodoc
abstract mixin class _$SaveApiKeyCopyWith<$Res> implements $SettingsEventCopyWith<$Res> {
  factory _$SaveApiKeyCopyWith(_SaveApiKey value, $Res Function(_SaveApiKey) _then) = __$SaveApiKeyCopyWithImpl;
@useResult
$Res call({
 AiProviderType provider, String apiKey
});




}
/// @nodoc
class __$SaveApiKeyCopyWithImpl<$Res>
    implements _$SaveApiKeyCopyWith<$Res> {
  __$SaveApiKeyCopyWithImpl(this._self, this._then);

  final _SaveApiKey _self;
  final $Res Function(_SaveApiKey) _then;

/// Create a copy of SettingsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? provider = null,Object? apiKey = null,}) {
  return _then(_SaveApiKey(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as AiProviderType,apiKey: null == apiKey ? _self.apiKey : apiKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _DeleteApiKey implements SettingsEvent {
  const _DeleteApiKey({required this.provider});
  

 final  AiProviderType provider;

/// Create a copy of SettingsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeleteApiKeyCopyWith<_DeleteApiKey> get copyWith => __$DeleteApiKeyCopyWithImpl<_DeleteApiKey>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeleteApiKey&&(identical(other.provider, provider) || other.provider == provider));
}


@override
int get hashCode {
    return Object.hash(runtimeType,provider);
}

@override
String toString() {
    return 'SettingsEvent.deleteApiKey(provider: $provider)';
}


}

/// @nodoc
abstract mixin class _$DeleteApiKeyCopyWith<$Res> implements $SettingsEventCopyWith<$Res> {
  factory _$DeleteApiKeyCopyWith(_DeleteApiKey value, $Res Function(_DeleteApiKey) _then) = __$DeleteApiKeyCopyWithImpl;
@useResult
$Res call({
 AiProviderType provider
});




}
/// @nodoc
class __$DeleteApiKeyCopyWithImpl<$Res>
    implements _$DeleteApiKeyCopyWith<$Res> {
  __$DeleteApiKeyCopyWithImpl(this._self, this._then);

  final _DeleteApiKey _self;
  final $Res Function(_DeleteApiKey) _then;

/// Create a copy of SettingsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? provider = null,}) {
  return _then(_DeleteApiKey(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as AiProviderType,
  ));
}


}

// dart format on
