// Id/CityId come from the route (cities/{cityId}/neighborhoods/{id}), not the body.
class UpdateNeighborhoodRequest {
  final String name;
  final String? nameAr;

  const UpdateNeighborhoodRequest({required this.name, this.nameAr});

  Map<String, dynamic> toJson() => {
        'name': name,
        if (nameAr != null) 'nameAr': nameAr,
      };
}
