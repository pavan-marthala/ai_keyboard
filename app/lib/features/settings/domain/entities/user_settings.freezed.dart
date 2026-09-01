// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserSettings {

 AiProviderType get activeProvider; String get activeModelId; String? get customBaseUrl; bool get hapticFeedbackEnabled; bool get soundEffectsEnabled;
/// Create a copy of UserSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserSettingsCopyWith<UserSettings> get copyWith => _$UserSettingsCopyWithImpl<UserSettings>(this as UserSettings, _$identity);

  /// Serializes this UserSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UserSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserSettings&&(identical(other.activeProvider, _this.activeProvider) || other.activeProvider == _this.activeProvider)&&(identical(other.activeModelId, _this.activeModelId) || other.activeModelId == _this.activeModelId)&&(identical(other.customBaseUrl, _this.customBaseUrl) || other.customBaseUrl == _this.customBaseUrl)&&(identical(other.hapticFeedbackEnabled, _this.hapticFeedbackEnabled) || other.hapticFeedbackEnabled == _this.hapticFeedbackEnabled)&&(identical(other.soundEffectsEnabled, _this.soundEffectsEnabled) || other.soundEffectsEnabled == _this.soundEffectsEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UserSettings;
  return Object.hash(runtimeType,_this.activeProvider,_this.activeModelId,_this.customBaseUrl,_this.hapticFeedbackEnabled,_this.soundEffectsEnabled);
}

@override
String toString() {
  final _this = this as UserSettings;
  return 'UserSettings(activeProvider: ${_this.activeProvider}, activeModelId: ${_this.activeModelId}, customBaseUrl: ${_this.customBaseUrl}, hapticFeedbackEnabled: ${_this.hapticFeedbackEnabled}, soundEffectsEnabled: ${_this.soundEffectsEnabled})';
}


}

