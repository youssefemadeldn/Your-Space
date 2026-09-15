import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:your_space_mobile/core/entities/invite_method.dart';
import 'package:your_space_mobile/core/entities/paginated_result.dart';
import 'package:your_space_mobile/core/entities/person.dart';
import 'package:your_space_mobile/core/network/failure.dart';
import 'package:your_space_mobile/features/people/domain/repositories/base_person_repository.dart';
import '../../domain/entities/bulk_add_guests_result.dart';
import '../../domain/entities/event_guest.dart';
import '../../domain/entities/event_guest_progress_summary.dart';
import '../../domain/entities/event_guest_status.dart';
import '../../domain/repositories/base_event_guest_repository.dart';
import '../datasources/base_event_guest_data_source.dart';
import '../datasources/event_guest_local_data_source_impl.dart';

/// Very large — effectively "no page limit" — for the local Person lookups
/// that back bulk-add expansion (§ below). The owned dataset is small by
/// design (design doc §1), so a single unbounded local query is cheap and
/// avoids inventing a real "all persons matching this filter" primitive
/// beyond what `PersonRepository.watchPersons` already exposes.
const _unboundedLocalLimit = 1000000;

@LazySingleton(as: EventGuestRepository)
class EventGuestRepositoryImpl implements EventGuestRepository {
  final BaseEventGuestDataSource _remote;
  final EventGuestLocalDataSourceImpl _local;
  final PersonRepository _personRepository;

  EventGuestRepositoryImpl(
    @Named('remote') this._remote,
    @Named('local') this._local,
    this._personRepository,
  );

