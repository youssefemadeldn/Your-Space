import 'package:equatable/equatable.dart';

import '../../../domain/entities/user_profile.dart';

sealed class LoginState extends Equatable {
  const LoginState();
  @override
  List<Object?> get props => const [];
}

final class LoginInitial extends LoginState {
  const LoginInitial();
}

final class LoginLoading extends LoginState {
  const LoginLoading();
}

final class LoginSuccess extends LoginState {
  final UserProfile user;
  const LoginSuccess(this.user);
  @override
  List<Object?> get props => [user];
}

final class LoginError extends LoginState {
  final String message;
  final String? errorCode;
  final bool isNetworkError;
  const LoginError(this.message, {this.errorCode, this.isNetworkError = false});
  @override
  List<Object?> get props => [message, errorCode, isNetworkError];
}
