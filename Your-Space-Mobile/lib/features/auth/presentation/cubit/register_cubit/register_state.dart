import 'package:equatable/equatable.dart';

import '../../../domain/entities/user_profile.dart';

sealed class RegisterState extends Equatable {
  const RegisterState();
  @override
  List<Object?> get props => const [];
}

final class RegisterInitial extends RegisterState {
  const RegisterInitial();
}

final class RegisterLoading extends RegisterState {
  const RegisterLoading();
}

final class RegisterSuccess extends RegisterState {
  final UserProfile user;
  const RegisterSuccess(this.user);
  @override
  List<Object?> get props => [user];
}

final class RegisterError extends RegisterState {
  final String message;
  final String? errorCode;
  final bool isNetworkError;
  const RegisterError(this.message, {this.errorCode, this.isNetworkError = false});
  @override
  List<Object?> get props => [message, errorCode, isNetworkError];
}
