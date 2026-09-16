import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/gender.dart';
import 'package:your_space_mobile/core/entities/invite_method.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/core/sync/sync_service.dart';
import '../../domain/entities/person_details.dart';
import '../../domain/entities/person_occasion_history_entry.dart';
import '../../domain/repositories/base_person_repository.dart';
import '../datasources/base_person_data_source.dart';
import '../datasources/person_local_data_source_impl.dart';
import '../datasources/person_relationship_local_data_source_impl.dart';
import '../models/add_occasion_history_request.dart';
import '../models/create_person_request.dart';
import '../models/update_person_request.dart';

@LazySingleton(as: PersonRepository)
class PersonRepositoryImpl implements PersonRepository {
  final BasePersonDataSource _remote;
  final PersonLocalDataSourceImpl _local;
  final PersonRelationshipLocalDataSourceImpl _relationshipsLocal;
  final SyncService _syncService;

  PersonRepositoryImpl(
    @Named('remote') this._remote,
    @Named('local') this._local,
    @Named('local') this._relationshipsLocal,
    this._syncService,
  );

  @override
  Future<Either<Failure, PaginatedResult<Person>>> getPersons({
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
    required int pageIndex,
    required int pageSize,
  }) async {
    final result = await _remote.getPersons(
      groupId: groupId,
      subGroupId: subGroupId,
      governorateId: governorateId,
      cityId: cityId,
      neighborhoodId: neighborhoodId,
      search: search,
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
    return result.fold(Left.new, (response) => Right(response.toResult((r) => r.toEntity())));
  }

  @override
  Stream<List<Person>> watchPersons({
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
    required int limit,
  }) =>
      _local.watchPersons(
        groupId: groupId,
        subGroupId: subGroupId,
        governorateId: governorateId,
        cityId: cityId,
        neighborhoodId: neighborhoodId,
        search: search,
        limit: limit,
      );

  @override
  Future<int> countPersons({
    int? groupId,
    int? subGroupId,
    int? governorateId,
    int? cityId,
    int? neighborhoodId,
    String? search,
  }) =>
      _local.countPersons(
        groupId: groupId,
        subGroupId: subGroupId,
        governorateId: governorateId,
        cityId: cityId,
        neighborhoodId: neighborhoodId,
        search: search,
      );

  @override
  Future<Either<Failure, Unit>> refreshPersons() async {
    const pageSize = 200;
    // Defensive cap against a pathological `hasMore` loop — a healthy
    // cursor sequence terminates on its own; this is insurance, not an
    // expected limit (design doc §1: "hundreds of rows" per owner).
    const maxPages = 50;
    var cursor = await _local.getPersonsSyncCursor();
    for (var page = 0; page < maxPages; page++) {
      final result = await _remote.getPersonChanges(since: cursor, pageSize: pageSize);
      if (result.isLeft()) {
        return result.fold(Left.new, (_) => throw StateError('unreachable'));
      }
      final changes = result.getOrElse(() => throw StateError('unreachable'));
      await _local.applyPersonChanges(
        upserts: changes.upserts.map((r) => r.toEntity()).toList(),
        tombstoneIds: changes.tombstoneIds,
      );
      await _local.savePersonsSyncCursor(changes.cursor);
      cursor = changes.cursor;
      if (!changes.hasMore) break;
    }
    return const Right(unit);
  }

  /// Cache-then-network (design doc §7): this is a one-shot `Future`, not a
  /// reactive `Stream`, so unlike `watchPersons()` it can't fall back to the
  /// local cache silently in the background — it has to try the network
  /// first and only reach for drift on a genuine connectivity failure. A
  /// `NetworkFailure` with a cached row falls back to it (relationships are
  /// fully cached too; occasion history and `createdAt` aren't — see
  /// `PersonDetails`'s own doc comment). Any other failure (auth, server
  /// error) or a cache miss still surfaces as before.
  @override
  Future<Either<Failure, PersonDetails>> getPersonById(int id) async {
    final result = await _remote.getPersonById(id);
    return result.fold(
      (failure) async {
        if (failure is! NetworkFailure) return Left(failure);
        final cachedPerson = await _local.getCachedPersonById(id);
        if (cachedPerson == null) return Left(failure);
        final relationships = await _relationshipsLocal.getCachedRelationships(id);
        return Right(PersonDetails(
          person: cachedPerson,
          occasionHistory: const [],
          relationships: relationships,
          createdAt: null,
        ));
      },
      (response) async {
        final details = response.toEntity();
        await _local.savePerson(details.person);
        return Right(details);
      },
    );
  }

  int _newTempPersonId() => -DateTime.now().microsecondsSinceEpoch;

  /// Builds the [Person] draft + JSON-encoded [CreatePersonRequest] payload
  /// and queues both via the outbox. Shared by [createPerson] and
  /// [createPersonAndSync] — only what happens after queuing differs.
  Future<(Person, int)> _queueCreate({
    required String name,
    String? phoneNumber,
    String? phoneNumber2,
    required Gender gender,
    required int groupId,
    required String groupName,
    int? subGroupId,
    String? subGroupName,
    required int governorateId,
    required String governorateName,
    int? cityId,
    String? cityName,
    int? neighborhoodId,
    String? neighborhoodName,
    String? notes,
    String? facebookUrl,
  }) async {
    final person = Person(
      id: _newTempPersonId(),
      name: name,
      phoneNumber: phoneNumber,
      phoneNumber2: phoneNumber2,
      gender: gender,
      groupId: groupId,
      groupName: groupName,
      subGroupId: subGroupId,
      subGroupName: subGroupName,
      governorateId: governorateId,
      governorateName: governorateName,
      cityId: cityId,
      cityName: cityName,
      neighborhoodId: neighborhoodId,
      neighborhoodName: neighborhoodName,
      notes: notes,
      facebookUrl: facebookUrl,
    );
    final payloadJson = jsonEncode(CreatePersonRequest(
      name: name,
      phoneNumber: phoneNumber,
      phoneNumber2: phoneNumber2,
      gender: gender,
      groupId: groupId,
      subGroupId: subGroupId,
      governorateId: governorateId,
      cityId: cityId,
      neighborhoodId: neighborhoodId,
      notes: notes,
      facebookUrl: facebookUrl,
    ).toJson());
    final rowId = await _local.queuePersonMutation(person: person, operation: 'create', payloadJson: payloadJson);
    return (person, rowId);
  }

  /// Shared by [updatePerson] and [updatePersonAndSync] — same split as
  /// [_queueCreate].
  Future<(Person, int)> _queueUpdate({
    required int id,
    required String name,
    String? phoneNumber,
    String? phoneNumber2,
    required Gender gender,
    required int groupId,
    required String groupName,
    int? subGroupId,
    String? subGroupName,
    required int governorateId,
    required String governorateName,
    int? cityId,
    String? cityName,
    int? neighborhoodId,
    String? neighborhoodName,
    String? notes,
    String? facebookUrl,
  }) async {
    final person = Person(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      phoneNumber2: phoneNumber2,
      gender: gender,
      groupId: groupId,
      groupName: groupName,
      subGroupId: subGroupId,
      subGroupName: subGroupName,
      governorateId: governorateId,
      governorateName: governorateName,
      cityId: cityId,
      cityName: cityName,
      neighborhoodId: neighborhoodId,
      neighborhoodName: neighborhoodName,
      notes: notes,
      facebookUrl: facebookUrl,
    );
    final payloadJson = jsonEncode(UpdatePersonRequest(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      phoneNumber2: phoneNumber2,
      gender: gender,
      groupId: groupId,
      subGroupId: subGroupId,
      governorateId: governorateId,
      cityId: cityId,
      neighborhoodId: neighborhoodId,
      notes: notes,
      facebookUrl: facebookUrl,
    ).toJson());
    final rowId = await _local.queuePersonMutation(person: person, operation: 'update', payloadJson: payloadJson);
    return (person, rowId);
  }

  @override
  Future<Either<Failure, Person>> createPerson({
    required String name,
    String? phoneNumber,
    String? phoneNumber2,
    required Gender gender,
    required int groupId,
    required String groupName,
    int? subGroupId,
    String? subGroupName,
    required int governorateId,
    required String governorateName,
    int? cityId,
    String? cityName,
    int? neighborhoodId,
    String? neighborhoodName,
    String? notes,
    String? facebookUrl,
  }) async {
    final (person, _) = await _queueCreate(
      name: name,
      phoneNumber: phoneNumber,
      phoneNumber2: phoneNumber2,
      gender: gender,
      groupId: groupId,
      groupName: groupName,
      subGroupId: subGroupId,
      subGroupName: subGroupName,
      governorateId: governorateId,
      governorateName: governorateName,
      cityId: cityId,
      cityName: cityName,
      neighborhoodId: neighborhoodId,
      neighborhoodName: neighborhoodName,
      notes: notes,
      facebookUrl: facebookUrl,
    );
    return Right(person);
  }

  @override
  Future<Either<Failure, Person>> updatePerson({
    required int id,
    required String name,
    String? phoneNumber,
    String? phoneNumber2,
    required Gender gender,
    required int groupId,
    required String groupName,
    int? subGroupId,
    String? subGroupName,
    required int governorateId,
    required String governorateName,
    int? cityId,
    String? cityName,
    int? neighborhoodId,
    String? neighborhoodName,
    String? notes,
    String? facebookUrl,
  }) async {
    final (person, _) = await _queueUpdate(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      phoneNumber2: phoneNumber2,
      gender: gender,
      groupId: groupId,
      groupName: groupName,
      subGroupId: subGroupId,
      subGroupName: subGroupName,
      governorateId: governorateId,
      governorateName: governorateName,
      cityId: cityId,
      cityName: cityName,
      neighborhoodId: neighborhoodId,
      neighborhoodName: neighborhoodName,
      notes: notes,
      facebookUrl: facebookUrl,
    );
    return Right(person);
  }

  @override
  Future<Either<Failure, Person>> createPersonAndSync({
    required String name,
    String? phoneNumber,
    String? phoneNumber2,
    required Gender gender,
    required int groupId,
    required String groupName,
    int? subGroupId,
    String? subGroupName,
    required int governorateId,
    required String governorateName,
    int? cityId,
    String? cityName,
    int? neighborhoodId,
    String? neighborhoodName,
    String? notes,
    String? facebookUrl,
  }) async {
    final (person, rowId) = await _queueCreate(
      name: name,
      phoneNumber: phoneNumber,
      phoneNumber2: phoneNumber2,
      gender: gender,
      groupId: groupId,
      groupName: groupName,
      subGroupId: subGroupId,
      subGroupName: subGroupName,
      governorateId: governorateId,
      governorateName: governorateName,
      cityId: cityId,
      cityName: cityName,
      neighborhoodId: neighborhoodId,
      neighborhoodName: neighborhoodName,
      notes: notes,
      facebookUrl: facebookUrl,
    );
    final result = await _syncService.replayRow(rowId);
    return result.fold(Left.new, (payload) => Right(payload as Person? ?? person));
  }

  @override
  Future<Either<Failure, Person>> updatePersonAndSync({
    required int id,
    required String name,
    String? phoneNumber,
    String? phoneNumber2,
    required Gender gender,
    required int groupId,
    required String groupName,
    int? subGroupId,
    String? subGroupName,
    required int governorateId,
    required String governorateName,
    int? cityId,
    String? cityName,
    int? neighborhoodId,
    String? neighborhoodName,
    String? notes,
    String? facebookUrl,
  }) async {
    final (person, rowId) = await _queueUpdate(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      phoneNumber2: phoneNumber2,
      gender: gender,
      groupId: groupId,
      groupName: groupName,
      subGroupId: subGroupId,
      subGroupName: subGroupName,
      governorateId: governorateId,
      governorateName: governorateName,
      cityId: cityId,
      cityName: cityName,
      neighborhoodId: neighborhoodId,
      neighborhoodName: neighborhoodName,
      notes: notes,
      facebookUrl: facebookUrl,
    );
    final result = await _syncService.replayRow(rowId);
    // Unlike createPersonAndSync, `id` here is always an already-real,
    // pre-existing person — so a NetworkFailure (device offline right now)
    // isn't a reason to reject the edit: the row is already safely queued
    // in the outbox and will sync on the next trigger, same Tier 2 success
    // a plain updatePerson call would report. Any other failure (validation,
    // server error) still propagates.
    return result.fold(
      (failure) => failure is NetworkFailure ? Right(person) : Left(failure),
      (payload) => Right(payload as Person? ?? person),
    );
  }

  @override
  Future<Either<Failure, PersonOccasionHistoryEntry>> addOccasionHistory({
    required int personId,
    required bool invitedMe,
    InviteMethod? inviteMethod,
    String? occasionName,
    DateTime? occasionDate,
    String? notes,
  }) async {
    final result = await _remote.addOccasionHistory(
      personId,
      AddOccasionHistoryRequest(
        invitedMe: invitedMe,
        inviteMethod: inviteMethod,
        occasionName: occasionName,
        occasionDate: occasionDate,
        notes: notes,
      ),
    );
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }
}
