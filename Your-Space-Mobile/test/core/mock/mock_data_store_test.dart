import 'package:flutter_test/flutter_test.dart';
import 'package:your_space_mobile/core/mock/entities/event_guest_status.dart';
import 'package:your_space_mobile/core/mock/entities/invite_method.dart';
import 'package:your_space_mobile/core/mock/mock_data_store.dart';

void main() {
  late MockDataStore store;

  setUp(() {
    store = MockDataStore()..simulatedLatency = Duration.zero;
  });

  group('Groups', () {
    test('groups() filters by search, case-insensitively', () {
      final results = store.groups(search: 'fam');
      expect(results, hasLength(1));
      expect(results.first.name, 'Family');
    });

    test('createGroup adds a new group with an id after the existing max', () {
      final maxIdBefore = store.groups().map((g) => g.id).reduce((a, b) => a > b ? a : b);
      final created = store.createGroup(name: 'Book club');
      expect(created.id, greaterThan(maxIdBefore));
      expect(store.groups().map((g) => g.name), contains('Book club'));
    });

    test('updateGroup renames the group and syncs denormalized groupName on its people', () {
      final family = store.groups().firstWhere((g) => g.name == 'Family');
      store.updateGroup(id: family.id, name: 'The Family');

      final updated = store.groups().firstWhere((g) => g.id == family.id);
      expect(updated.name, 'The Family');

      final peopleInGroup = store.people(groupId: family.id);
      expect(peopleInGroup, isNotEmpty);
      expect(peopleInGroup.every((p) => p.groupName == 'The Family'), isTrue);
    });
  });

  group('People', () {
    test('people() filters by groupId', () {
      final family = store.groups().firstWhere((g) => g.name == 'Family');
      final results = store.people(groupId: family.id);
      expect(results, isNotEmpty);
      expect(results.every((p) => p.groupId == family.id), isTrue);
    });

    test('createPerson denormalizes groupName from the given groupId', () {
      final family = store.groups().firstWhere((g) => g.name == 'Family');
      final created = store.createPerson(name: 'New Person', groupId: family.id);
      expect(created.groupName, 'Family');
    });

    test('updatePerson moving groups updates groupName and existing event-guest rows', () {
      final closeFriends = store.groups().firstWhere((g) => g.name == 'Close friends');
      final person = store.people().firstWhere((p) => p.name == 'Omar Khaled');

      store.updatePerson(id: person.id, groupId: closeFriends.id);

      final updatedPerson = store.people().firstWhere((p) => p.id == person.id);
      expect(updatedPerson.groupName, 'Close friends');

      final events = store.events();
      final guestRow = store.eventGuests(events.first.id).where((g) => g.personId == person.id);
      if (guestRow.isNotEmpty) {
        expect(guestRow.first.groupName, 'Close friends');
        expect(guestRow.first.groupId, closeFriends.id);
      }
    });
  });

  group('Occasion history', () {
    test('addOccasionHistory with invitedMe=true flips hasReciprocityHistory', () {
      final person = store.people().firstWhere((p) => !p.hasReciprocityHistory);
      expect(person.hasReciprocityHistory, isFalse);

      store.addOccasionHistory(personId: person.id, invitedMe: true, occasionName: 'Dinner');

      final updated = store.people().firstWhere((p) => p.id == person.id);
      expect(updated.hasReciprocityHistory, isTrue);
    });

    test('addOccasionHistory with invitedMe=false does not touch hasReciprocityHistory', () {
      final person = store.people().firstWhere((p) => !p.hasReciprocityHistory);

      store.addOccasionHistory(personId: person.id, invitedMe: false);

      final updated = store.people().firstWhere((p) => p.id == person.id);
      expect(updated.hasReciprocityHistory, isFalse);
    });

    test('occasionHistory returns entries newest-first', () async {
      final person = store.people().first;
      store.addOccasionHistory(personId: person.id, invitedMe: false, occasionName: 'First');
      // A real gap between calls — two DateTime.now() calls made back-to-back
      // synchronously can land in the same clock tick, which would make the
      // sort comparator see them as equal rather than actually testing order.
      await Future.delayed(const Duration(milliseconds: 2));
      store.addOccasionHistory(personId: person.id, invitedMe: false, occasionName: 'Second');

      final history = store.occasionHistory(person.id);
      expect(history.first.occasionName, 'Second');
    });
  });

  group('Events', () {
    test('events() computes totalGuestCount from eventGuests, not a stored field', () {
      final event = store.events().firstWhere((e) => e.name == "Sara's Birthday");
      expect(event.totalGuestCount, store.eventGuests(event.id).length);
    });

    test('a brand-new event has zero guests', () {
      final created = store.createEvent(name: 'New Year Gathering 2');
      expect(created.totalGuestCount, 0);
    });
  });

  group('Event guests & progress', () {
    test('eventProgress totals match the sum of per-group breakdowns', () {
      final event = store.events().firstWhere((e) => e.name == "Sara's Birthday");
      final progress = store.eventProgress(event.id);

      final sumInvited = progress.groups.fold<int>(0, (sum, g) => sum + g.invitedCount);
      final sumSkipped = progress.groups.fold<int>(0, (sum, g) => sum + g.skippedCount);
      final sumNotInvited = progress.groups.fold<int>(0, (sum, g) => sum + g.notInvitedCount);

      expect(progress.invitedCount, sumInvited);
      expect(progress.skippedCount, sumSkipped);
      expect(progress.notInvitedCount, sumNotInvited);
    });

    test('eventProgress includes every group, even ones with zero guests added', () {
      final newEvent = store.createEvent(name: 'Empty Event');
      final progress = store.eventProgress(newEvent.id);
      expect(progress.groups, hasLength(store.groups().length));
      expect(progress.groups.every((g) => g.guestsAddedCount == 0), isTrue);
    });

    test('markInvited sets status to invited with the given method and a timestamp', () {
      final event = store.events().firstWhere((e) => e.name == "Sara's Birthday");
      final guest = store.eventGuests(event.id).firstWhere((g) => g.status == EventGuestStatus.notInvited);

      final updated = store.markInvited(guest.id, inviteMethod: InviteMethod.whatsApp);

      expect(updated.status, EventGuestStatus.invited);
      expect(updated.inviteMethod, InviteMethod.whatsApp);
      expect(updated.invitedAt, isNotNull);
    });

    test('revertGuest clears inviteMethod and invitedAt back to notInvited', () {
      final event = store.events().firstWhere((e) => e.name == "Sara's Birthday");
      final guest = store.eventGuests(event.id).firstWhere((g) => g.status == EventGuestStatus.invited);

      final reverted = store.revertGuest(guest.id);

      expect(reverted.status, EventGuestStatus.notInvited);
      expect(reverted.inviteMethod, isNull);
      expect(reverted.invitedAt, isNull);
    });

    test('every guest status transition is unconditional, no guard', () {
      final event = store.events().firstWhere((e) => e.name == "Sara's Birthday");
      final guest = store.eventGuests(event.id).first;

      // Skip an already-skipped/invited/whatever guest twice in a row — must not throw.
      store.markSkipped(guest.id);
      final result = store.markSkipped(guest.id);
      expect(result.status, EventGuestStatus.skipped);
    });

    test('removeGuest deletes the row entirely', () {
      final event = store.events().firstWhere((e) => e.name == "Sara's Birthday");
      final countBefore = store.eventGuests(event.id).length;
      final guest = store.eventGuests(event.id).first;

      store.removeGuest(guest.id);

      expect(store.eventGuests(event.id), hasLength(countBefore - 1));
      expect(store.eventGuests(event.id).any((g) => g.id == guest.id), isFalse);
    });
  });

  group('Bulk add guests', () {
    test('addPersonsToEvent reports already-present persons without duplicating them', () {
      final event = store.events().firstWhere((e) => e.name == "Sara's Birthday");
      final existingGuest = store.eventGuests(event.id).first;
      final newPerson = store.people().firstWhere(
            (p) => !store.eventGuests(event.id).map((g) => g.personId).contains(p.id),
          );

      final result = store.addPersonsToEvent(
        eventId: event.id,
        personIds: [existingGuest.personId, newPerson.id],
      );

      expect(result.requestedCount, 2);
      expect(result.addedCount, 1);
      expect(result.alreadyPresentCount, 1);
    });

    test('addGroupToEvent adds every person in that group', () {
      final newEvent = store.createEvent(name: 'Group Add Test');
      final group = store.groups().first;
      final peopleInGroup = store.people(groupId: group.id);

      final result = store.addGroupToEvent(eventId: newEvent.id, groupId: group.id);

      expect(result.addedCount, peopleInGroup.length);
      expect(store.eventGuests(newEvent.id), hasLength(peopleInGroup.length));
    });
  });

  group('Reciprocity suggestions', () {
    test('only returns people with reciprocity history who are not already guests', () {
      final event = store.events().firstWhere((e) => e.name == "Sara's Birthday");
      final suggestions = store.reciprocitySuggestions(event.id);

      final existingGuestIds = store.eventGuests(event.id).map((g) => g.personId).toSet();
      expect(suggestions.every((p) => p.hasReciprocityHistory), isTrue);
      expect(suggestions.any((p) => existingGuestIds.contains(p.id)), isFalse);
    });
  });
}
