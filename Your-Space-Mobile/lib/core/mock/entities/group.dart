import 'package:equatable/equatable.dart';

class Group extends Equatable {
  final int id;
  final String name;
  final String? nameAr;
  final DateTime createdAt;

  const Group({
    required this.id,
    required this.name,
    this.nameAr,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, nameAr, createdAt];
}
