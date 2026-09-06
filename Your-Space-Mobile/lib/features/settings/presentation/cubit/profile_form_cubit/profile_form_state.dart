import 'package:equatable/equatable.dart';

import 'package:your_space_mobile/features/auth/domain/entities/user_profile.dart';

sealed class ProfileFormState extends Equatable {
  const ProfileFormState();
  @override
  List<Object?> get props => const [];
}

final class ProfileFormInitial extends ProfileFormState {
  const ProfileFormInitial();
}

final class ProfileFormLoading extends ProfileFormState {
  const ProfileFormLoading();
}

final class ProfileFormReady extends ProfileFormState {
  final UserProfile profile;
  const ProfileFormReady(this.profile);
  @override
  List<Object?> get props => [profile];
}

final class ProfileFormSubmitting extends ProfileFormState {
  const ProfileFormSubmitting();
}

final class ProfileFormSuccess extends ProfileFormState {
  final UserProfile profile;
  const ProfileFormSuccess(this.profile);
  @override
  List<Object?> get props => [profile];
}

final class ProfileFormError extends ProfileFormState {
  final String message;
  const ProfileFormError(this.message);
  @override
  List<Object?> get props => [message];
}
