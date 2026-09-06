import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/auth/domain/entities/user_profile.dart';
import 'package:your_space_mobile/features/auth/domain/repositories/base_auth_repository.dart';
import 'package:your_space_mobile/features/auth/domain/use_cases/get_current_user_profile_use_case.dart';
import 'package:your_space_mobile/features/settings/presentation/cubit/profile_form_cubit/profile_form_cubit.dart';
import 'package:your_space_mobile/features/settings/presentation/cubit/profile_form_cubit/profile_form_state.dart';

class MockGetCurrentUserProfileUseCase extends Mock implements GetCurrentUserProfileUseCase {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockDataRefreshBus extends Mock implements DataRefreshBus {}

void main() {
  late MockGetCurrentUserProfileUseCase getCurrentUserProfile;
  late MockAuthRepository authRepository;
  late MockDataRefreshBus dataRefreshBus;
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

  setUpAll(() {
    registerFallbackValue(File('fallback.jpg'));
  });

  setUp(() {
    getCurrentUserProfile = MockGetCurrentUserProfileUseCase();
    authRepository = MockAuthRepository();
    dataRefreshBus = MockDataRefreshBus();
    cubit = ProfileFormCubit(getCurrentUserProfile, authRepository, dataRefreshBus);
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
    verify(() => dataRefreshBus.notify(DataScope.profile)).called(1);
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

  group('uploadAvatar', () {
    test('does nothing when no profile has been loaded yet', () async {
      await cubit.uploadAvatar(File('photo.jpg'));

      verifyNever(() => authRepository.uploadAvatar(any()));
    });

    test('emits [AvatarUploading, AvatarSuccess] with the updated profile', () async {
      when(() => getCurrentUserProfile()).thenAnswer((_) async => const Right(profile));
      await cubit.initialize();

      when(() => authRepository.uploadAvatar(any())).thenAnswer(
        (_) async => const Right(UserProfile(
          id: 'user-1',
          email: 'jane@example.com',
          firstName: 'Jane',
          lastName: 'Doe',
          gender: Gender.female,
          avatarUrl: 'https://example.com/avatar.jpg',
          roles: ['User'],
        )),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<ProfileFormAvatarUploading>(),
          isA<ProfileFormAvatarSuccess>()
              .having((s) => s.profile.avatarUrl, 'profile.avatarUrl', 'https://example.com/avatar.jpg'),
        ]),
      );

      unawaited(cubit.uploadAvatar(File('photo.jpg')));
      await expectation;
      verify(() => dataRefreshBus.notify(DataScope.profile)).called(1);
    });

    test('emits an AvatarError, keeping the previously-known profile, on failure', () async {
      when(() => getCurrentUserProfile()).thenAnswer((_) async => const Right(profile));
      await cubit.initialize();
      when(() => authRepository.uploadAvatar(any()))
          .thenAnswer((_) async => const Left(ValidationFailure(message: 'File too large')));

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<ProfileFormAvatarUploading>(),
          isA<ProfileFormAvatarError>().having((s) => s.profile.firstName, 'profile.firstName', 'Jane'),
        ]),
      );

      unawaited(cubit.uploadAvatar(File('photo.jpg')));
      await expectation;
    });
  });

  group('removeAvatar', () {
    test('emits [AvatarUploading, AvatarSuccess] with avatarUrl cleared', () async {
      when(() => getCurrentUserProfile()).thenAnswer((_) async => const Right(profile));
      await cubit.initialize();
      when(() => authRepository.removeAvatar()).thenAnswer(
        (_) async => const Right(UserProfile(
          id: 'user-1',
          email: 'jane@example.com',
          firstName: 'Jane',
          lastName: 'Doe',
          gender: Gender.female,
          roles: ['User'],
        )),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<ProfileFormAvatarUploading>(),
          isA<ProfileFormAvatarSuccess>().having((s) => s.profile.avatarUrl, 'profile.avatarUrl', isNull),
        ]),
      );

      unawaited(cubit.removeAvatar());
      await expectation;
      verify(() => dataRefreshBus.notify(DataScope.profile)).called(1);
    });
  });
}
