import 'package:equatable/equatable.dart';

/// Shared presentation-level row shape all 3 management screens map their
/// entity (SubGroup/City/Neighborhood) into before handing off to
/// [ClassificationListBody] — this is where the mockup's "one implementation"
/// intent actually lives, at the UI layer, while each entity keeps its own
/// concrete cubit pair (see B3's cubit-design decision).
class ClassificationItem extends Equatable {
  final int id;
  final String name;
  final String? caption;

  const ClassificationItem({required this.id, required this.name, this.caption});

  @override
  List<Object?> get props => [id, name, caption];
}
