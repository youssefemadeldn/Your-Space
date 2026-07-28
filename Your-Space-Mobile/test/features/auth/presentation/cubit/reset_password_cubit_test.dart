import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/auth/domain/repositories/base_auth_repository.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/reset_password_cubit/reset_password_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/reset_password_cubit/reset_password_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late ResetPasswordCubit cubit;

  setUp(() {
    repository = MockAuthRepository();
    cubit = ResetPasswordCubit(repository);
  });

  tearDown(() => cubit.close());

  group('submit', () {
    void stubResetPassword(Either<Failure, Unit> result) {
      when(() => repository.resetPassword(
            email: any(named: 'email'),
            code: any(named: 'code'),
            newPassword: any(named: 'newPassword'),
            confirmNewPassword: any(named: 'confirmNewPassword'),
          )).thenAnswer((_) async => result);
    }

    void submit() => unawaited(cubit.submit(
          email: 'a@a.com',
          code: '123456',
          newPassword: 'NewPassw0rd!',
          confirmNewPassword: 'NewPassw0rd!',
        ));

    test('emits [Submitting, Success] on success', () async {
      stubResetPassword(const Right(unit));

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([const ResetPasswordSubmitting(), const ResetPasswordSuccess()]),
      );

      submit();
      await expectation;
    });

    test('emits an Error with the backend message for Otp.Invalid', () async {
      stubResetPassword(const Left(
        ServerFailure(statusCode: 400, message: 'Incorrect or expired code', errorCode: 'Otp.Invalid'),
      ));

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const ResetPasswordSubmitting(),
          isA<ResetPasswordError>()
              .having((s) => s.errorCode, 'errorCode', 'Otp.Invalid')
              .having((s) => s.message, 'message', 'Incorrect or expired code'),
        ]),
      );

      submit();
      await expectation;
    });

    test('emits an Error with isNetworkError true on NetworkFailure', () async {
      stubResetPassword(const Left(NetworkFailure()));

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const ResetPasswordSubmitting(),
          isA<ResetPasswordError>().having((s) => s.isNetworkError, 'isNetworkError', true),
        ]),
      );

      submit();
      await expectation;
    });
  });

  group('resendCode', () {
    test('re-issues via forgotPassword and emits ResendSuccess', () async {
      when(() => repository.forgotPassword(email: any(named: 'email')))
          .thenAnswer((_) async => const Right(unit));

      final expectation = expectLater(cubit.stream, emits(const ResetPasswordResendSuccess()));

      unawaited(cubit.resendCode(email: 'a@a.com'));
      await expectation;

      verify(() => repository.forgotPassword(email: 'a@a.com')).called(1);
    });

    test('emits a ResendError with isNetworkError true on NetworkFailure', () async {
      when(() => repository.forgotPassword(email: any(named: 'email')))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      final expectation = expectLater(
        cubit.stream,
        emits(isA<ResetPasswordResendError>().having((s) => s.isNetworkError, 'isNetworkError', true)),
      );

      unawaited(cubit.resendCode(email: 'a@a.com'));
      await expectation;
    });
  });
}
