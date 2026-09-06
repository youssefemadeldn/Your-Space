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