/// @nodoc
abstract mixin class $UserSettingsCopyWith<$Res>  {
  factory $UserSettingsCopyWith(UserSettings value, $Res Function(UserSettings) _then) = _$UserSettingsCopyWithImpl;
@useResult
$Res call({
 AiProviderType activeProvider, String activeModelId, String? customBaseUrl, bool hapticFeedbackEnabled, bool soundEffectsEnabled
});




}
/// @nodoc
class _$UserSettingsCopyWithImpl<$Res>
    implements $UserSettingsCopyWith<$Res> {
  _$UserSettingsCopyWithImpl(this._self, this._then);

  final UserSettings _self;
  final $Res Function(UserSettings) _then;

/// Create a copy of UserSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activeProvider = null,Object? activeModelId = null,Object? customBaseUrl = freezed,Object? hapticFeedbackEnabled = null,Object? soundEffectsEnabled = null,}) {
  return _then(UserSettings(
activeProvider: null == activeProvider ? _self.activeProvider : activeProvider // ignore: cast_nullable_to_non_nullable
as AiProviderType,activeModelId: null == activeModelId ? _self.activeModelId : activeModelId // ignore: cast_nullable_to_non_nullable
as String,customBaseUrl: freezed == customBaseUrl ? _self.customBaseUrl : customBaseUrl // ignore: cast_nullable_to_non_nullable
as String?,hapticFeedbackEnabled: null == hapticFeedbackEnabled ? _self.hapticFeedbackEnabled : hapticFeedbackEnabled // ignore: cast_nullable_to_non_nullable
as bool,soundEffectsEnabled: null == soundEffectsEnabled ? _self.soundEffectsEnabled : soundEffectsEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserSettings].
extension UserSettingsPatterns on UserSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserSettings value)  $default,){
final _that = this;
switch (_that) {
case _UserSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserSettings value)?  $default,){
final _that = this;
switch (_that) {
case _UserSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AiProviderType activeProvider,  String activeModelId,  String? customBaseUrl,  bool hapticFeedbackEnabled,  bool soundEffectsEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserSettings() when $default != null:
return $default(_that.activeProvider,_that.activeModelId,_that.customBaseUrl,_that.hapticFeedbackEnabled,_that.soundEffectsEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AiProviderType activeProvider,  String activeModelId,  String? customBaseUrl,  bool hapticFeedbackEnabled,  bool soundEffectsEnabled)  $default,) {final _that = this;
switch (_that) {
case _UserSettings():
return $default(_that.activeProvider,_that.activeModelId,_that.customBaseUrl,_that.hapticFeedbackEnabled,_that.soundEffectsEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AiProviderType activeProvider,  String activeModelId,  String? customBaseUrl,  bool hapticFeedbackEnabled,  bool soundEffectsEnabled)?  $default,) {final _that = this;
switch (_that) {
case _UserSettings() when $default != null:
return $default(_that.activeProvider,_that.activeModelId,_that.customBaseUrl,_that.hapticFeedbackEnabled,_that.soundEffectsEnabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserSettings implements UserSettings {
  const _UserSettings({this.activeProvider = AiProviderType.openAi, this.activeModelId = 'gpt-4o-mini', this.customBaseUrl, this.hapticFeedbackEnabled = true, this.soundEffectsEnabled = true});
  factory _UserSettings.fromJson(Map<String, dynamic> json) => _$UserSettingsFromJson(json);

@override@JsonKey() final  AiProviderType activeProvider;
@override@JsonKey() final  String activeModelId;
@override final  String? customBaseUrl;
@override@JsonKey() final  bool hapticFeedbackEnabled;
@override@JsonKey() final  bool soundEffectsEnabled;

/// Create a copy of UserSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserSettingsCopyWith<_UserSettings> get copyWith => __$UserSettingsCopyWithImpl<_UserSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserSettings&&(identical(other.activeProvider, activeProvider) || other.activeProvider == activeProvider)&&(identical(other.activeModelId, activeModelId) || other.activeModelId == activeModelId)&&(identical(other.customBaseUrl, customBaseUrl) || other.customBaseUrl == customBaseUrl)&&(identical(other.hapticFeedbackEnabled, hapticFeedbackEnabled) || other.hapticFeedbackEnabled == hapticFeedbackEnabled)&&(identical(other.soundEffectsEnabled, soundEffectsEnabled) || other.soundEffectsEnabled == soundEffectsEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,activeProvider,activeModelId,customBaseUrl,hapticFeedbackEnabled,soundEffectsEnabled);
}

@override
String toString() {
    return 'UserSettings(activeProvider: $activeProvider, activeModelId: $activeModelId, customBaseUrl: $customBaseUrl, hapticFeedbackEnabled: $hapticFeedbackEnabled, soundEffectsEnabled: $soundEffectsEnabled)';
}


}

/// @nodoc
abstract mixin class _$UserSettingsCopyWith<$Res> implements $UserSettingsCopyWith<$Res> {
  factory _$UserSettingsCopyWith(_UserSettings value, $Res Function(_UserSettings) _then) = __$UserSettingsCopyWithImpl;
@override @useResult
$Res call({
 AiProviderType activeProvider, String activeModelId, String? customBaseUrl, bool hapticFeedbackEnabled, bool soundEffectsEnabled
});




}
/// @nodoc
class __$UserSettingsCopyWithImpl<$Res>
    implements _$UserSettingsCopyWith<$Res> {
  __$UserSettingsCopyWithImpl(this._self, this._then);

  final _UserSettings _self;
  final $Res Function(_UserSettings) _then;

/// Create a copy of UserSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activeProvider = null,Object? activeModelId = null,Object? customBaseUrl = freezed,Object? hapticFeedbackEnabled = null,Object? soundEffectsEnabled = null,}) {
  return _then(_UserSettings(
activeProvider: null == activeProvider ? _self.activeProvider : activeProvider // ignore: cast_nullable_to_non_nullable
as AiProviderType,activeModelId: null == activeModelId ? _self.activeModelId : activeModelId // ignore: cast_nullable_to_non_nullable
as String,customBaseUrl: freezed == customBaseUrl ? _self.customBaseUrl : customBaseUrl // ignore: cast_nullable_to_non_nullable
as String?,hapticFeedbackEnabled: null == hapticFeedbackEnabled ? _self.hapticFeedbackEnabled : hapticFeedbackEnabled // ignore: cast_nullable_to_non_nullable
as bool,soundEffectsEnabled: null == soundEffectsEnabled ? _self.soundEffectsEnabled : soundEffectsEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
