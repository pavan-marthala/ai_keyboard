// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_provider_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AiProviderConfig {

 AiProviderType get provider; String get modelId; String? get baseUrl;
/// Create a copy of AiProviderConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiProviderConfigCopyWith<AiProviderConfig> get copyWith => _$AiProviderConfigCopyWithImpl<AiProviderConfig>(this as AiProviderConfig, _$identity);

  /// Serializes this AiProviderConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AiProviderConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiProviderConfig&&(identical(other.provider, _this.provider) || other.provider == _this.provider)&&(identical(other.modelId, _this.modelId) || other.modelId == _this.modelId)&&(identical(other.baseUrl, _this.baseUrl) || other.baseUrl == _this.baseUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AiProviderConfig;
  return Object.hash(runtimeType,_this.provider,_this.modelId,_this.baseUrl);
}

@override
String toString() {
  final _this = this as AiProviderConfig;
  return 'AiProviderConfig(provider: ${_this.provider}, modelId: ${_this.modelId}, baseUrl: ${_this.baseUrl})';
}


}

/// @nodoc
abstract mixin class $AiProviderConfigCopyWith<$Res>  {
  factory $AiProviderConfigCopyWith(AiProviderConfig value, $Res Function(AiProviderConfig) _then) = _$AiProviderConfigCopyWithImpl;
@useResult
$Res call({
 AiProviderType provider, String modelId, String? baseUrl
});




}
/// @nodoc
class _$AiProviderConfigCopyWithImpl<$Res>
    implements $AiProviderConfigCopyWith<$Res> {
  _$AiProviderConfigCopyWithImpl(this._self, this._then);

  final AiProviderConfig _self;
  final $Res Function(AiProviderConfig) _then;

/// Create a copy of AiProviderConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? provider = null,Object? modelId = null,Object? baseUrl = freezed,}) {
  return _then(AiProviderConfig(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as AiProviderType,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,baseUrl: freezed == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AiProviderConfig].
extension AiProviderConfigPatterns on AiProviderConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiProviderConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiProviderConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiProviderConfig value)  $default,){
final _that = this;
switch (_that) {
case _AiProviderConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiProviderConfig value)?  $default,){
final _that = this;
switch (_that) {
case _AiProviderConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AiProviderType provider,  String modelId,  String? baseUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiProviderConfig() when $default != null:
return $default(_that.provider,_that.modelId,_that.baseUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AiProviderType provider,  String modelId,  String? baseUrl)  $default,) {final _that = this;
switch (_that) {
case _AiProviderConfig():
return $default(_that.provider,_that.modelId,_that.baseUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AiProviderType provider,  String modelId,  String? baseUrl)?  $default,) {final _that = this;
switch (_that) {
case _AiProviderConfig() when $default != null:
return $default(_that.provider,_that.modelId,_that.baseUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AiProviderConfig implements AiProviderConfig {
  const _AiProviderConfig({required this.provider, required this.modelId, this.baseUrl});
  factory _AiProviderConfig.fromJson(Map<String, dynamic> json) => _$AiProviderConfigFromJson(json);

@override final  AiProviderType provider;
@override final  String modelId;
@override final  String? baseUrl;

/// Create a copy of AiProviderConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiProviderConfigCopyWith<_AiProviderConfig> get copyWith => __$AiProviderConfigCopyWithImpl<_AiProviderConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AiProviderConfigToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiProviderConfig&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,provider,modelId,baseUrl);
}

@override
String toString() {
    return 'AiProviderConfig(provider: $provider, modelId: $modelId, baseUrl: $baseUrl)';
}


}

/// @nodoc
abstract mixin class _$AiProviderConfigCopyWith<$Res> implements $AiProviderConfigCopyWith<$Res> {
  factory _$AiProviderConfigCopyWith(_AiProviderConfig value, $Res Function(_AiProviderConfig) _then) = __$AiProviderConfigCopyWithImpl;
@override @useResult
$Res call({
 AiProviderType provider, String modelId, String? baseUrl
});




}
/// @nodoc
class __$AiProviderConfigCopyWithImpl<$Res>
    implements _$AiProviderConfigCopyWith<$Res> {
  __$AiProviderConfigCopyWithImpl(this._self, this._then);

  final _AiProviderConfig _self;
  final $Res Function(_AiProviderConfig) _then;

/// Create a copy of AiProviderConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = null,Object? modelId = null,Object? baseUrl = freezed,}) {
  return _then(_AiProviderConfig(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as AiProviderType,modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String,baseUrl: freezed == baseUrl ? _self.baseUrl : baseUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
