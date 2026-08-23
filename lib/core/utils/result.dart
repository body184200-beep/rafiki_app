/// Lightweight success/failure wrapper for async boundaries.
sealed class Result<T> {
  const Result();

  factory Result.ok(T value) = Ok<T>;
  factory Result.err(Object error, [StackTrace? stackTrace]) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  R fold<R>(R Function(T value) onOk, R Function(Object error) onErr) {
    return switch (this) {
      Ok<T>(:final value) => onOk(value),
      Err<T>(:final error) => onErr(error),
    };
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error, [this.stackTrace]);
  final Object error;
  final StackTrace? stackTrace;
}
