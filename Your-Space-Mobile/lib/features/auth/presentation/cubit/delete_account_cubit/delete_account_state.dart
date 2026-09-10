import 'package:equatable/equatable.dart';

sealed class DeleteAccountState extends Equatable {
  const DeleteAccountState();
  @override
  List<Object?> get props => const [];
}

final class DeleteAccountInitial extends DeleteAccountState {
  const DeleteAccountInitial();
}

final class DeleteAccountLoading extends DeleteAccountState {
  const DeleteAccountLoading();
}

final class DeleteAccountSuccess extends DeleteAccountState {
  const DeleteAccountSuccess();
}

final class DeleteAccountError extends DeleteAccountState {
  final String message;
  final String? errorCode;
  final bool isNetworkError;
  const DeleteAccountError(
    this.message, {
    this.errorCode,
    this.isNetworkError = false,
  });
  @override
  List<Object?> get props => [message, errorCode, isNetworkError];
}
