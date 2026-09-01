import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import '../../../domain/repositories/base_auth_repository.dart';
import '../failure_messages.dart';
import 'delete_account_state.dart';

@injectable
class DeleteAccountCubit extends Cubit<DeleteAccountState> {
  final AuthRepository _repository;

  DeleteAccountCubit(this._repository) : super(const DeleteAccountInitial());

  Future<void> submit({required String password}) async {
    emit(const DeleteAccountLoading());
    final result = await _repository.deleteAccount(password: password);
    result.fold(
      (failure) => emit(DeleteAccountError(
        failureToMessage(failure),
        errorCode: failure.errorCode,
        isNetworkError: failure is NetworkFailure,
      )),
      (_) => emit(const DeleteAccountSuccess()),
    );
  }
}
