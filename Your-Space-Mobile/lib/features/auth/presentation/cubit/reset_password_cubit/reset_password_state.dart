import 'package:equatable/equatable.dart';

sealed class ResetPasswordState extends Equatable {
  const ResetPasswordState();
  @override
  List<Object?> get props => const [];
}

final class ResetPasswordInitial extends ResetPasswordState {
  const ResetPasswordInitial();
}

final class ResetPasswordSubmitting extends ResetPasswordState {
  const ResetPasswordSubmitting();
}

final class ResetPasswordSuccess extends ResetPasswordState {
  const ResetPasswordSuccess();
}

final class ResetPasswordError extends ResetPasswordState {
  final String message;
  final String? errorCode;
  final bool isNetworkError;
  const ResetPasswordError(
    this.message, {
    this.errorCode,
    this.isNetworkError = false,
  });
  @override
  List<Object?> get props => [message, errorCode, isNetworkError];
}

final class ResetPasswordResendSuccess extends ResetPasswordState {
  const ResetPasswordResendSuccess();
}

final class ResetPasswordResendError extends ResetPasswordState {
  final bool isNetworkError;
  const ResetPasswordResendError({this.isNetworkError = false});
  @override
  List<Object?> get props => [isNetworkError];
}
