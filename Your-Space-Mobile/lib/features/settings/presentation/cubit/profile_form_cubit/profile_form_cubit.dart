import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure_messages.dart' as core;
import 'package:your_space_mobile/features/auth/domain/repositories/base_auth_repository.dart';
import 'package:your_space_mobile/features/auth/domain/use_cases/get_current_user_profile_use_case.dart';

import 'profile_form_state.dart';

/// Single cubit for both load+submit — same shape as `PersonFormCubit`/
/// `ResetPasswordCubit` (a full-navigation form with no simultaneous list).
@injectable
class ProfileFormCubit extends Cubit<ProfileFormState> {
  final GetCurrentUserProfileUseCase _getCurrentUserProfile;
  final AuthRepository _authRepository;

  ProfileFormCubit(this._getCurrentUserProfile, this._authRepository)
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
      (profile) => emit(ProfileFormSuccess(profile)),
    );
  }
}
