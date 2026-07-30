import 'package:equatable/equatable.dart';

/// Shared across the groups, people, and events features — lives in core so
/// the dependency direction stays Feature → Core, never Feature → Feature
/// (same rationale as `core/router/args/`).
///
/// [nameAr] is always null when hydrated from the backend: neither
/// `GroupProfileDto` nor `GroupDetailsDto` ever return it (only accepted on
/// create/update) — a known, accepted gap. Editing an existing group's
/// Arabic name always starts blank.
class Group extends Equatable {
  final int id;
  final String name;
  final String? nameAr;

  const Group({required this.id, required this.name, this.nameAr});

  @override
  List<Object?> get props => [id, name, nameAr];
}
