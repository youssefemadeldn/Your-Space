import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import '../../../domain/repositories/base_auth_repository.dart';
import '../failure_messages.dart';
import 'forgot_password_state.dart';

@injectable
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final AuthRepository _repository;

  ForgotPasswordCubit(this._repository) : super(const ForgotPasswordInitial());

  Future<void> submit({required String email}) async {
    emit(const ForgotPasswordLoading());
    final result = await _repository.forgotPassword(email: email);
    result.fold(
      (failure) => emit(ForgotPasswordError(
        failureToMessage(failure),
        errorCode: failure.errorCode,
        isNetworkError: failure is NetworkFailure,
      )),
      (_) => emit(const ForgotPasswordSuccess()),
    );
  }
}
