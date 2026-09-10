/// Person-to-person kinship relation type — 14 fixed values, mirrors the
/// backend's `RelationType` enum exactly. See [Gender] for the same
/// PascalCase-wire-value bridging pattern.
enum RelationType {
  husband,
  wife,
  father,
  mother,
  uncleMaternal,
  auntMaternal,
  unclePaternal,
  auntPaternal,
  son,
  daughter,
  brother,
  sister,
  nephew,
  niece;

  static RelationType fromWire(String value) => switch (value) {
        'Husband' => RelationType.husband,
        'Wife' => RelationType.wife,
        'Father' => RelationType.father,
        'Mother' => RelationType.mother,
        'UncleMaternal' => RelationType.uncleMaternal,
        'AuntMaternal' => RelationType.auntMaternal,
        'UnclePaternal' => RelationType.unclePaternal,
        'AuntPaternal' => RelationType.auntPaternal,
        'Son' => RelationType.son,
        'Daughter' => RelationType.daughter,
        'Brother' => RelationType.brother,
        'Sister' => RelationType.sister,
        'Nephew' => RelationType.nephew,
        'Niece' => RelationType.niece,
        _ => throw FormatException('Unknown RelationType wire value: $value'),
      };

  String toWire() => switch (this) {
        RelationType.husband => 'Husband',
        RelationType.wife => 'Wife',
        RelationType.father => 'Father',
        RelationType.mother => 'Mother',
        RelationType.uncleMaternal => 'UncleMaternal',
        RelationType.auntMaternal => 'AuntMaternal',
        RelationType.unclePaternal => 'UnclePaternal',
        RelationType.auntPaternal => 'AuntPaternal',
        RelationType.son => 'Son',
        RelationType.daughter => 'Daughter',
        RelationType.brother => 'Brother',
        RelationType.sister => 'Sister',
        RelationType.nephew => 'Nephew',
        RelationType.niece => 'Niece',
      };

  /// Translation key for localized display — e.g. `'people.relationType.uncleMaternal'`.
  String get labelKey => 'people.relationType.$name';
}
