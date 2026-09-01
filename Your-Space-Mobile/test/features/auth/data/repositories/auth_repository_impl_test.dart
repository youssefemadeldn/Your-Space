import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/storage/secure_storage_helper.dart';
import 'package:your_space_mobile/features/auth/data/datasources/auth_remote_data_source_impl.dart';
import 'package:your_space_mobile/features/auth/data/models/auth_response.dart';
import 'package:your_space_mobile/features/auth/data/models/change_password_request.dart';
import 'package:your_space_mobile/features/auth/data/models/confirm_email_request.dart';
import 'package:your_space_mobile/features/auth/data/models/delete_account_request.dart';
import 'package:your_space_mobile/features/auth/data/models/forgot_password_request.dart';
import 'package:your_space_mobile/features/auth/data/models/login_request.dart';
import 'package:your_space_mobile/features/auth/data/models/register_request.dart';
import 'package:your_space_mobile/features/auth/data/models/resend_confirmation_email_request.dart';
import 'package:your_space_mobile/features/auth/data/models/reset_password_request.dart';
import 'package:your_space_mobile/features/auth/data/models/user_profile_response.dart';
import 'package:your_space_mobile/features/auth/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDataSourceImpl extends Mock implements AuthRemoteDataSourceImpl {}

class MockSecureStorageHelper extends Mock implements SecureStorageHelper {}

void main() {
  late MockAuthRemoteDataSourceImpl remote;
  late MockSecureStorageHelper secureStorage;
  late AuthRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const RegisterRequest(
      email: '',
      password: '',
      confirmPassword: '',
      firstName: '',
      lastName: '',
      phoneNumber: '',
    ));
    registerFallbackValue(const LoginRequest(email: '', password: ''));
    registerFallbackValue(const ConfirmEmailRequest(email: '', code: ''));
    registerFallbackValue(const ResendConfirmationEmailRequest(email: ''));
    registerFallbackValue(const ForgotPasswordRequest(email: ''));
    registerFallbackValue(const ResetPasswordRequest(
      email: '',
      code: '',
      newPassword: '',
      confirmNewPassword: '',
    ));
    registerFallbackValue(const ChangePasswordRequest(
      currentPassword: '',
      newPassword: '',
      confirmNewPassword: '',
    ));
    registerFallbackValue(const DeleteAccountRequest(password: ''));
  });

  setUp(() {
    remote = MockAuthRemoteDataSourceImpl();
    secureStorage = MockSecureStorageHelper();
    repository = AuthRepositoryImpl(remote, secureStorage);
  });

  group('login', () {
    final userProfileResponse = const UserProfileResponse(
      id: '1',
      email: 'a@a.com',
      firstName: 'A',
      lastName: 'B',
      roles: ['User'],
    );

    test('persists both tokens and the remember-me flag, returns the entity on success', () async {
      final authResponse = AuthResponse(
        accessToken: 'access-token',
        accessTokenExpiresAt: DateTime(2030),
        refreshToken: 'refresh-token',
        user: userProfileResponse,
      );
      when(() => remote.login(any())).thenAnswer((_) async => Right(authResponse));
      when(() => secureStorage.saveToken(any())).thenAnswer((_) async {});
      when(() => secureStorage.saveRefreshToken(any())).thenAnswer((_) async {});
      when(() => secureStorage.saveRememberMe(any())).thenAnswer((_) async {});

      final result = await repository.login(email: 'a@a.com', password: 'password123', rememberMe: true);

      expect(result.isRight(), isTrue);
      verifyInOrder([
        () => secureStorage.saveToken('access-token'),
        () => secureStorage.saveRefreshToken('refresh-token'),
        () => secureStorage.saveRememberMe(true),
      ]);
    });

    test('persists rememberMe as false when the box is unchecked', () async {
      final authResponse = AuthResponse(
        accessToken: 'access-token',
        accessTokenExpiresAt: DateTime(2030),
        refreshToken: 'refresh-token',
        user: userProfileResponse,
      );
      when(() => remote.login(any())).thenAnswer((_) async => Right(authResponse));
      when(() => secureStorage.saveToken(any())).thenAnswer((_) async {});
      when(() => secureStorage.saveRefreshToken(any())).thenAnswer((_) async {});
      when(() => secureStorage.saveRememberMe(any())).thenAnswer((_) async {});

      await repository.login(email: 'a@a.com', password: 'password123', rememberMe: false);

      verify(() => secureStorage.saveRememberMe(false)).called(1);
    });

    test('never touches storage on failure', () async {
      const failure = UnauthorizedFailure(errorCode: 'Auth.InvalidCredentials');
      when(() => remote.login(any())).thenAnswer((_) async => const Left(failure));

      final result = await repository.login(email: 'a@a.com', password: 'wrong', rememberMe: true);

      expect(result, const Left(failure));
      verifyNever(() => secureStorage.saveToken(any()));
      verifyNever(() => secureStorage.saveRefreshToken(any()));
      verifyNever(() => secureStorage.saveRememberMe(any()));
    });
  });

  group('changePassword', () {
    test('clears the session on success', () async {
      when(() => remote.changePassword(any())).thenAnswer((_) async => const Right(unit));
      when(() => secureStorage.clearSession()).thenAnswer((_) async {});

      final result = await repository.changePassword(
        currentPassword: 'old-password',
        newPassword: 'NewPassw0rd!',
        confirmNewPassword: 'NewPassw0rd!',
      );

      expect(result.isRight(), isTrue);
      verify(() => secureStorage.clearSession()).called(1);
    });

    test('never touches storage on failure', () async {
      const failure = ValidationFailure(message: 'Wrong password', errorCode: 'Validation.Failed');
      when(() => remote.changePassword(any())).thenAnswer((_) async => const Left(failure));

      final result = await repository.changePassword(
        currentPassword: 'bad-password',
        newPassword: 'NewPassw0rd!',
        confirmNewPassword: 'NewPassw0rd!',
      );

      expect(result, const Left(failure));
      verifyNever(() => secureStorage.clearSession());
    });
  });

  group('deleteAccount', () {
    test('clears the session on success', () async {
      when(() => remote.deleteAccount(any())).thenAnswer((_) async => const Right(unit));
      when(() => secureStorage.clearSession()).thenAnswer((_) async {});

      final result = await repository.deleteAccount(password: 'MyPassw0rd!');

      expect(result.isRight(), isTrue);
      verify(() => secureStorage.clearSession()).called(1);
    });

    test('never touches storage on failure', () async {
      const failure = ValidationFailure(
        message: 'The password you entered is incorrect.',
        errorCode: 'Auth.DeleteAccount.InvalidPassword',
      );
      when(() => remote.deleteAccount(any())).thenAnswer((_) async => const Left(failure));

      final result = await repository.deleteAccount(password: 'wrong');

      expect(result, const Left(failure));
      verifyNever(() => secureStorage.clearSession());
    });
  });
}
