import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/auth/domain/repositories/base_auth_repository.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/delete_account_cubit/delete_account_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/delete_account_cubit/delete_account_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late DeleteAccountCubit cubit;

  setUp(() {
    repository = MockAuthRepository();
    cubit = DeleteAccountCubit(repository);
  });

  tearDown(() => cubit.close());

  void stubDeleteAccount(Either<Failure, Unit> result) {
    when(() => repository.deleteAccount(password: any(named: 'password')))
        .thenAnswer((_) async => result);
  }

  void submit() => unawaited(cubit.submit(password: 'MyPassw0rd!'));

  test('emits [Loading, Success] on success', () async {
    stubDeleteAccount(const Right(unit));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const DeleteAccountLoading(), const DeleteAccountSuccess()]),
    );

    submit();
    await expectation;
  });

  test('emits an Error carrying the backend message and errorCode on a wrong password', () async {
    stubDeleteAccount(const Left(
      ValidationFailure(
        message: 'The password you entered is incorrect.',
        errorCode: 'Auth.DeleteAccount.InvalidPassword',
      ),
    ));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const DeleteAccountLoading(),
        isA<DeleteAccountError>()
            .having((s) => s.errorCode, 'errorCode', 'Auth.DeleteAccount.InvalidPassword')
            .having((s) => s.message, 'message', 'The password you entered is incorrect.')
            .having((s) => s.isNetworkError, 'isNetworkError', false),
      ]),
    );

    submit();
    await expectation;
  });

  test('emits an Error with isNetworkError true on NetworkFailure', () async {
    stubDeleteAccount(const Left(NetworkFailure()));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const DeleteAccountLoading(),
        isA<DeleteAccountError>().having((s) => s.isNetworkError, 'isNetworkError', true),
      ]),
    );

    submit();
    await expectation;
  });
}
