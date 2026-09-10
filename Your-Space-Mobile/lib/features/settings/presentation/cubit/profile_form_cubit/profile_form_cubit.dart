import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/events/data_refresh_bus.dart';
import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/auth/domain/entities/user_profile.dart';
import 'package:your_space_mobile/features/auth/domain/repositories/base_auth_repository.dart';
import 'package:your_space_mobile/features/auth/domain/use_cases/get_current_user_profile_use_case.dart';

import 'profile_form_state.dart';

/// Single cubit for both load+submit — same shape as `PersonFormCubit`/
/// `ResetPasswordCubit` (a full-navigation form with no simultaneous list).
@injectable
class ProfileFormCubit extends Cubit<ProfileFormState> {
  final GetCurrentUserProfileUseCase _getCurrentUserProfile;
  final AuthRepository _authRepository;
  final DataRefreshBus _dataRefreshBus;

  ProfileFormCubit(this._getCurrentUserProfile, this._authRepository, this._dataRefreshBus)
      : super(const ProfileFormInitial());

  Future<void> initialize() async {
    emit(const ProfileFormLoading());
    final result = await _getCurrentUserProfile();
    result.fold(
      (failure) => emit(ProfileFormError(core.failureToMessage(failure))),
      (profile) => emit(ProfileFormReady(profile)),
    );
  }

  Future<void> submit({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    emit(const ProfileFormSubmitting());
    final result = await _authRepository.updateProfile(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
    );
    result.fold(
      (failure) => emit(ProfileFormError(core.failureToMessage(failure))),
      (profile) {
        _dataRefreshBus.notify(DataScope.profile);
        emit(ProfileFormSuccess(profile));
      },
    );
  }

  /// Every state variant that carries a profile — used to seed the avatar-mutation
  /// states without discarding what's already known while an upload/remove is in flight.
  UserProfile? get _currentProfile => switch (state) {
        ProfileFormReady(:final profile) => profile,
        ProfileFormSuccess(:final profile) => profile,
        ProfileFormAvatarUploading(:final profile) => profile,
        ProfileFormAvatarSuccess(:final profile) => profile,
        ProfileFormAvatarError(:final profile) => profile,
        _ => null,
      };

  Future<void> uploadAvatar(File file) async {
    final current = _currentProfile;
    if (current == null) return;

    emit(ProfileFormAvatarUploading(current));
    final result = await _authRepository.uploadAvatar(file);
    result.fold(
      (failure) => emit(ProfileFormAvatarError(current, core.failureToMessage(failure))),
      (profile) {
        _dataRefreshBus.notify(DataScope.profile);
        emit(ProfileFormAvatarSuccess(profile));
      },
    );
  }

  Future<void> removeAvatar() async {
    final current = _currentProfile;
    if (current == null) return;

    emit(ProfileFormAvatarUploading(current));
    final result = await _authRepository.removeAvatar();
    result.fold(
      (failure) => emit(ProfileFormAvatarError(current, core.failureToMessage(failure))),
      (profile) {
        _dataRefreshBus.notify(DataScope.profile);
        emit(ProfileFormAvatarSuccess(profile));
      },
    );
  }
}
