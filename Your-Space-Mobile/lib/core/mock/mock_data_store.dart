import 'package:injectable/injectable.dart';

import 'entities/bulk_add_guests_result.dart';
import 'entities/event.dart';
import 'entities/event_guest.dart';
import 'entities/event_guest_progress_summary.dart';
import 'entities/event_guest_status.dart';
import 'entities/group.dart';
import 'entities/group_guest_progress.dart';
import 'entities/invite_method.dart';
import 'entities/person.dart';
import 'entities/person_occasion_history_entry.dart';
import 'mock_seed_data.dart';

/// Temporary, in-memory replacement for the Groups/People/Events repositories
/// that don't exist yet. Every read/write here is synchronous — Cubits are the
/// ones that add a [simulatedLatency] delay around a call, so "fake async" stays
/// a presentation-layer concern instead of leaking into this store.
///
/// Shared across the home/groups/people/events features (Feature -> Core, never
/// Feature -> Feature) for the same reason `CartCubit` is a documented
/// `@lazySingleton` exception in CLAUDE.md's DI table: several screens across
/// different features need to read the same live data (e.g. the People form's
/// group picker, Home's stat counts, Events' add-guests screen). Delete this
/// whole file once each feature gets a real repository backed by the API.
@lazySingleton
class MockDataStore {
  MockDataStore()
      : _groups = List.of(mockSeedGroups),
        _people = List.of(mockSeedPeople),
        _occasionHistory = List.of(mockSeedOccasionHistory),
        _events = List.of(mockSeedEvents),
        _eventGuests = List.of(mockSeedEventGuests),
        _nextGroupId = _nextId(mockSeedGroups.map((g) => g.id)),
        _nextPersonId = _nextId(mockSeedPeople.map((p) => p.id)),
        _nextOccasionId = _nextId(mockSeedOccasionHistory.map((o) => o.id)),
        _nextEventId = _nextId(mockSeedEvents.map((e) => e.id)),
        _nextEventGuestId = _nextId(mockSeedEventGuests.map((g) => g.id));

  /// Mutable, not constructor-injected — a constructor parameter with a
  /// default value here would still make `injectable`'s generator try to
  /// resolve `Duration` from GetIt (unregistered, crashes at runtime). Tests
  /// that want no artificial delay just assign `store.simulatedLatency = Duration.zero`.
  Duration simulatedLatency = const Duration(milliseconds: 500);

  final List<Group> _groups;
  final List<Person> _people;
  final List<PersonOccasionHistoryEntry> _occasionHistory;
  final List<Event> _events;
  final List<EventGuest> _eventGuests;

  int _nextGroupId;
  int _nextPersonId;
  int _nextOccasionId;
  int _nextEventId;
  int _nextEventGuestId;

  static int _nextId(Iterable<int> ids) =>
      (ids.isEmpty ? 0 : ids.reduce((a, b) => a > b ? a : b)) + 1;

  // ---- Groups ----

  List<Group> groups({String? search}) {
    final query = search?.trim().toLowerCase();
    final list = query == null || query.isEmpty
        ? _groups
        : _groups.where((g) => g.name.toLowerCase().contains(query)).toList();
    return List.unmodifiable(list);
  }

  Group createGroup({required String name, String? nameAr}) {
    final group = Group(id: _nextGroupId++, name: name, nameAr: nameAr, createdAt: DateTime.now());
    _groups.add(group);
    return group;
  }

  Group updateGroup({required int id, String? name, String? nameAr}) {
    final index = _groups.indexWhere((g) => g.id == id);
    final current = _groups[index];
    final updated = Group(
      id: current.id,
      name: name ?? current.name,
      nameAr: nameAr ?? current.nameAr,
      createdAt: current.createdAt,
    );
    _groups[index] = updated;

    // Keep the denormalized groupName in sync everywhere it's cached, mirroring
    // what a real backend's joined read models would already reflect.
    if (name != null && name != current.name) {
      for (var i = 0; i < _people.length; i++) {
        if (_people[i].groupId == id) _people[i] = _withGroupName(_people[i], updated.name);
      }
      for (var i = 0; i < _eventGuests.length; i++) {
        if (_eventGuests[i].groupId == id) {
          _eventGuests[i] = _withEventGuestGroupName(_eventGuests[i], updated.name);
        }
      }
    }
    return updated;
  }

  Person _withGroupName(Person person, String groupName) => Person(
        id: person.id,
        name: person.name,
        phoneNumber: person.phoneNumber,
        groupId: person.groupId,
        groupName: groupName,
        hasReciprocityHistory: person.hasReciprocityHistory,
        createdAt: person.createdAt,
      );

  EventGuest _withEventGuestGroupName(EventGuest guest, String groupName) => EventGuest(
        id: guest.id,
        eventId: guest.eventId,
        personId: guest.personId,
        personName: guest.personName,
        personPhoneNumber: guest.personPhoneNumber,
        groupId: guest.groupId,
        groupName: groupName,
        status: guest.status,
        inviteMethod: guest.inviteMethod,
        invitedAt: guest.invitedAt,
      );

