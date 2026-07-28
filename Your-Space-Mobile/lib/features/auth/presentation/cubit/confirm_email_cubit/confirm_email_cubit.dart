import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import '../../../domain/repositories/base_auth_repository.dart';
import '../failure_messages.dart';
import 'confirm_email_state.dart';

@injectable
class ConfirmEmailCubit extends Cubit<ConfirmEmailState> {
  final AuthRepository _repository;

  ConfirmEmailCubit(this._repository) : super(const ConfirmEmailInitial());

  Future<void> verify({required String email, required String code}) async {
    emit(const ConfirmEmailVerifying());
    final result = await _repository.confirmEmail(email: email, code: code);
    result.fold(
      (failure) => emit(ConfirmEmailVerifyError(
        failureToMessage(failure),
        errorCode: failure.errorCode,
        isNetworkError: failure is NetworkFailure,
      )),
      (_) => emit(const ConfirmEmailVerifySuccess()),
    );
  }

  Future<void> resendCode({required String email}) async {
    final result = await _repository.resendConfirmationEmail(email: email);
    result.fold(
      (failure) => emit(ConfirmEmailResendError(isNetworkError: failure is NetworkFailure)),
      (_) => emit(const ConfirmEmailResendSuccess()),
    );
  }
}
