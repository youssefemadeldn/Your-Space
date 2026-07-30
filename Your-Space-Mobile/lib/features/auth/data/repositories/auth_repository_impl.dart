import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/storage/secure_storage_helper.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/base_auth_repository.dart';
import '../datasources/auth_remote_data_source_impl.dart';
import '../models/change_password_request.dart';
import '../models/confirm_email_request.dart';
import '../models/forgot_password_request.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/resend_confirmation_email_request.dart';
import '../models/reset_password_request.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSourceImpl _remote;
  final SecureStorageHelper _secureStorage;

  AuthRepositoryImpl(this._remote, this._secureStorage);

  @override
  Future<Either<Failure, UserProfile>> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    final result = await _remote.register(RegisterRequest(
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
    ));
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }

  @override
  Future<Either<Failure, UserProfile>> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final result = await _remote.login(LoginRequest(email: email, password: password));
    return result.fold(
      (failure) async => Left(failure),
      (response) async {
        await _secureStorage.saveToken(response.accessToken);
        await _secureStorage.saveRefreshToken(response.refreshToken);
        await _secureStorage.saveRememberMe(rememberMe);
        return Right(response.toEntity());
      },
    );
  }

  @override
  Future<Either<Failure, Unit>> confirmEmail({
    required String email,
    required String code,
  }) =>
      _remote.confirmEmail(ConfirmEmailRequest(email: email, code: code));

  @override
  Future<Either<Failure, Unit>> resendConfirmationEmail({required String email}) =>
      _remote.resendConfirmationEmail(ResendConfirmationEmailRequest(email: email));

  @override
  Future<Either<Failure, Unit>> forgotPassword({required String email}) =>
      _remote.forgotPassword(ForgotPasswordRequest(email: email));

  @override
  Future<Either<Failure, Unit>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmNewPassword,
  }) =>
      _remote.resetPassword(ResetPasswordRequest(
        email: email,
        code: code,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      ));

  @override
  Future<Either<Failure, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final result = await _remote.changePassword(ChangePasswordRequest(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmNewPassword: confirmNewPassword,
    ));
    return result.fold(
      (failure) async => Left(failure),
      (_) async {
        await _secureStorage.clearSession();
        return const Right(unit);
      },
    );
  }
}
