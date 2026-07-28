import 'package:equatable/equatable.dart';

sealed class ConfirmEmailState extends Equatable {
  const ConfirmEmailState();
  @override
  List<Object?> get props => const [];
}

final class ConfirmEmailInitial extends ConfirmEmailState {
  const ConfirmEmailInitial();
}

final class ConfirmEmailVerifying extends ConfirmEmailState {
  const ConfirmEmailVerifying();
}

final class ConfirmEmailVerifySuccess extends ConfirmEmailState {
  const ConfirmEmailVerifySuccess();
}

final class ConfirmEmailVerifyError extends ConfirmEmailState {
  final String message;
  final String? errorCode;
  final bool isNetworkError;
  const ConfirmEmailVerifyError(
    this.message, {
    this.errorCode,
    this.isNetworkError = false,
  });
  @override
  List<Object?> get props => [message, errorCode, isNetworkError];
}

final class ConfirmEmailResendSuccess extends ConfirmEmailState {
  const ConfirmEmailResendSuccess();
}

final class ConfirmEmailResendError extends ConfirmEmailState {
  final bool isNetworkError;
  const ConfirmEmailResendError({this.isNetworkError = false});
  @override
  List<Object?> get props => [isNetworkError];
}
