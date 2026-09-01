// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AiRequest {

 String get inputText; String get prompt; AiProviderConfig get config; double get temperature; int get maxTokens;
/// Create a copy of AiRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiRequestCopyWith<AiRequest> get copyWith => _$AiRequestCopyWithImpl<AiRequest>(this as AiRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AiRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiRequest&&(identical(other.inputText, _this.inputText) || other.inputText == _this.inputText)&&(identical(other.prompt, _this.prompt) || other.prompt == _this.prompt)&&(identical(other.config, _this.config) || other.config == _this.config)&&(identical(other.temperature, _this.temperature) || other.temperature == _this.temperature)&&(identical(other.maxTokens, _this.maxTokens) || other.maxTokens == _this.maxTokens));
}


@override
int get hashCode {
  final _this = this as AiRequest;
  return Object.hash(runtimeType,_this.inputText,_this.prompt,_this.config,_this.temperature,_this.maxTokens);
}

@override
String toString() {
  final _this = this as AiRequest;
  return 'AiRequest(inputText: ${_this.inputText}, prompt: ${_this.prompt}, config: ${_this.config}, temperature: ${_this.temperature}, maxTokens: ${_this.maxTokens})';
}


}

/// @nodoc
abstract mixin class $AiRequestCopyWith<$Res>  {
  factory $AiRequestCopyWith(AiRequest value, $Res Function(AiRequest) _then) = _$AiRequestCopyWithImpl;
@useResult
$Res call({
 String inputText, String prompt, AiProviderConfig config, double temperature, int maxTokens
});


$AiProviderConfigCopyWith<$Res> get config;

}
/// @nodoc
class _$AiRequestCopyWithImpl<$Res>
    implements $AiRequestCopyWith<$Res> {
  _$AiRequestCopyWithImpl(this._self, this._then);

  final AiRequest _self;
  final $Res Function(AiRequest) _then;

/// Create a copy of AiRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inputText = null,Object? prompt = null,Object? config = null,Object? temperature = null,Object? maxTokens = null,}) {
  return _then(AiRequest(
inputText: null == inputText ? _self.inputText : inputText // ignore: cast_nullable_to_non_nullable
as String,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as AiProviderConfig,temperature: null == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double,maxTokens: null == maxTokens ? _self.maxTokens : maxTokens // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of AiRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AiProviderConfigCopyWith<$Res> get config {
  
  return $AiProviderConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}


/// Adds pattern-matching-related methods to [AiRequest].
extension AiRequestPatterns on AiRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiRequest value)  $default,){
final _that = this;
switch (_that) {
case _AiRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiRequest value)?  $default,){
final _that = this;
switch (_that) {
case _AiRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String inputText,  String prompt,  AiProviderConfig config,  double temperature,  int maxTokens)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiRequest() when $default != null:
return $default(_that.inputText,_that.prompt,_that.config,_that.temperature,_that.maxTokens);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String inputText,  String prompt,  AiProviderConfig config,  double temperature,  int maxTokens)  $default,) {final _that = this;
switch (_that) {
case _AiRequest():
return $default(_that.inputText,_that.prompt,_that.config,_that.temperature,_that.maxTokens);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String inputText,  String prompt,  AiProviderConfig config,  double temperature,  int maxTokens)?  $default,) {final _that = this;
switch (_that) {
case _AiRequest() when $default != null:
return $default(_that.inputText,_that.prompt,_that.config,_that.temperature,_that.maxTokens);case _:
  return null;

}
}

}

/// @nodoc


class _AiRequest implements AiRequest {
  const _AiRequest({required this.inputText, required this.prompt, required this.config, this.temperature = 0.7, this.maxTokens = 1000});
  

@override final  String inputText;
@override final  String prompt;
@override final  AiProviderConfig config;
@override@JsonKey() final  double temperature;
@override@JsonKey() final  int maxTokens;

/// Create a copy of AiRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiRequestCopyWith<_AiRequest> get copyWith => __$AiRequestCopyWithImpl<_AiRequest>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiRequest&&(identical(other.inputText, inputText) || other.inputText == inputText)&&(identical(other.prompt, prompt) || other.prompt == prompt)&&(identical(other.config, config) || other.config == config)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.maxTokens, maxTokens) || other.maxTokens == maxTokens));
}


@override
int get hashCode {
    return Object.hash(runtimeType,inputText,prompt,config,temperature,maxTokens);
}

@override
String toString() {
    return 'AiRequest(inputText: $inputText, prompt: $prompt, config: $config, temperature: $temperature, maxTokens: $maxTokens)';
}


}

/// @nodoc
abstract mixin class _$AiRequestCopyWith<$Res> implements $AiRequestCopyWith<$Res> {
  factory _$AiRequestCopyWith(_AiRequest value, $Res Function(_AiRequest) _then) = __$AiRequestCopyWithImpl;
@override @useResult
$Res call({
 String inputText, String prompt, AiProviderConfig config, double temperature, int maxTokens
});


@override $AiProviderConfigCopyWith<$Res> get config;

}
/// @nodoc
class __$AiRequestCopyWithImpl<$Res>
    implements _$AiRequestCopyWith<$Res> {
  __$AiRequestCopyWithImpl(this._self, this._then);

  final _AiRequest _self;
  final $Res Function(_AiRequest) _then;

/// Create a copy of AiRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? inputText = null,Object? prompt = null,Object? config = null,Object? temperature = null,Object? maxTokens = null,}) {
  return _then(_AiRequest(
inputText: null == inputText ? _self.inputText : inputText // ignore: cast_nullable_to_non_nullable
as String,prompt: null == prompt ? _self.prompt : prompt // ignore: cast_nullable_to_non_nullable
as String,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as AiProviderConfig,temperature: null == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as double,maxTokens: null == maxTokens ? _self.maxTokens : maxTokens // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of AiRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AiProviderConfigCopyWith<$Res> get config {
  
  return $AiProviderConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}

// dart format on
