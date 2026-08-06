import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import '../../../domain/repositories/base_auth_repository.dart';
import '../failure_messages.dart';
import 'register_state.dart';

@injectable
class RegisterCubit extends Cubit<RegisterState> {
  final AuthRepository _repository;

  RegisterCubit(this._repository) : super(const RegisterInitial());

  Future<void> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required Gender gender,
  }) async {
    emit(const RegisterLoading());
    final result = await _repository.register(
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      gender: gender,
    );
    result.fold(
      (failure) => emit(RegisterError(
        failureToMessage(failure),
        errorCode: failure.errorCode,
        isNetworkError: failure is NetworkFailure,
      )),
      (user) => emit(RegisterSuccess(user)),
    );
  }
}
