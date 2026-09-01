// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AiModel {

 String get id; String get displayName; AiProviderType get provider; String? get description; List<String> get capabilities;
/// Create a copy of AiModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AiModelCopyWith<AiModel> get copyWith => _$AiModelCopyWithImpl<AiModel>(this as AiModel, _$identity);

  /// Serializes this AiModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AiModel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AiModel&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.provider, _this.provider) || other.provider == _this.provider)&&(identical(other.description, _this.description) || other.description == _this.description)&&const DeepCollectionEquality().equals(other.capabilities, _this.capabilities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AiModel;
  return Object.hash(runtimeType,_this.id,_this.displayName,_this.provider,_this.description,const DeepCollectionEquality().hash(_this.capabilities));
}

@override
String toString() {
  final _this = this as AiModel;
  return 'AiModel(id: ${_this.id}, displayName: ${_this.displayName}, provider: ${_this.provider}, description: ${_this.description}, capabilities: ${_this.capabilities})';
}


}

/// @nodoc
abstract mixin class $AiModelCopyWith<$Res>  {
  factory $AiModelCopyWith(AiModel value, $Res Function(AiModel) _then) = _$AiModelCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, AiProviderType provider, String? description, List<String> capabilities
});




}
/// @nodoc
class _$AiModelCopyWithImpl<$Res>
    implements $AiModelCopyWith<$Res> {
  _$AiModelCopyWithImpl(this._self, this._then);

  final AiModel _self;
  final $Res Function(AiModel) _then;

/// Create a copy of AiModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? provider = null,Object? description = freezed,Object? capabilities = null,}) {
  return _then(AiModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as AiProviderType,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,capabilities: null == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [AiModel].
extension AiModelPatterns on AiModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AiModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AiModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AiModel value)  $default,){
final _that = this;
switch (_that) {
case _AiModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AiModel value)?  $default,){
final _that = this;
switch (_that) {
case _AiModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  AiProviderType provider,  String? description,  List<String> capabilities)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AiModel() when $default != null:
return $default(_that.id,_that.displayName,_that.provider,_that.description,_that.capabilities);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  AiProviderType provider,  String? description,  List<String> capabilities)  $default,) {final _that = this;
switch (_that) {
case _AiModel():
return $default(_that.id,_that.displayName,_that.provider,_that.description,_that.capabilities);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  AiProviderType provider,  String? description,  List<String> capabilities)?  $default,) {final _that = this;
switch (_that) {
case _AiModel() when $default != null:
return $default(_that.id,_that.displayName,_that.provider,_that.description,_that.capabilities);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AiModel implements AiModel {
  const _AiModel({required this.id, required this.displayName, required this.provider, this.description,  List<String> capabilities = const []}): _capabilities = capabilities;
  factory _AiModel.fromJson(Map<String, dynamic> json) => _$AiModelFromJson(json);

@override final  String id;
@override final  String displayName;
@override final  AiProviderType provider;
@override final  String? description;
 final  List<String> _capabilities;
@override@JsonKey() List<String> get capabilities {
  if (_capabilities is EqualUnmodifiableListView) return _capabilities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_capabilities);
}


/// Create a copy of AiModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AiModelCopyWith<_AiModel> get copyWith => __$AiModelCopyWithImpl<_AiModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AiModelToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AiModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.capabilities, _capabilities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,displayName,provider,description,const DeepCollectionEquality().hash(_capabilities));
}

@override
String toString() {
    return 'AiModel(id: $id, displayName: $displayName, provider: $provider, description: $description, capabilities: $capabilities)';
}


}

/// @nodoc
abstract mixin class _$AiModelCopyWith<$Res> implements $AiModelCopyWith<$Res> {
  factory _$AiModelCopyWith(_AiModel value, $Res Function(_AiModel) _then) = __$AiModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, AiProviderType provider, String? description, List<String> capabilities
});




}
/// @nodoc
class __$AiModelCopyWithImpl<$Res>
    implements _$AiModelCopyWith<$Res> {
  __$AiModelCopyWithImpl(this._self, this._then);

  final _AiModel _self;
  final $Res Function(_AiModel) _then;

/// Create a copy of AiModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? provider = null,Object? description = freezed,Object? capabilities = null,}) {
  return _then(_AiModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as AiProviderType,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,capabilities: null == capabilities ? _self._capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
