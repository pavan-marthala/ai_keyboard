sealed class Result<T, F> {
  const Result();

  R when<R>({
    required R Function(T data) success,
    required R Function(F failure) failure,
  }) {
    final self = this;
    if (self is Success<T, F>) {
      return success(self.data);
    } else if (self is FailureResult<T, F>) {
      return failure(self.failure);
    }
    throw StateError('Unknown Result type');
  }

  bool get isSuccess => this is Success<T, F>;
  bool get isFailure => this is FailureResult<T, F>;

  T? get dataOrNull => isSuccess ? (this as Success<T, F>).data : null;
  F? get failureOrNull => isFailure ? (this as FailureResult<T, F>).failure : null;
}

final class Success<T, F> extends Result<T, F> {
  final T data;
  const Success(this.data);
}

final class FailureResult<T, F> extends Result<T, F> {
  final F failure;
  const FailureResult(this.failure);
}
