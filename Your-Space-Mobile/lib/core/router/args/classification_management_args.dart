import 'package:your_space_mobile/core/entities/classification_entity_kind.dart';

class ClassificationManagementArgs {
  final ClassificationEntityKind kind;
  final int parentId;
  final String parentName;

  const ClassificationManagementArgs({
    required this.kind,
    required this.parentId,
    required this.parentName,
  });
}