  // ---- People ----

  List<Person> people({int? groupId, String? search}) {
    var list = _people.toList();
    if (groupId != null) list = list.where((p) => p.groupId == groupId).toList();
    final query = search?.trim().toLowerCase();
    if (query != null && query.isNotEmpty) {
      list = list.where((p) => p.name.toLowerCase().contains(query)).toList();
    }
    return List.unmodifiable(list);
  }

  Person? personById(int id) {
    for (final person in _people) {
      if (person.id == id) return person;
    }
    return null;
  }

  Person createPerson({required String name, String? phoneNumber, required int groupId}) {
    final group = _groups.firstWhere((g) => g.id == groupId);
    final person = Person(
      id: _nextPersonId++,
      name: name,
      phoneNumber: phoneNumber,
      groupId: groupId,
      groupName: group.name,
      createdAt: DateTime.now(),
    );
    _people.add(person);
    return person;
  }

  Person updatePerson({required int id, String? name, String? phoneNumber, int? groupId}) {
    final index = _people.indexWhere((p) => p.id == id);
    final current = _people[index];
    final groupName = groupId == null ? current.groupName : _groups.firstWhere((g) => g.id == groupId).name;
    final updated = Person(
      id: current.id,
      name: name ?? current.name,
      phoneNumber: phoneNumber ?? current.phoneNumber,
      groupId: groupId ?? current.groupId,
      groupName: groupName,
      hasReciprocityHistory: current.hasReciprocityHistory,
      createdAt: current.createdAt,
    );
    _people[index] = updated;

    if (groupId != null && groupId != current.groupId) {
      for (var i = 0; i < _eventGuests.length; i++) {
        if (_eventGuests[i].personId == id) {
          _eventGuests[i] = _withEventGuestGroup(_eventGuests[i], groupId, groupName);
        }
      }
    }
    return updated;
  }

  EventGuest _withEventGuestGroup(EventGuest guest, int groupId, String groupName) => EventGuest(
        id: guest.id,
        eventId: guest.eventId,
        personId: guest.personId,
        personName: guest.personName,
        personPhoneNumber: guest.personPhoneNumber,
        groupId: groupId,
        groupName: groupName,
        status: guest.status,
        inviteMethod: guest.inviteMethod,
        invitedAt: guest.invitedAt,
      );

  // ---- Occasion history ----

