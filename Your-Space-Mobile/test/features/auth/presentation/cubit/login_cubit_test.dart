import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/auth/domain/entities/user_profile.dart';
import 'package:your_space_mobile/features/auth/domain/repositories/base_auth_repository.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/login_cubit/login_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/login_cubit/login_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late LoginCubit cubit;

  const user = UserProfile(
    id: '1',
    email: 'a@a.com',
    firstName: 'A',
    lastName: 'B',
    roles: ['User'],
  );

  setUp(() {
    repository = MockAuthRepository();
    cubit = LoginCubit(repository);
  });

  tearDown(() => cubit.close());

  test('emits [Loading, Success] on successful login', () async {
    when(() => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
          rememberMe: any(named: 'rememberMe'),
        ))
        .thenAnswer((_) async => const Right(user));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const LoginLoading(), const LoginSuccess(user)]),
    );

    unawaited(cubit.login(email: 'a@a.com', password: 'password123', rememberMe: true));
    await expectation;
  });

  test('forwards rememberMe unchanged to the repository', () async {
    when(() => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
          rememberMe: any(named: 'rememberMe'),
        )).thenAnswer((_) async => const Right(user));

    await cubit.login(email: 'a@a.com', password: 'password123', rememberMe: true);

    verify(() => repository.login(email: 'a@a.com', password: 'password123', rememberMe: true)).called(1);
  });

  test('emits an Error with errorCode Auth.EmailNotConfirmed unmodified', () async {
    when(() => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
          rememberMe: any(named: 'rememberMe'),
        ))
        .thenAnswer((_) async => const Left(
              ServerFailure(statusCode: 403, message: 'Email not confirmed', errorCode: 'Auth.EmailNotConfirmed'),
            ));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const LoginLoading(),
        isA<LoginError>().having((s) => s.errorCode, 'errorCode', 'Auth.EmailNotConfirmed'),
      ]),
    );

    unawaited(cubit.login(email: 'unverified@a.com', password: 'password123', rememberMe: true));
    await expectation;
  });

  test('emits an Error with errorCode Auth.InvalidCredentials', () async {
    when(() => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
          rememberMe: any(named: 'rememberMe'),
        ))
        .thenAnswer((_) async => const Left(UnauthorizedFailure(errorCode: 'Auth.InvalidCredentials')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const LoginLoading(),
        isA<LoginError>()
            .having((s) => s.errorCode, 'errorCode', 'Auth.InvalidCredentials')
            .having((s) => s.isNetworkError, 'isNetworkError', false),
      ]),
    );

    unawaited(cubit.login(email: 'a@a.com', password: 'wrong', rememberMe: true));
    await expectation;
  });

  test('emits an Error with the backend message for Auth.AccountLocked', () async {
    when(() => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
          rememberMe: any(named: 'rememberMe'),
        ))
        .thenAnswer((_) async => const Left(
              ServerFailure(statusCode: 423, message: 'Account locked', errorCode: 'Auth.AccountLocked'),
            ));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const LoginLoading(),
        isA<LoginError>()
            .having((s) => s.errorCode, 'errorCode', 'Auth.AccountLocked')
            .having((s) => s.message, 'message', 'Account locked'),
      ]),
    );

    unawaited(cubit.login(email: 'locked@a.com', password: 'password123', rememberMe: true));
    await expectation;
  });

  test('emits an Error with isNetworkError true on NetworkFailure', () async {
    when(() => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
          rememberMe: any(named: 'rememberMe'),
        ))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const LoginLoading(),
        isA<LoginError>().having((s) => s.isNetworkError, 'isNetworkError', true),
      ]),
    );

    unawaited(cubit.login(email: 'a@a.com', password: 'password123', rememberMe: true));
    await expectation;
  });
}