  @override
  Future<Either<Failure, PaginatedResult<EventGuest>>> getEventGuests(
    int eventId, {
    int? groupId,
    EventGuestStatus? status,
    required int pageIndex,
    required int pageSize,
  }) async {
    final result = await _remote.getEventGuests(
      eventId,
      groupId: groupId,
      status: status,
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
    return result.fold(Left.new, (response) => Right(response.toResult((r) => r.toEntity(eventId))));
  }

  @override
  Stream<List<EventGuest>> watchEventGuests({
    required int eventId,
    int? groupId,
    EventGuestStatus? status,
    required int limit,
  }) =>
      _local.watchEventGuests(eventId: eventId, groupId: groupId, status: status, limit: limit);

  @override
  Future<int> countEventGuests({required int eventId, int? groupId, EventGuestStatus? status}) =>
      _local.countEventGuests(eventId: eventId, groupId: groupId, status: status);

  @override
  Future<Either<Failure, Unit>> refreshEventGuests() async {
    final result = await _remote.getAllMineEventGuests();
    return result.fold(
      Left.new,
      (responses) async {
        await _local.applyEventGuestsSnapshot(responses.map((r) => r.toEntity()).toList());
        return const Right(unit);
      },
    );
  }

  @override
  Future<Either<Failure, EventGuestProgressSummary>> getProgress(int eventId) async {
    final result = await _remote.getProgress(eventId);
    return result.fold(Left.new, (response) => Right(response.toEntity()));
  }

  @override
  Future<Either<Failure, PaginatedResult<Person>>> getReciprocitySuggestions(
    int eventId, {
    int? groupId,
    required int pageIndex,
    required int pageSize,
  }) async {
    final result = await _remote.getReciprocitySuggestions(
      eventId,
      groupId: groupId,
      pageIndex: pageIndex,
      pageSize: pageSize,
    );
    return result.fold(Left.new, (response) => Right(response.toResult((r) => r.toEntity())));
  }

  int _newTempGuestId() => -DateTime.now().microsecondsSinceEpoch;

  /// Client-side bulk-add expansion (row 9 cross-cutting decision): resolves
  /// [persons] against the already-known guest set for [eventId] and queues
  /// one `'create'` outbox row per new guest — no bulk-shaped outbox
  /// operation exists, consistent with the rest of the rollout's
  /// one-row-per-mutation model.
  Future<BulkAddGuestsResult> _addPersons(int eventId, List<Person> persons) async {
    final existing = await _local.watchEventGuests(eventId: eventId, limit: _unboundedLocalLimit).first;
    final existingPersonIds = existing.map((g) => g.personId).toSet();
    final newPersons = persons.where((p) => !existingPersonIds.contains(p.id)).toList();

    for (final person in newPersons) {
      final guest = EventGuest(
        id: _newTempGuestId(),
        eventId: eventId,
        personId: person.id,
        personName: person.name,
        personPhoneNumber: person.phoneNumber,
        groupId: person.groupId,
        groupName: person.groupName,
      );
      final payloadJson = jsonEncode({'eventId': eventId, 'personId': person.id});
      await _local.queueEventGuestMutation(guest: guest, operation: 'create', payloadJson: payloadJson);
    }

    return BulkAddGuestsResult(
      requestedCount: persons.length,
      addedCount: newPersons.length,
      alreadyPresentCount: persons.length - newPersons.length,
    );
  }

  @override
  Future<Either<Failure, BulkAddGuestsResult>> addPersonsToEvent({
    required int eventId,
    required List<int> personIds,
  }) async {
    final allPersons = await _personRepository.watchPersons(limit: _unboundedLocalLimit).first;
    final requested = allPersons.where((p) => personIds.contains(p.id)).toList();
    return Right(await _addPersons(eventId, requested));
  }

  @override
  Future<Either<Failure, BulkAddGuestsResult>> addGroupToEvent({
    required int eventId,
    required int groupId,
  }) async {
    final persons = await _personRepository.watchPersons(groupId: groupId, limit: _unboundedLocalLimit).first;
    return Right(await _addPersons(eventId, persons));
  }

  @override
  Future<Either<Failure, BulkAddGuestsResult>> addSubGroupToEvent({
    required int eventId,
    required int subGroupId,
  }) async {
    final persons =
        await _personRepository.watchPersons(subGroupId: subGroupId, limit: _unboundedLocalLimit).first;
    return Right(await _addPersons(eventId, persons));
  }

  @override
  Future<Either<Failure, BulkAddGuestsResult>> addGovernorateToEvent({
    required int eventId,
    required int governorateId,
  }) async {
    final persons = await _personRepository
        .watchPersons(governorateId: governorateId, limit: _unboundedLocalLimit)
        .first;
    return Right(await _addPersons(eventId, persons));
  }

  @override
  Future<Either<Failure, BulkAddGuestsResult>> addCityToEvent({
    required int eventId,
    required int cityId,
  }) async {
    final persons = await _personRepository.watchPersons(cityId: cityId, limit: _unboundedLocalLimit).first;
    return Right(await _addPersons(eventId, persons));
  }

  @override
  Future<Either<Failure, BulkAddGuestsResult>> addNeighborhoodToEvent({
    required int eventId,
    required int neighborhoodId,
  }) async {
    final persons = await _personRepository
        .watchPersons(neighborhoodId: neighborhoodId, limit: _unboundedLocalLimit)
        .first;
    return Right(await _addPersons(eventId, persons));
  }

  /// Status transitions (invite/skip/revert) are `'update'` outbox rows —
  /// same shape as any other partial-field update elsewhere in the rollout.
  Future<EventGuest> _queueStatusUpdate(
    int eventId,
    int guestId, {
    required EventGuestStatus status,
    InviteMethod? inviteMethod,
    DateTime? invitedAt,
  }) async {
    final existing = await _local.watchEventGuests(eventId: eventId, limit: _unboundedLocalLimit).first;
    final current = existing.firstWhere((g) => g.id == guestId);
    final updated = EventGuest(
      id: current.id,
      eventId: current.eventId,
      personId: current.personId,
      personName: current.personName,
      personPhoneNumber: current.personPhoneNumber,
      groupId: current.groupId,
      groupName: current.groupName,
      status: status,
      inviteMethod: inviteMethod,
      invitedAt: invitedAt,
    );
    final payloadJson = jsonEncode({
      'eventId': eventId,
      'guestId': guestId,
      'status': status.toWire(),
      if (inviteMethod != null) 'inviteMethod': inviteMethod.toWire(),
    });
    await _local.queueEventGuestMutation(guest: updated, operation: 'update', payloadJson: payloadJson);
    return updated;
  }

  @override
  Future<Either<Failure, EventGuest>> markInvited(
    int eventId,
    int guestId, {
    required InviteMethod inviteMethod,
  }) async =>
      Right(await _queueStatusUpdate(
        eventId,
        guestId,
        status: EventGuestStatus.invited,
        inviteMethod: inviteMethod,
        invitedAt: DateTime.now(),
      ));

  @override
  Future<Either<Failure, EventGuest>> markSkipped(int eventId, int guestId) async =>
      Right(await _queueStatusUpdate(eventId, guestId, status: EventGuestStatus.skipped));

  @override
  Future<Either<Failure, EventGuest>> revertGuest(int eventId, int guestId) async =>
      Right(await _queueStatusUpdate(eventId, guestId, status: EventGuestStatus.notInvited));

  @override
  Future<Either<Failure, Unit>> removeGuest(int eventId, int guestId) async {
    await _local.queueDeletedEventGuest(guestId, payloadJson: jsonEncode({'eventId': eventId}));
    return const Right(unit);
  }
}