  List<PersonOccasionHistoryEntry> occasionHistory(int personId) {
    final list = _occasionHistory.where((o) => o.personId == personId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  PersonOccasionHistoryEntry addOccasionHistory({
    required int personId,
    required bool invitedMe,
    InviteMethod? inviteMethod,
    String? occasionName,
    DateTime? occasionDate,
    String? notes,
  }) {
    final entry = PersonOccasionHistoryEntry(
      id: _nextOccasionId++,
      personId: personId,
      invitedMe: invitedMe,
      inviteMethod: invitedMe ? inviteMethod : null,
      occasionName: occasionName,
      occasionDate: occasionDate,
      notes: notes,
      createdAt: DateTime.now(),
    );
    _occasionHistory.add(entry);

    if (invitedMe) {
      final index = _people.indexWhere((p) => p.id == personId);
      if (index != -1 && !_people[index].hasReciprocityHistory) {
        final person = _people[index];
        _people[index] = Person(
          id: person.id,
          name: person.name,
          phoneNumber: person.phoneNumber,
          groupId: person.groupId,
          groupName: person.groupName,
          hasReciprocityHistory: true,
          createdAt: person.createdAt,
        );
      }
    }
    return entry;
  }

  // ---- Events ----

  List<Event> events({String? search}) {
    final query = search?.trim().toLowerCase();
    final source =
        query == null || query.isEmpty ? _events : _events.where((e) => e.name.toLowerCase().contains(query));
    return List.unmodifiable(source.map(_withGuestCount).toList());
  }

  Event? eventById(int id) {
    for (final event in _events) {
      if (event.id == id) return _withGuestCount(event);
    }
    return null;
  }

  Event _withGuestCount(Event event) => Event(
        id: event.id,
        name: event.name,
        nameAr: event.nameAr,
        eventDate: event.eventDate,
        notes: event.notes,
        totalGuestCount: _eventGuests.where((g) => g.eventId == event.id).length,
        createdAt: event.createdAt,
      );

  Event createEvent({required String name, String? nameAr, DateTime? eventDate, String? notes}) {
    final event = Event(
      id: _nextEventId++,
      name: name,
      nameAr: nameAr,
      eventDate: eventDate,
      notes: notes,
      createdAt: DateTime.now(),
    );
    _events.add(event);
    return event;
  }

  Event updateEvent({required int id, String? name, String? nameAr, DateTime? eventDate, String? notes}) {
    final index = _events.indexWhere((e) => e.id == id);
    final current = _events[index];
    final updated = Event(
      id: current.id,
      name: name ?? current.name,
      nameAr: nameAr ?? current.nameAr,
      eventDate: eventDate ?? current.eventDate,
      notes: notes ?? current.notes,
      totalGuestCount: current.totalGuestCount,
      createdAt: current.createdAt,
    );
    _events[index] = updated;
    return _withGuestCount(updated);
  }

  // ---- Event guests ----

  List<EventGuest> eventGuests(int eventId, {int? groupId, EventGuestStatus? status}) {
    var list = _eventGuests.where((g) => g.eventId == eventId).toList();
    if (groupId != null) list = list.where((g) => g.groupId == groupId).toList();
    if (status != null) list = list.where((g) => g.status == status).toList();
    return List.unmodifiable(list);
  }

  EventGuestProgressSummary eventProgress(int eventId) {
    final guestsForEvent = _eventGuests.where((g) => g.eventId == eventId).toList();

    int countOf(Iterable<EventGuest> guests, EventGuestStatus status) =>
        guests.where((g) => g.status == status).length;

    final groupProgress = _groups.map((group) {
      final peopleInGroup = _people.where((p) => p.groupId == group.id).length;
      final guestsInGroup = guestsForEvent.where((g) => g.groupId == group.id).toList();
      return GroupGuestProgress(
        groupId: group.id,
        groupName: group.name,
        totalPersonsInGroup: peopleInGroup,
        guestsAddedCount: guestsInGroup.length,
        notInvitedCount: countOf(guestsInGroup, EventGuestStatus.notInvited),
        invitedCount: countOf(guestsInGroup, EventGuestStatus.invited),
        skippedCount: countOf(guestsInGroup, EventGuestStatus.skipped),
      );
    }).toList();

    return EventGuestProgressSummary(
      eventId: eventId,
      totalGuestCount: guestsForEvent.length,
      notInvitedCount: countOf(guestsForEvent, EventGuestStatus.notInvited),
      invitedCount: countOf(guestsForEvent, EventGuestStatus.invited),
      skippedCount: countOf(guestsForEvent, EventGuestStatus.skipped),
      groups: groupProgress,
    );
  }

  BulkAddGuestsResult addPersonsToEvent({required int eventId, required List<int> personIds}) {
    var added = 0;
    var alreadyPresent = 0;
    for (final personId in personIds) {
      final exists = _eventGuests.any((g) => g.eventId == eventId && g.personId == personId);
      if (exists) {
        alreadyPresent++;
        continue;
      }
      final person = personById(personId);
      if (person == null) continue;
      _eventGuests.add(EventGuest(
        id: _nextEventGuestId++,
        eventId: eventId,
        personId: person.id,
        personName: person.name,
        personPhoneNumber: person.phoneNumber,
        groupId: person.groupId,
        groupName: person.groupName,
      ));
      added++;
    }
    return BulkAddGuestsResult(
      requestedCount: personIds.length,
      addedCount: added,
      alreadyPresentCount: alreadyPresent,
    );
  }

  BulkAddGuestsResult addGroupToEvent({required int eventId, required int groupId}) {
    final personIds = _people.where((p) => p.groupId == groupId).map((p) => p.id).toList();
    return addPersonsToEvent(eventId: eventId, personIds: personIds);
  }

  EventGuest markInvited(int guestId, {required InviteMethod inviteMethod}) =>
      _updateGuestStatus(guestId, EventGuestStatus.invited, inviteMethod: inviteMethod);

  EventGuest markSkipped(int guestId) => _updateGuestStatus(guestId, EventGuestStatus.skipped);

  EventGuest revertGuest(int guestId) => _updateGuestStatus(guestId, EventGuestStatus.notInvited);

  void removeGuest(int guestId) => _eventGuests.removeWhere((g) => g.id == guestId);

  EventGuest _updateGuestStatus(int guestId, EventGuestStatus status, {InviteMethod? inviteMethod}) {
    final index = _eventGuests.indexWhere((g) => g.id == guestId);
    final current = _eventGuests[index];
    final updated = EventGuest(
      id: current.id,
      eventId: current.eventId,
      personId: current.personId,
      personName: current.personName,
      personPhoneNumber: current.personPhoneNumber,
      groupId: current.groupId,
      groupName: current.groupName,
      status: status,
      inviteMethod: status == EventGuestStatus.invited ? inviteMethod : null,
      invitedAt: status == EventGuestStatus.invited ? DateTime.now() : null,
    );
    _eventGuests[index] = updated;
    return updated;
  }

  List<Person> reciprocitySuggestions(int eventId, {int? groupId}) {
    final existingPersonIds = _eventGuests.where((g) => g.eventId == eventId).map((g) => g.personId).toSet();
    var candidates =
        _people.where((p) => p.hasReciprocityHistory && !existingPersonIds.contains(p.id)).toList();
    if (groupId != null) candidates = candidates.where((p) => p.groupId == groupId).toList();
    return List.unmodifiable(candidates);
  }
}
