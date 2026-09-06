import 'package:your_space_mobile/core/entities/gender.dart';

class UpdatePersonRequest {
  final int id;
  final String name;
  final String? phoneNumber;
  final String? phoneNumber2;
  final Gender gender;
  final int groupId;
  final int? subGroupId;
  final int governorateId;
  final int? cityId;
  final int? neighborhoodId;
  final String? notes;

  const UpdatePersonRequest({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.phoneNumber2,
    required this.gender,
    required this.groupId,
    this.subGroupId,
    required this.governorateId,
    this.cityId,
    this.neighborhoodId,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (phoneNumber2 != null) 'phoneNumber2': phoneNumber2,
        'gender': gender.toWire(),
        'groupId': groupId,
        if (subGroupId != null) 'subGroupId': subGroupId,
        'governorateId': governorateId,
        if (cityId != null) 'cityId': cityId,
        if (neighborhoodId != null) 'neighborhoodId': neighborhoodId,
        if (notes != null) 'notes': notes,
      };
}
