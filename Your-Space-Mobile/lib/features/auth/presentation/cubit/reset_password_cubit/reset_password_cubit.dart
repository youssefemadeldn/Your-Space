import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import '../../../domain/repositories/base_auth_repository.dart';
import '../failure_messages.dart';
import 'reset_password_state.dart';

@injectable
class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  final AuthRepository _repository;

  ResetPasswordCubit(this._repository) : super(const ResetPasswordInitial());

  Future<void> submit({
    required String email,
    required String code,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    emit(const ResetPasswordSubmitting());
    final result = await _repository.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
      confirmNewPassword: confirmNewPassword,
    );
    result.fold(
      (failure) => emit(ResetPasswordError(
        failureToMessage(failure),
        errorCode: failure.errorCode,
        isNetworkError: failure is NetworkFailure,
      )),
      (_) => emit(const ResetPasswordSuccess()),
    );
  }

  // There is no dedicated reset-password resend endpoint — resending here
  // re-issues a fresh code the same way Forgot Password does.
  Future<void> resendCode({required String email}) async {
    final result = await _repository.forgotPassword(email: email);
    result.fold(
      (failure) => emit(ResetPasswordResendError(isNetworkError: failure is NetworkFailure)),
      (_) => emit(const ResetPasswordResendSuccess()),
    );
  }
}
