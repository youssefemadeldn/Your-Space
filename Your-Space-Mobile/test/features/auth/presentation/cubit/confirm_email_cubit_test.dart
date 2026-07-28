import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/auth/domain/repositories/base_auth_repository.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/confirm_email_cubit/confirm_email_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/confirm_email_cubit/confirm_email_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late ConfirmEmailCubit cubit;

  setUp(() {
    repository = MockAuthRepository();
    cubit = ConfirmEmailCubit(repository);
  });

  tearDown(() => cubit.close());

  group('verify', () {
    void stubConfirmEmail(Either<Failure, Unit> result) {
      when(() => repository.confirmEmail(email: any(named: 'email'), code: any(named: 'code')))
          .thenAnswer((_) async => result);
    }

    test('emits [Verifying, VerifySuccess] on success', () async {
      stubConfirmEmail(const Right(unit));

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([const ConfirmEmailVerifying(), const ConfirmEmailVerifySuccess()]),
      );

      unawaited(cubit.verify(email: 'a@a.com', code: '123456'));
      await expectation;
    });

    test('emits a VerifyError with the backend message for Otp.Invalid', () async {
      stubConfirmEmail(const Left(
        ServerFailure(statusCode: 400, message: 'Incorrect code', errorCode: 'Otp.Invalid'),
      ));

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const ConfirmEmailVerifying(),
          isA<ConfirmEmailVerifyError>()
              .having((s) => s.errorCode, 'errorCode', 'Otp.Invalid')
              .having((s) => s.message, 'message', 'Incorrect code'),
        ]),
      );

      unawaited(cubit.verify(email: 'a@a.com', code: '000000'));
      await expectation;
    });

    test('emits a VerifyError with isNetworkError true on NetworkFailure', () async {
      stubConfirmEmail(const Left(NetworkFailure()));

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const ConfirmEmailVerifying(),
          isA<ConfirmEmailVerifyError>().having((s) => s.isNetworkError, 'isNetworkError', true),
        ]),
      );

      unawaited(cubit.verify(email: 'a@a.com', code: '123456'));
      await expectation;
    });
  });

  group('resendCode', () {
    test('emits ResendSuccess on success', () async {
      when(() => repository.resendConfirmationEmail(email: any(named: 'email')))
          .thenAnswer((_) async => const Right(unit));

      final expectation = expectLater(cubit.stream, emits(const ConfirmEmailResendSuccess()));

      unawaited(cubit.resendCode(email: 'a@a.com'));
      await expectation;
    });

    test('emits a ResendError with isNetworkError true on NetworkFailure', () async {
      when(() => repository.resendConfirmationEmail(email: any(named: 'email')))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      final expectation = expectLater(
        cubit.stream,
        emits(isA<ConfirmEmailResendError>().having((s) => s.isNetworkError, 'isNetworkError', true)),
      );

      unawaited(cubit.resendCode(email: 'a@a.com'));
      await expectation;
    });
  });
}
