import 'package:drift/drift.dart';

/// Local mirror of the synced [EventGuest] entity
/// (`lib/features/events/domain/entities/event_guest.dart`).
///
/// `id` is the server id; a negative value marks a not-yet-synced record
/// created offline (Tier 2 temp-id, see `doc/local-first-sync-design.md` §5).
/// EventGuest is permanently hard-delete-only (no soft-delete column ever
/// planned — row 9, cross-cutting decision) so Tier 3 for this table runs
/// design doc §6's "full-refetch-as-delta" mode forever, not as an interim
/// stand-in — there is deliberately no `updatedAt` watermark column here,
/// unlike every cursor-synced table.
class EventGuestsTable extends Table {
  IntColumn get id => integer()();
  IntColumn get eventId => integer()();
  IntColumn get personId => integer()();
  TextColumn get personName => text()();
  TextColumn get personPhoneNumber => text().nullable()();
  IntColumn get groupId => integer()();
  TextColumn get groupName => text()();
  TextColumn get status => text()(); // EventGuestStatus wire value, e.g. "NotInvited"
  TextColumn get inviteMethod => text().nullable()(); // InviteMethod wire value, e.g. "WhatsApp"
  DateTimeColumn get invitedAt => dateTime().nullable()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // tombstone, Tier 3
  BoolColumn get isDirty =>
      boolean().withDefault(const Constant(false))(); // pending outbox row, Tier 2

  @override
  Set<Column> get primaryKey => {id};
}
