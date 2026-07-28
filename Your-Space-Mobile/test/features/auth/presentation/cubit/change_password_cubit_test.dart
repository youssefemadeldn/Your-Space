import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/auth/domain/repositories/base_auth_repository.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/change_password_cubit/change_password_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/change_password_cubit/change_password_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late ChangePasswordCubit cubit;

  setUp(() {
    repository = MockAuthRepository();
    cubit = ChangePasswordCubit(repository);
  });

  tearDown(() => cubit.close());

  void stubChangePassword(Either<Failure, Unit> result) {
    when(() => repository.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
          confirmNewPassword: any(named: 'confirmNewPassword'),
        )).thenAnswer((_) async => result);
  }

  void submit() => unawaited(cubit.submit(
        currentPassword: 'OldPassw0rd!',
        newPassword: 'NewPassw0rd!',
        confirmNewPassword: 'NewPassw0rd!',
      ));

  test('emits [Loading, Success] on success', () async {
    stubChangePassword(const Right(unit));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const ChangePasswordLoading(), const ChangePasswordSuccess()]),
    );

    submit();
    await expectation;
  });

  test('emits an Error with the backend message on Validation.Failed (wrong current password)', () async {
    stubChangePassword(const Left(
      ValidationFailure(message: 'Your current password is incorrect', errorCode: 'Validation.Failed'),
    ));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const ChangePasswordLoading(),
        isA<ChangePasswordError>()
            .having((s) => s.errorCode, 'errorCode', 'Validation.Failed')
            .having((s) => s.message, 'message', 'Your current password is incorrect'),
      ]),
    );

    submit();
    await expectation;
  });

  test('emits an Error with isNetworkError true on NetworkFailure', () async {
    stubChangePassword(const Left(NetworkFailure()));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const ChangePasswordLoading(),
        isA<ChangePasswordError>().having((s) => s.isNetworkError, 'isNetworkError', true),
      ]),
    );

    submit();
    await expectation;
  });
}
