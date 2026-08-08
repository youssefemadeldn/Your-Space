// Id/GovernorateId come from the route (governorates/{governorateId}/cities/{id}), not the body.
class UpdateCityRequest {
  final String name;
  final String? nameAr;

  const UpdateCityRequest({required this.name, this.nameAr});

  Map<String, dynamic> toJson() => {
        'name': name,
        if (nameAr != null) 'nameAr': nameAr,
      };
}
