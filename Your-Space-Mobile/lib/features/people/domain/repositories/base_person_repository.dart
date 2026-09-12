import 'package:dartz/dartz.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/invite_method.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/network/failure.dart';

import '../entities/person_details.dart';
import '../entities/person_occasion_history_entry.dart';

abstract class PersonRepository {
  Future<Either<Failure, PaginatedResult<Person>>> getPersons({
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
    required int pageIndex,
    required int pageSize,
  });

  Future<Either<Failure, PersonDetails>> getPersonById(int id);

  /// Tier 1 read path for `PeopleListCubit` (local-first, CLAUDE.md rule 7) —
  /// reads local drift only, never touches the network. `limit` grows as
  /// `loadMore()` is called; the caller resubscribes rather than tracking an
  /// offset (see `doc/local-first-sync-design.md` §3).
  Stream<List<Person>> watchPersons({
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
    required int limit,
  });

  /// One-shot exact count for the same filter set, local-only — backs
  /// `hasNextPage` without a `length == limit` heuristic.
  Future<int> countPersons({
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
  });

  /// Background bulk sync, no filters: the entire owned dataset is meant to
  /// live on-device (design doc §1), so this loops the paginated remote
  /// endpoint until exhausted and upserts everything into drift. The result
  /// only signals whether the fetch itself succeeded — on failure the UI
  /// keeps showing cached data (design doc §3).
  Future<Either<Failure, Unit>> refreshPersons();

  Future<Either<Failure, Person>> createPerson({
    required String name,
    String? phoneNumber,
    String? phoneNumber2,
    required Gender gender,
    required int groupId,
    int? subGroupId,
    required int governorateId,
    int? cityId,
    int? neighborhoodId,
    String? notes,
  });

  Future<Either<Failure, Person>> updatePerson({
    required int id,
    required String name,
    String? phoneNumber,
    String? phoneNumber2,
    required Gender gender,
    required int groupId,
    int? subGroupId,
    required int governorateId,
    int? cityId,
    int? neighborhoodId,
    String? notes,
  });

  Future<Either<Failure, PersonOccasionHistoryEntry>> addOccasionHistory({
    required int personId,
    required bool invitedMe,
    InviteMethod? inviteMethod,
    String? occasionName,
    DateTime? occasionDate,
    String? notes,
  });
}
