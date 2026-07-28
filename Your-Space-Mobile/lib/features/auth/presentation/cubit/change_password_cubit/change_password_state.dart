import 'package:equatable/equatable.dart';

sealed class ChangePasswordState extends Equatable {
  const ChangePasswordState();
  @override
  List<Object?> get props => const [];
}

final class ChangePasswordInitial extends ChangePasswordState {
  const ChangePasswordInitial();
}

final class ChangePasswordLoading extends ChangePasswordState {
  const ChangePasswordLoading();
}

final class ChangePasswordSuccess extends ChangePasswordState {
  const ChangePasswordSuccess();
}

final class ChangePasswordError extends ChangePasswordState {
  final String message;
  final String? errorCode;
  final bool isNetworkError;
  const ChangePasswordError(
    this.message, {
    this.errorCode,
    this.isNetworkError = false,
  });
  @override
  List<Object?> get props => [message, errorCode, isNetworkError];
}
