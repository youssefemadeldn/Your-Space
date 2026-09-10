import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/network/failure.dart';
import '../entities/user_profile.dart';
import '../repositories/base_auth_repository.dart';

/// Wraps `AuthRepository.getProfile()` — extracted as a use case (rather than a
/// direct repo call) because it's called from two cubits: `HomeStatsCubit`
/// (personalized greeting) and `ProfileFormCubit` (Settings edit-profile prefill).
@injectable
class GetCurrentUserProfileUseCase {
  final AuthRepository _authRepository;

  GetCurrentUserProfileUseCase(this._authRepository);

  Future<Either<Failure, UserProfile>> call() => _authRepository.getProfile();
}
