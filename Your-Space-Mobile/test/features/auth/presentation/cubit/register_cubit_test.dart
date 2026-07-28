import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/auth/domain/entities/user_profile.dart';
import 'package:your_space_mobile/features/auth/domain/repositories/base_auth_repository.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/register_cubit/register_cubit.dart';
import 'package:your_space_mobile/features/auth/presentation/cubit/register_cubit/register_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late RegisterCubit cubit;

  const user = UserProfile(
    id: '1',
    email: 'a@a.com',
    firstName: 'A',
    lastName: 'B',
    roles: ['User'],
  );

  setUp(() {
    repository = MockAuthRepository();
    cubit = RegisterCubit(repository);
  });

  tearDown(() => cubit.close());

  void stubRegister(Either<Failure, UserProfile> result) {
    when(() => repository.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
          confirmPassword: any(named: 'confirmPassword'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          phoneNumber: any(named: 'phoneNumber'),
        )).thenAnswer((_) async => result);
  }

  void submit() => unawaited(cubit.register(
        email: 'a@a.com',
        password: 'Passw0rd!',
        confirmPassword: 'Passw0rd!',
        firstName: 'A',
        lastName: 'B',
        phoneNumber: '+201234567890',
      ));

  test('emits [Loading, Success] on successful registration', () async {
    stubRegister(const Right(user));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const RegisterLoading(), const RegisterSuccess(user)]),
    );

    submit();
    await expectation;
  });

  test('emits an Error with the backend message for Auth.Register.EmailExists', () async {
    stubRegister(const Left(
      ServerFailure(statusCode: 409, message: 'Email already exists', errorCode: 'Auth.Register.EmailExists'),
    ));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const RegisterLoading(),
        isA<RegisterError>()
            .having((s) => s.errorCode, 'errorCode', 'Auth.Register.EmailExists')
            .having((s) => s.message, 'message', 'Email already exists'),
      ]),
    );

    submit();
    await expectation;
  });

  test('emits an Error with isNetworkError true on NetworkFailure', () async {
    stubRegister(const Left(NetworkFailure()));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const RegisterLoading(),
        isA<RegisterError>().having((s) => s.isNetworkError, 'isNetworkError', true),
      ]),
    );

    submit();
    await expectation;
  });
}
