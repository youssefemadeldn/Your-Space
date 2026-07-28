import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import '../../../domain/repositories/base_auth_repository.dart';
import '../failure_messages.dart';
import 'change_password_state.dart';

@injectable
class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  final AuthRepository _repository;

  ChangePasswordCubit(this._repository) : super(const ChangePasswordInitial());

  Future<void> submit({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    emit(const ChangePasswordLoading());
    final result = await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmNewPassword: confirmNewPassword,
    );
    result.fold(
      (failure) => emit(ChangePasswordError(
        failureToMessage(failure),
        errorCode: failure.errorCode,
        isNetworkError: failure is NetworkFailure,
      )),
      (_) => emit(const ChangePasswordSuccess()),
    );
  }
}
