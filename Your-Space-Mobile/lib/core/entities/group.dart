import 'package:equatable/equatable.dart';

/// Shared across the groups, people, and events features — lives in core so
/// the dependency direction stays Feature → Core, never Feature → Feature
/// (same rationale as `core/router/args/`).
class Group extends Equatable {
  final int id;
  final String name;
  final String? nameAr;
  final DateTime? updatedAt;

  const Group({required this.id, required this.name, this.nameAr, this.updatedAt});

  @override
  List<Object?> get props => [id, name, nameAr, updatedAt];
}
