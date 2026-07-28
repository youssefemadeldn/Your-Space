import 'package:equatable/equatable.dart';

sealed class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();
  @override
  List<Object?> get props => const [];
}

final class ForgotPasswordInitial extends ForgotPasswordState {
  const ForgotPasswordInitial();
}

final class ForgotPasswordLoading extends ForgotPasswordState {
  const ForgotPasswordLoading();
}

final class ForgotPasswordSuccess extends ForgotPasswordState {
  const ForgotPasswordSuccess();
}

final class ForgotPasswordError extends ForgotPasswordState {
  final String message;
  final String? errorCode;
  final bool isNetworkError;
  const ForgotPasswordError(
    this.message, {
    this.errorCode,
    this.isNetworkError = false,
  });
  @override
  List<Object?> get props => [message, errorCode, isNetworkError];
}
