import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/auth/domain/entities/user_profile.dart';
import 'package:your_space_mobile/features/auth/domain/repositories/base_auth_repository.dart';
import 'package:your_space_mobile/features/auth/domain/use_cases/get_current_user_profile_use_case.dart';
import 'package:your_space_mobile/features/settings/presentation/cubit/profile_form_cubit/profile_form_cubit.dart';
import 'package:your_space_mobile/features/settings/presentation/cubit/profile_form_cubit/profile_form_state.dart';

class MockGetCurrentUserProfileUseCase extends Mock implements GetCurrentUserProfileUseCase {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockGetCurrentUserProfileUseCase getCurrentUserProfile;
  late MockAuthRepository authRepository;
  late ProfileFormCubit cubit;

  const profile = UserProfile(
    id: 'user-1',
    email: 'jane@example.com',
    firstName: 'Jane',
    lastName: 'Doe',
    phoneNumber: '+201234567890',
    gender: Gender.female,
    roles: ['User'],
  );

  setUp(() {
    getCurrentUserProfile = MockGetCurrentUserProfileUseCase();
    authRepository = MockAuthRepository();
    cubit = ProfileFormCubit(getCurrentUserProfile, authRepository);
  });

  tearDown(() => cubit.close());

  test('initialize() emits [Loading, Ready] with the current profile on success', () async {
    when(() => getCurrentUserProfile()).thenAnswer((_) async => const Right(profile));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const ProfileFormLoading(),
        isA<ProfileFormReady>().having((s) => s.profile.firstName, 'profile.firstName', 'Jane'),
      ]),
    );

    unawaited(cubit.initialize());
    await expectation;
  });

  test('initialize() emits an Error when the profile fetch fails', () async {
    when(() => getCurrentUserProfile()).thenAnswer((_) async => const Left(NetworkFailure()));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const ProfileFormLoading(), isA<ProfileFormError>()]),
    );

    unawaited(cubit.initialize());
    await expectation;
  });

  test('submit() emits [Submitting, Success] with the updated profile', () async {
    when(() => authRepository.updateProfile(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          phoneNumber: any(named: 'phoneNumber'),
        )).thenAnswer((_) async => const Right(
          UserProfile(
            id: 'user-1',
            email: 'jane@example.com',
            firstName: 'Janet',
            lastName: 'Doe',
            phoneNumber: '+201234567890',
            gender: Gender.female,
            roles: ['User'],
          ),
        ));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        const ProfileFormSubmitting(),
        isA<ProfileFormSuccess>().having((s) => s.profile.firstName, 'profile.firstName', 'Janet'),
      ]),
    );

    unawaited(cubit.submit(firstName: 'Janet', lastName: 'Doe', phoneNumber: '+201234567890'));
    await expectation;
  });

  test('submit() emits an Error when the update fails', () async {
    when(() => authRepository.updateProfile(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          phoneNumber: any(named: 'phoneNumber'),
        )).thenAnswer((_) async => const Left(ValidationFailure(message: 'Invalid phone number')));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([const ProfileFormSubmitting(), isA<ProfileFormError>()]),
    );

    unawaited(cubit.submit(firstName: 'Janet', lastName: 'Doe', phoneNumber: 'bad'));
    await expectation;
  });
}
