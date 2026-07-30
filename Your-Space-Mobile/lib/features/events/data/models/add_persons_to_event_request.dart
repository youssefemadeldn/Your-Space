class AddPersonsToEventRequest {
  final List<int> personIds;

  const AddPersonsToEventRequest({required this.personIds});

  Map<String, dynamic> toJson() => {'personIds': personIds};
}
