import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/auth/domain/repositories/base_auth_repository.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/forgot_password_cubit/forgot_password_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/forgot_password_cubit/forgot_password_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late ForgotPasswordCubit cubit;

  setUp(() {
    repository = MockAuthRepository();
    cubit = ForgotPasswordCubit(repository);
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] — backend is always "successful" (anti-enumeration)', () async {
    when(() => repository.forgotPassword(email: any(named: 'email')))
        .thenAnswer((_) async => const Right(unit));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const ForgotPasswordLoading(), const ForgotPasswordSuccess()]),
    );

    unawaited(cubit.submit(email: 'a@a.com'));
    await expectation;
  });

  test('emits an Error with isNetworkError true when the request itself fails', () async {
    when(() => repository.forgotPassword(email: any(named: 'email')))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const ForgotPasswordLoading(),
        isA<ForgotPasswordError>().having((s) => s.isNetworkError, 'isNetworkError', true),
      ]),
    );

    unawaited(cubit.submit(email: 'a@a.com'));
    await expectation;
  });
}
