import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String? errorCode;

  const Failure({this.errorCode});

  @override
  List<Object?> get props => [errorCode];
}

class ServerFailure extends Failure {
  final int statusCode;
  final String message;

  const ServerFailure({
    required this.statusCode,
    required this.message,
    super.errorCode,
  });

  @override
  List<Object?> get props => [errorCode, statusCode, message];
}

class NetworkFailure extends Failure {
  const NetworkFailure();
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.errorCode});
}

class CacheFailure extends Failure {
  const CacheFailure();
}

class ValidationFailure extends Failure {
  final String message;

  const ValidationFailure({required this.message, super.errorCode});

  @override
  List<Object?> get props => [errorCode, message];
}

class UnexpectedFailure extends Failure {
  final String message;

  const UnexpectedFailure({this.message = '', super.errorCode});

  @override
  List<Object?> get props => [errorCode, message];
}
