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

// Independent avatar-mutation states — deliberately separate classes, not a reused/parameterized
// ProfileFormSubmitting, so the avatar spinner can never collide with the Save-button spinner (the
// Sprint 1 "isolate loading state" lesson). Each carries the current profile so the rest of the
// screen (name/phone fields, the profile picture itself) keeps rendering underneath.
final class ProfileFormAvatarUploading extends ProfileFormState {
  final UserProfile profile;
  const ProfileFormAvatarUploading(this.profile);
  @override
  List<Object?> get props => [profile];
}

final class ProfileFormAvatarSuccess extends ProfileFormState {
  final UserProfile profile;
  const ProfileFormAvatarSuccess(this.profile);
  @override
  List<Object?> get props => [profile];
}

final class ProfileFormAvatarError extends ProfileFormState {
  final UserProfile profile;
  final String message;
  const ProfileFormAvatarError(this.profile, this.message);
  @override
  List<Object?> get props => [profile, message];
}
