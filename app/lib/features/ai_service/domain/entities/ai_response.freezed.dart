// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AiResponse {

 String get transformedText; int? get promptTokens; int? get completionTokens;
/// Create a copy of AiResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiResponseCopyWith<AiResponse> get copyWith => _$AiResponseCopyWithImpl<AiResponse>(this as AiResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AiResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiResponse&&(identical(other.transformedText, _this.transformedText) || other.transformedText == _this.transformedText)&&(identical(other.promptTokens, _this.promptTokens) || other.promptTokens == _this.promptTokens)&&(identical(other.completionTokens, _this.completionTokens) || other.completionTokens == _this.completionTokens));
}


@override
int get hashCode {
  final _this = this as AiResponse;
  return Object.hash(runtimeType,_this.transformedText,_this.promptTokens,_this.completionTokens);
}

@override
String toString() {
  final _this = this as AiResponse;
  return 'AiResponse(transformedText: ${_this.transformedText}, promptTokens: ${_this.promptTokens}, completionTokens: ${_this.completionTokens})';
}


}

/// @nodoc
abstract mixin class $AiResponseCopyWith<$Res>  {
  factory $AiResponseCopyWith(AiResponse value, $Res Function(AiResponse) _then) = _$AiResponseCopyWithImpl;
@useResult
$Res call({
 String transformedText, int? promptTokens, int? completionTokens
});




}
/// @nodoc
class _$AiResponseCopyWithImpl<$Res>
    implements $AiResponseCopyWith<$Res> {
  _$AiResponseCopyWithImpl(this._self, this._then);

  final AiResponse _self;
  final $Res Function(AiResponse) _then;

/// Create a copy of AiResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? transformedText = null,Object? promptTokens = freezed,Object? completionTokens = freezed,}) {
  return _then(AiResponse(
transformedText: null == transformedText ? _self.transformedText : transformedText // ignore: cast_nullable_to_non_nullable
as String,promptTokens: freezed == promptTokens ? _self.promptTokens : promptTokens // ignore: cast_nullable_to_non_nullable
as int?,completionTokens: freezed == completionTokens ? _self.completionTokens : completionTokens // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [AiResponse].
extension AiResponsePatterns on AiResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiResponse value)  $default,){
final _that = this;
switch (_that) {
case _AiResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiResponse value)?  $default,){
final _that = this;
switch (_that) {
case _AiResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String transformedText,  int? promptTokens,  int? completionTokens)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiResponse() when $default != null:
return $default(_that.transformedText,_that.promptTokens,_that.completionTokens);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String transformedText,  int? promptTokens,  int? completionTokens)  $default,) {final _that = this;
switch (_that) {
case _AiResponse():
return $default(_that.transformedText,_that.promptTokens,_that.completionTokens);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String transformedText,  int? promptTokens,  int? completionTokens)?  $default,) {final _that = this;
switch (_that) {
case _AiResponse() when $default != null:
return $default(_that.transformedText,_that.promptTokens,_that.completionTokens);case _:
  return null;

}
}

}

/// @nodoc


class _AiResponse implements AiResponse {
  const _AiResponse({required this.transformedText, this.promptTokens, this.completionTokens});
  

@override final  String transformedText;
@override final  int? promptTokens;
@override final  int? completionTokens;

/// Create a copy of AiResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiResponseCopyWith<_AiResponse> get copyWith => __$AiResponseCopyWithImpl<_AiResponse>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiResponse&&(identical(other.transformedText, transformedText) || other.transformedText == transformedText)&&(identical(other.promptTokens, promptTokens) || other.promptTokens == promptTokens)&&(identical(other.completionTokens, completionTokens) || other.completionTokens == completionTokens));
}


@override
int get hashCode {
    return Object.hash(runtimeType,transformedText,promptTokens,completionTokens);
}

@override
String toString() {
    return 'AiResponse(transformedText: $transformedText, promptTokens: $promptTokens, completionTokens: $completionTokens)';
}


}

/// @nodoc
abstract mixin class _$AiResponseCopyWith<$Res> implements $AiResponseCopyWith<$Res> {
  factory _$AiResponseCopyWith(_AiResponse value, $Res Function(_AiResponse) _then) = __$AiResponseCopyWithImpl;
@override @useResult
$Res call({
 String transformedText, int? promptTokens, int? completionTokens
});




}
/// @nodoc
class __$AiResponseCopyWithImpl<$Res>
    implements _$AiResponseCopyWith<$Res> {
  __$AiResponseCopyWithImpl(this._self, this._then);

  final _AiResponse _self;
  final $Res Function(_AiResponse) _then;

/// Create a copy of AiResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? transformedText = null,Object? promptTokens = freezed,Object? completionTokens = freezed,}) {
  return _then(_AiResponse(
transformedText: null == transformedText ? _self.transformedText : transformedText // ignore: cast_nullable_to_non_nullable
as String,promptTokens: freezed == promptTokens ? _self.promptTokens : promptTokens // ignore: cast_nullable_to_non_nullable
as int?,completionTokens: freezed == completionTokens ? _self.completionTokens : completionTokens // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
