import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
class Failure with _$Failure {
  const factory Failure.server({required String message, int? statusCode}) =
      ServerFailure;

  const factory Failure.cache({required String message}) = CacheFailure;

  const factory Failure.missingApiKey({required String providerName}) =
      MissingApiKeyFailure;

  const factory Failure.providerNotConfigured({required String providerName}) =
      ProviderNotConfiguredFailure;

  const factory Failure.invalidCommand({required String commandTrigger}) =
      InvalidCommandFailure;

  const factory Failure.network({required String message}) = NetworkFailure;

  const factory Failure.unexpected({required String message}) =
      UnexpectedFailure;
}

extension FailureMessageExt on Failure {
  String get message {
    return when(
      server: (msg, code) => msg,
      cache: (msg) => msg,
      missingApiKey: (provider) => 'Missing API key for $provider',
      providerNotConfigured: (provider) => '$provider is not configured',
      invalidCommand: (trigger) => 'Invalid command: $trigger',
      network: (msg) => msg,
      unexpected: (msg) => msg,
    );
  }
}
