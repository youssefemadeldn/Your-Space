import 'failure.dart';

/// Internal transport type — never imported outside [ApiManager]. Represents
/// the raw HTTP outcome before it is converted to `Either<Failure, T>`.
sealed class ApiResult<T> {
  const ApiResult();
}

class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);
}

class ApiFailure<T> extends ApiResult<T> {
  final Failure failure;
  const ApiFailure(this.failure);
}
