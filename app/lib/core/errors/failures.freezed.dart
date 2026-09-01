// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'failures.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Failure {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is Failure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'Failure()';
}


}

/// @nodoc
class $FailureCopyWith<$Res>  {
$FailureCopyWith(Failure _, $Res Function(Failure) __);
}


/// Adds pattern-matching-related methods to [Failure].
extension FailurePatterns on Failure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ServerFailure value)?  server,TResult Function( CacheFailure value)?  cache,TResult Function( MissingApiKeyFailure value)?  missingApiKey,TResult Function( ProviderNotConfiguredFailure value)?  providerNotConfigured,TResult Function( InvalidCommandFailure value)?  invalidCommand,TResult Function( NetworkFailure value)?  network,TResult Function( UnexpectedFailure value)?  unexpected,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ServerFailure() when server != null:
return server(_that);case CacheFailure() when cache != null:
return cache(_that);case MissingApiKeyFailure() when missingApiKey != null:
return missingApiKey(_that);case ProviderNotConfiguredFailure() when providerNotConfigured != null:
return providerNotConfigured(_that);case InvalidCommandFailure() when invalidCommand != null:
return invalidCommand(_that);case NetworkFailure() when network != null:
return network(_that);case UnexpectedFailure() when unexpected != null:
return unexpected(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ServerFailure value)  server,required TResult Function( CacheFailure value)  cache,required TResult Function( MissingApiKeyFailure value)  missingApiKey,required TResult Function( ProviderNotConfiguredFailure value)  providerNotConfigured,required TResult Function( InvalidCommandFailure value)  invalidCommand,required TResult Function( NetworkFailure value)  network,required TResult Function( UnexpectedFailure value)  unexpected,}){
final _that = this;
switch (_that) {
case ServerFailure():
return server(_that);case CacheFailure():
return cache(_that);case MissingApiKeyFailure():
return missingApiKey(_that);case ProviderNotConfiguredFailure():
return providerNotConfigured(_that);case InvalidCommandFailure():
return invalidCommand(_that);case NetworkFailure():
return network(_that);case UnexpectedFailure():
return unexpected(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ServerFailure value)?  server,TResult? Function( CacheFailure value)?  cache,TResult? Function( MissingApiKeyFailure value)?  missingApiKey,TResult? Function( ProviderNotConfiguredFailure value)?  providerNotConfigured,TResult? Function( InvalidCommandFailure value)?  invalidCommand,TResult? Function( NetworkFailure value)?  network,TResult? Function( UnexpectedFailure value)?  unexpected,}){
final _that = this;
switch (_that) {
case ServerFailure() when server != null:
return server(_that);case CacheFailure() when cache != null:
return cache(_that);case MissingApiKeyFailure() when missingApiKey != null:
return missingApiKey(_that);case ProviderNotConfiguredFailure() when providerNotConfigured != null:
return providerNotConfigured(_that);case InvalidCommandFailure() when invalidCommand != null:
return invalidCommand(_that);case NetworkFailure() when network != null:
return network(_that);case UnexpectedFailure() when unexpected != null:
return unexpected(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String message,  int? statusCode)?  server,TResult Function( String message)?  cache,TResult Function( String providerName)?  missingApiKey,TResult Function( String providerName)?  providerNotConfigured,TResult Function( String commandTrigger)?  invalidCommand,TResult Function( String message)?  network,TResult Function( String message)?  unexpected,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ServerFailure() when server != null:
return server(_that.message,_that.statusCode);case CacheFailure() when cache != null:
return cache(_that.message);case MissingApiKeyFailure() when missingApiKey != null:
return missingApiKey(_that.providerName);case ProviderNotConfiguredFailure() when providerNotConfigured != null:
return providerNotConfigured(_that.providerName);case InvalidCommandFailure() when invalidCommand != null:
return invalidCommand(_that.commandTrigger);case NetworkFailure() when network != null:
return network(_that.message);case UnexpectedFailure() when unexpected != null:
return unexpected(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String message,  int? statusCode)  server,required TResult Function( String message)  cache,required TResult Function( String providerName)  missingApiKey,required TResult Function( String providerName)  providerNotConfigured,required TResult Function( String commandTrigger)  invalidCommand,required TResult Function( String message)  network,required TResult Function( String message)  unexpected,}) {final _that = this;
switch (_that) {
case ServerFailure():
return server(_that.message,_that.statusCode);case CacheFailure():
return cache(_that.message);case MissingApiKeyFailure():
return missingApiKey(_that.providerName);case ProviderNotConfiguredFailure():
return providerNotConfigured(_that.providerName);case InvalidCommandFailure():
return invalidCommand(_that.commandTrigger);case NetworkFailure():
return network(_that.message);case UnexpectedFailure():
return unexpected(_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String message,  int? statusCode)?  server,TResult? Function( String message)?  cache,TResult? Function( String providerName)?  missingApiKey,TResult? Function( String providerName)?  providerNotConfigured,TResult? Function( String commandTrigger)?  invalidCommand,TResult? Function( String message)?  network,TResult? Function( String message)?  unexpected,}) {final _that = this;
switch (_that) {
case ServerFailure() when server != null:
return server(_that.message,_that.statusCode);case CacheFailure() when cache != null:
return cache(_that.message);case MissingApiKeyFailure() when missingApiKey != null:
return missingApiKey(_that.providerName);case ProviderNotConfiguredFailure() when providerNotConfigured != null:
return providerNotConfigured(_that.providerName);case InvalidCommandFailure() when invalidCommand != null:
return invalidCommand(_that.commandTrigger);case NetworkFailure() when network != null:
return network(_that.message);case UnexpectedFailure() when unexpected != null:
return unexpected(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ServerFailure implements Failure {
  const ServerFailure({required this.message, this.statusCode});
  

 final  String message;
 final  int? statusCode;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerFailureCopyWith<ServerFailure> get copyWith => _$ServerFailureCopyWithImpl<ServerFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerFailure&&(identical(other.message, message) || other.message == message)&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message,statusCode);
}

@override
String toString() {
    return 'Failure.server(message: $message, statusCode: $statusCode)';
}


}

/// @nodoc
abstract mixin class $ServerFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $ServerFailureCopyWith(ServerFailure value, $Res Function(ServerFailure) _then) = _$ServerFailureCopyWithImpl;
@useResult
$Res call({
 String message, int? statusCode
});




}
/// @nodoc
class _$ServerFailureCopyWithImpl<$Res>
    implements $ServerFailureCopyWith<$Res> {
  _$ServerFailureCopyWithImpl(this._self, this._then);

  final ServerFailure _self;
  final $Res Function(ServerFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? statusCode = freezed,}) {
  return _then(ServerFailure(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,statusCode: freezed == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc


class CacheFailure implements Failure {
  const CacheFailure({required this.message});
  

 final  String message;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CacheFailureCopyWith<CacheFailure> get copyWith => _$CacheFailureCopyWithImpl<CacheFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CacheFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'Failure.cache(message: $message)';
}


}

/// @nodoc
abstract mixin class $CacheFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $CacheFailureCopyWith(CacheFailure value, $Res Function(CacheFailure) _then) = _$CacheFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$CacheFailureCopyWithImpl<$Res>
    implements $CacheFailureCopyWith<$Res> {
  _$CacheFailureCopyWithImpl(this._self, this._then);

  final CacheFailure _self;
  final $Res Function(CacheFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(CacheFailure(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MissingApiKeyFailure implements Failure {
  const MissingApiKeyFailure({required this.providerName});
  

 final  String providerName;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MissingApiKeyFailureCopyWith<MissingApiKeyFailure> get copyWith => _$MissingApiKeyFailureCopyWithImpl<MissingApiKeyFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MissingApiKeyFailure&&(identical(other.providerName, providerName) || other.providerName == providerName));
}


@override
int get hashCode {
    return Object.hash(runtimeType,providerName);
}

@override
String toString() {
    return 'Failure.missingApiKey(providerName: $providerName)';
}


}

/// @nodoc
abstract mixin class $MissingApiKeyFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $MissingApiKeyFailureCopyWith(MissingApiKeyFailure value, $Res Function(MissingApiKeyFailure) _then) = _$MissingApiKeyFailureCopyWithImpl;
@useResult
$Res call({
 String providerName
});




}
/// @nodoc
class _$MissingApiKeyFailureCopyWithImpl<$Res>
    implements $MissingApiKeyFailureCopyWith<$Res> {
  _$MissingApiKeyFailureCopyWithImpl(this._self, this._then);

  final MissingApiKeyFailure _self;
  final $Res Function(MissingApiKeyFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? providerName = null,}) {
  return _then(MissingApiKeyFailure(
providerName: null == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ProviderNotConfiguredFailure implements Failure {
  const ProviderNotConfiguredFailure({required this.providerName});
  

 final  String providerName;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderNotConfiguredFailureCopyWith<ProviderNotConfiguredFailure> get copyWith => _$ProviderNotConfiguredFailureCopyWithImpl<ProviderNotConfiguredFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderNotConfiguredFailure&&(identical(other.providerName, providerName) || other.providerName == providerName));
}


@override
int get hashCode {
    return Object.hash(runtimeType,providerName);
}

@override
String toString() {
    return 'Failure.providerNotConfigured(providerName: $providerName)';
}


}

/// @nodoc
abstract mixin class $ProviderNotConfiguredFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $ProviderNotConfiguredFailureCopyWith(ProviderNotConfiguredFailure value, $Res Function(ProviderNotConfiguredFailure) _then) = _$ProviderNotConfiguredFailureCopyWithImpl;
@useResult
$Res call({
 String providerName
});




}
/// @nodoc
class _$ProviderNotConfiguredFailureCopyWithImpl<$Res>
    implements $ProviderNotConfiguredFailureCopyWith<$Res> {
  _$ProviderNotConfiguredFailureCopyWithImpl(this._self, this._then);

  final ProviderNotConfiguredFailure _self;
  final $Res Function(ProviderNotConfiguredFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? providerName = null,}) {
  return _then(ProviderNotConfiguredFailure(
providerName: null == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class InvalidCommandFailure implements Failure {
  const InvalidCommandFailure({required this.commandTrigger});
  

 final  String commandTrigger;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvalidCommandFailureCopyWith<InvalidCommandFailure> get copyWith => _$InvalidCommandFailureCopyWithImpl<InvalidCommandFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is InvalidCommandFailure&&(identical(other.commandTrigger, commandTrigger) || other.commandTrigger == commandTrigger));
}


@override
int get hashCode {
    return Object.hash(runtimeType,commandTrigger);
}

@override
String toString() {
    return 'Failure.invalidCommand(commandTrigger: $commandTrigger)';
}


}

/// @nodoc
abstract mixin class $InvalidCommandFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $InvalidCommandFailureCopyWith(InvalidCommandFailure value, $Res Function(InvalidCommandFailure) _then) = _$InvalidCommandFailureCopyWithImpl;
@useResult
$Res call({
 String commandTrigger
});




}
/// @nodoc
class _$InvalidCommandFailureCopyWithImpl<$Res>
    implements $InvalidCommandFailureCopyWith<$Res> {
  _$InvalidCommandFailureCopyWithImpl(this._self, this._then);

  final InvalidCommandFailure _self;
  final $Res Function(InvalidCommandFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? commandTrigger = null,}) {
  return _then(InvalidCommandFailure(
commandTrigger: null == commandTrigger ? _self.commandTrigger : commandTrigger // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class NetworkFailure implements Failure {
  const NetworkFailure({required this.message});
  

 final  String message;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkFailureCopyWith<NetworkFailure> get copyWith => _$NetworkFailureCopyWithImpl<NetworkFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'Failure.network(message: $message)';
}


}

/// @nodoc
abstract mixin class $NetworkFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $NetworkFailureCopyWith(NetworkFailure value, $Res Function(NetworkFailure) _then) = _$NetworkFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$NetworkFailureCopyWithImpl<$Res>
    implements $NetworkFailureCopyWith<$Res> {
  _$NetworkFailureCopyWithImpl(this._self, this._then);

  final NetworkFailure _self;
  final $Res Function(NetworkFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(NetworkFailure(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class UnexpectedFailure implements Failure {
  const UnexpectedFailure({required this.message});
  

 final  String message;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnexpectedFailureCopyWith<UnexpectedFailure> get copyWith => _$UnexpectedFailureCopyWithImpl<UnexpectedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UnexpectedFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,message);
}

@override
String toString() {
    return 'Failure.unexpected(message: $message)';
}


}

/// @nodoc
abstract mixin class $UnexpectedFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $UnexpectedFailureCopyWith(UnexpectedFailure value, $Res Function(UnexpectedFailure) _then) = _$UnexpectedFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$UnexpectedFailureCopyWithImpl<$Res>
    implements $UnexpectedFailureCopyWith<$Res> {
  _$UnexpectedFailureCopyWithImpl(this._self, this._then);

  final UnexpectedFailure _self;
  final $Res Function(UnexpectedFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(UnexpectedFailure(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
