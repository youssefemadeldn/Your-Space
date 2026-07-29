import 'entities/event.dart';
import 'entities/event_guest.dart';
import 'entities/event_guest_status.dart';
import 'entities/group.dart';
import 'entities/invite_method.dart';
import 'entities/person.dart';
import 'entities/person_occasion_history_entry.dart';

final _now = DateTime.now();

final List<Group> mockSeedGroups = [
  Group(id: 1, name: 'Family', nameAr: 'العائلة', createdAt: _now.subtract(const Duration(days: 300))),
  Group(
    id: 2,
    name: 'Close friends',
    nameAr: 'أصدقاء مقربون',
    createdAt: _now.subtract(const Duration(days: 250)),
  ),
  Group(
    id: 3,
    name: 'Work friends',
    nameAr: 'أصدقاء العمل',
    createdAt: _now.subtract(const Duration(days: 180)),
  ),
  Group(id: 4, name: 'Neighbors', nameAr: 'الجيران', createdAt: _now.subtract(const Duration(days: 90))),
];

final List<Person> mockSeedPeople = [
  Person(
    id: 1,
    name: 'Sara Adel',
    phoneNumber: '+201001234567',
    groupId: 1,
    groupName: 'Family',
    hasReciprocityHistory: true,
    createdAt: _now.subtract(const Duration(days: 280)),
  ),
  Person(
    id: 2,
    name: 'Omar Khaled',
    groupId: 1,
    groupName: 'Family',
    createdAt: _now.subtract(const Duration(days: 275)),
  ),
  Person(
    id: 3,
    name: 'Mona Tarek',
    phoneNumber: '+201009876543',
    groupId: 2,
    groupName: 'Close friends',
    hasReciprocityHistory: true,
    createdAt: _now.subtract(const Duration(days: 240)),
  ),
  Person(
    id: 4,
    name: 'Youssef Hassan',
    phoneNumber: '+201112223344',
    groupId: 2,
    groupName: 'Close friends',
    createdAt: _now.subtract(const Duration(days: 230)),
  ),
  Person(
    id: 5,
    name: 'Laila Fathy',
    groupId: 3,
    groupName: 'Work friends',
    createdAt: _now.subtract(const Duration(days: 170)),
  ),
  Person(
    id: 6,
    name: 'Ahmed Samir',
    phoneNumber: '+201223344556',
    groupId: 3,
    groupName: 'Work friends',
    createdAt: _now.subtract(const Duration(days: 160)),
  ),
  Person(
    id: 7,
    name: 'Nour Ibrahim',
    phoneNumber: '+201334455667',
    groupId: 4,
    groupName: 'Neighbors',
    hasReciprocityHistory: true,
    createdAt: _now.subtract(const Duration(days: 85)),
  ),
  Person(
    id: 8,
    name: 'Karim Adly',
    groupId: 4,
    groupName: 'Neighbors',
    createdAt: _now.subtract(const Duration(days: 80)),
  ),
  Person(
    id: 9,
    name: 'Dina Mostafa',
    phoneNumber: '+201445566778',
    groupId: 1,
    groupName: 'Family',
    createdAt: _now.subtract(const Duration(days: 260)),
  ),
  Person(
    id: 10,
    name: 'Tarek Younes',
    phoneNumber: '+201556677889',
    groupId: 2,
    groupName: 'Close friends',
    createdAt: _now.subtract(const Duration(days: 220)),
  ),
];

final List<PersonOccasionHistoryEntry> mockSeedOccasionHistory = [
  PersonOccasionHistoryEntry(
    id: 1,
    personId: 1,
    invitedMe: true,
    inviteMethod: InviteMethod.whatsApp,
    occasionName: "Sara's engagement",
    occasionDate: _now.subtract(const Duration(days: 120)),
    createdAt: _now.subtract(const Duration(days: 120)),
  ),
  PersonOccasionHistoryEntry(
    id: 2,
    personId: 3,
    invitedMe: true,
    inviteMethod: InviteMethod.physical,
    occasionName: 'Eid gathering',
    occasionDate: _now.subtract(const Duration(days: 60)),
    createdAt: _now.subtract(const Duration(days: 60)),
  ),
  PersonOccasionHistoryEntry(
    id: 3,
    personId: 7,
    invitedMe: true,
    inviteMethod: InviteMethod.phoneCall,
    occasionName: 'Housewarming',
    occasionDate: _now.subtract(const Duration(days: 30)),
    createdAt: _now.subtract(const Duration(days: 30)),
  ),
];

final List<Event> mockSeedEvents = [
  Event(
    id: 1,
    name: "Sara's Birthday",
    nameAr: 'عيد ميلاد سارة',
    eventDate: _now.add(const Duration(days: 14)),
    notes: 'Backyard party, bring a dish to share',
    createdAt: _now.subtract(const Duration(days: 10)),
  ),
  Event(
    id: 2,
    name: 'New Year Gathering',
    createdAt: _now.subtract(const Duration(days: 1)),
  ),
];

final List<EventGuest> mockSeedEventGuests = [
  EventGuest(
    id: 1,
    eventId: 1,
    personId: 2,
    personName: 'Omar Khaled',
    groupId: 1,
    groupName: 'Family',
    status: EventGuestStatus.invited,
    inviteMethod: InviteMethod.whatsApp,
    invitedAt: _now.subtract(const Duration(days: 3)),
  ),
  EventGuest(
    id: 2,
    eventId: 1,
    personId: 3,
    personName: 'Mona Tarek',
    personPhoneNumber: '+201009876543',
    groupId: 2,
    groupName: 'Close friends',
    status: EventGuestStatus.invited,
    inviteMethod: InviteMethod.physical,
    invitedAt: _now.subtract(const Duration(days: 2)),
  ),
  EventGuest(
    id: 3,
    eventId: 1,
    personId: 4,
    personName: 'Youssef Hassan',
    personPhoneNumber: '+201112223344',
    groupId: 2,
    groupName: 'Close friends',
  ),
  EventGuest(
    id: 4,
    eventId: 1,
    personId: 5,
    personName: 'Laila Fathy',
    groupId: 3,
    groupName: 'Work friends',
    status: EventGuestStatus.skipped,
  ),
  EventGuest(
    id: 5,
    eventId: 1,
    personId: 9,
    personName: 'Dina Mostafa',
    personPhoneNumber: '+201445566778',
    groupId: 1,
    groupName: 'Family',
  ),
  EventGuest(
    id: 6,
    eventId: 1,
    personId: 10,
    personName: 'Tarek Younes',
    personPhoneNumber: '+201556677889',
    groupId: 2,
    groupName: 'Close friends',
    status: EventGuestStatus.invited,
    inviteMethod: InviteMethod.whatsApp,
    invitedAt: _now.subtract(const Duration(days: 1)),
  ),
];
