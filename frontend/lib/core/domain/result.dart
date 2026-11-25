import 'package:resolveit/core/domain/api_failure.dart';

/// The outcome of a use case: either a [Success] value or a [Failure].
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.failure);
  final ApiFailure failure;
}
